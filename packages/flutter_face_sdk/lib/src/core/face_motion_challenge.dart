import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum FaceMotionStep {
  initial,
  closer,
  complete,
}

enum FaceMotionDirection {
  initial,
  closer,
  complete,
  // Aliases for compatibility
  center,
  left,
  right,
  up,
  down,
}

class FacePoseMetrics {
  const FacePoseMetrics({
    required this.yaw,
    required this.pitch,
    required this.roll,
    this.faceWidthRatio = 0.0,
    this.faceCenterX = 0.0,
    this.faceCenterY = 0.0,
  });

  final double yaw;
  final double pitch;
  final double roll;
  final double faceWidthRatio;
  final double faceCenterX;
  final double faceCenterY;

  bool get isValid => yaw.isFinite && pitch.isFinite && roll.isFinite;

  FacePoseMetrics copyWith({
    double? yaw,
    double? pitch,
    double? roll,
    double? faceWidthRatio,
    double? faceCenterX,
    double? faceCenterY,
  }) {
    return FacePoseMetrics(
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      faceWidthRatio: faceWidthRatio ?? this.faceWidthRatio,
      faceCenterX: faceCenterX ?? this.faceCenterX,
      faceCenterY: faceCenterY ?? this.faceCenterY,
    );
  }
}

FacePoseMetrics? estimateFacePose({
  required double leftEyeX,
  required double leftEyeY,
  required double rightEyeX,
  required double rightEyeY,
  required double noseX,
  required double noseY,
  required double mouthLeftX,
  required double mouthLeftY,
  required double mouthRightX,
  required double mouthRightY,
  required double roll,
  double faceWidthRatio = 0.0,
  double faceCenterX = 0.0,
  double faceCenterY = 0.0,
}) {
  final eyeCenterX = (leftEyeX + rightEyeX) / 2;
  final eyeCenterY = (leftEyeY + rightEyeY) / 2;
  final mouthCenterY = (mouthLeftY + mouthRightY) / 2;
  final eyeDistance = math.sqrt(
    math.pow(leftEyeX - rightEyeX, 2) + math.pow(leftEyeY - rightEyeY, 2),
  );
  final eyeToMouthDistance = (mouthCenterY - eyeCenterY).abs();
  if (eyeDistance < 1 || eyeToMouthDistance < 1) return null;

  final metrics = FacePoseMetrics(
    yaw: (noseX - eyeCenterX) / eyeDistance,
    pitch: (noseY - eyeCenterY) / eyeToMouthDistance,
    roll: roll,
    faceWidthRatio: faceWidthRatio,
    faceCenterX: faceCenterX,
    faceCenterY: faceCenterY,
  );
  return metrics.isValid ? metrics : null;
}

class FaceMotionChallenge extends ChangeNotifier {
  FaceMotionChallenge({
    this.requiredStableFrames = 1,
    this.requiredCenterStableFrames = 2,
    this.initialFaceWidthRatioMin = 0.18,
    this.initialFaceWidthRatioMax = 0.48,
    this.targetCloseFaceWidthRatio = 0.52,
    this.maximumCenterYaw = 0.12,
    this.maximumCenterPitchDelta = 0.14,
    this.maximumCenterRollDegrees = 14,
    this.maximumRollDegrees = 25,
    this.minimumYawDelta = 0.055,
    double? minimumLeftYawDelta,
  })  : minimumLeftYawDelta = minimumLeftYawDelta ?? 0.038,
        assert(requiredStableFrames > 0),
        assert(requiredCenterStableFrames >= requiredStableFrames);

  final int requiredStableFrames;
  final int requiredCenterStableFrames;
  final double initialFaceWidthRatioMin;
  final double initialFaceWidthRatioMax;
  final double targetCloseFaceWidthRatio;
  final double maximumCenterYaw;
  final double maximumCenterPitchDelta;
  final double maximumCenterRollDegrees;
  final double maximumRollDegrees;
  final double minimumYawDelta;
  final double minimumLeftYawDelta;

  FaceMotionStep _step = FaceMotionStep.initial;
  int _stableFrames = 0;
  double? _baselineRatio;
  double _currentStepProgress = 0;
  int _lastProgressBucket = -1;
  bool _notificationScheduled = false;
  bool _isDisposed = false;
  String? _feedback;
  bool get hasFeedback => _feedback != null;
  String get displayInstruction => _feedback ?? instruction;

  void setFeedback(String? message) {
    if (_feedback == message) return;
    _feedback = message;
    _scheduleNotification();
  }

  void interruptObservation(String message) {
    _clearStability();
    _updateCurrentProgress(0);
    setFeedback(message);
  }

  FaceMotionStep get step => _step;
  bool get isComplete => _step == FaceMotionStep.complete;
  bool get isInitialStep => _step == FaceMotionStep.initial;
  bool get isCloserStep => _step == FaceMotionStep.closer;
  bool get isFinalCenterStep => _step == FaceMotionStep.closer;
  int get completedStepCount => _step.index;
  int get totalStepCount => FaceMotionStep.complete.index;
  int get requiredFramesForCurrentStep =>
      isFinalCenterStep ? requiredCenterStableFrames : requiredStableFrames;
  double get currentStepProgress => _currentStepProgress;
  double get progress => isComplete
      ? 1.0
      : (completedStepCount + _currentStepProgress) / totalStepCount;

  double get targetFrameScale => isInitialStep ? 0.78 : 1.0;

  FaceMotionDirection get direction {
    switch (_step) {
      case FaceMotionStep.initial:
        return FaceMotionDirection.initial;
      case FaceMotionStep.closer:
        return FaceMotionDirection.closer;
      case FaceMotionStep.complete:
        return FaceMotionDirection.complete;
    }
  }

  String get instruction {
    switch (_step) {
      case FaceMotionStep.initial:
        return 'Đặt khuôn mặt vào trong khung hình';
      case FaceMotionStep.closer:
        return 'Đưa điện thoại lại gần hơn';
      case FaceMotionStep.complete:
        return 'Đang so khớp với ảnh trên chip CCCD...';
    }
  }

  bool observe(FacePoseMetrics metrics, {bool allowAdvance = true}) {
    if (isComplete || !metrics.isValid) return false;

    if (metrics.roll.abs() > maximumCenterRollDegrees) {
      _clearStability();
      _updateCurrentProgress(0);
      setFeedback('Giữ thẳng đầu, không nghiêng');
      return false;
    }

    if (metrics.yaw.abs() > maximumCenterYaw) {
      _clearStability();
      _updateCurrentProgress(0);
      setFeedback('Nhìn thẳng vào camera');
      return false;
    }

    if (metrics.pitch < 0.20 || metrics.pitch > 0.80) {
      _clearStability();
      _updateCurrentProgress(0);
      setFeedback('Giữ điện thoại ngang tầm mắt');
      return false;
    }

    final ratio = metrics.faceWidthRatio;

    switch (_step) {
      case FaceMotionStep.initial:
        if (ratio > 0 && ratio < initialFaceWidthRatioMin) {
          _clearStability();
          _updateCurrentProgress(ratio / initialFaceWidthRatioMin);
          setFeedback('Đưa khuôn mặt vào gần khung hơn');
          return false;
        }
        if (ratio > initialFaceWidthRatioMax) {
          _clearStability();
          _updateCurrentProgress(0);
          setFeedback('Đưa điện thoại ra xa hơn');
          return false;
        }

        final yawProgress = 1.0 - (metrics.yaw.abs() / maximumCenterYaw);
        final rollProgress =
            1.0 - (metrics.roll.abs() / maximumCenterRollDegrees);
        _updateCurrentProgress(math.min(yawProgress, rollProgress));

        _stableFrames++;
        if (!allowAdvance || _stableFrames < requiredFramesForCurrentStep) {
          return false;
        }

        _baselineRatio = ratio > 0 ? ratio : 0.32;
        _step = FaceMotionStep.closer;
        setFeedback(null);
        _clearStability();
        _updateCurrentProgress(0, forceNotify: true);
        return true;

      case FaceMotionStep.closer:
        final baseline = _baselineRatio ?? 0.32;
        final progress = targetCloseFaceWidthRatio > baseline
            ? ((ratio - baseline) / (targetCloseFaceWidthRatio - baseline))
                .clamp(0.0, 1.0)
            : (ratio >= targetCloseFaceWidthRatio ? 1.0 : 0.0);
        _updateCurrentProgress(progress);

        if (ratio > 0 && ratio < targetCloseFaceWidthRatio) {
          _clearStability();
          setFeedback('Đưa điện thoại lại gần hơn');
          return false;
        }

        if (ratio > 0.84) {
          _clearStability();
          setFeedback('Đưa điện thoại ra xa hơn một chút');
          return false;
        }

        setFeedback('Giữ yên để xác thực...');
        _stableFrames++;
        if (!allowAdvance || _stableFrames < requiredFramesForCurrentStep) {
          return false;
        }

        _step = FaceMotionStep.complete;
        setFeedback(null);
        _clearStability();
        _updateCurrentProgress(1.0, forceNotify: true);
        return true;

      case FaceMotionStep.complete:
        return false;
    }
  }

  void reset() {
    final shouldNotify = _step != FaceMotionStep.initial;
    _step = FaceMotionStep.initial;
    _baselineRatio = null;
    setFeedback(null);
    _clearStability();
    _updateCurrentProgress(0, forceNotify: shouldNotify);
  }

  void _clearStability() {
    _stableFrames = 0;
  }

  void _updateCurrentProgress(double value, {bool forceNotify = false}) {
    final normalized = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    _currentStepProgress = normalized;
    final bucket = (normalized * 10).floor();
    if (!forceNotify && bucket == _lastProgressBucket) return;
    _lastProgressBucket = bucket;
    _scheduleNotification();
  }

  void _scheduleNotification() {
    if (_notificationScheduled || _isDisposed) return;
    _notificationScheduled = true;
    scheduleMicrotask(() {
      _notificationScheduled = false;
      if (!_isDisposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
