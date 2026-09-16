import 'dart:io';

import '../core/face_verification_policy.dart';
import '../core/face_motion_challenge.dart';
import 'helptext_model.dart';
import 'package:http/http.dart' as http;

class FaceIDModel {
  Function(String, File, FaceIDModel) successCallback;
  Function(String desc, List<http.MultipartFile>)? logCallback;
  String? imageTrainPath;
  final Map<String, String>? registeredFaceFiles;
  final Future<Map<String, String>> Function()? refreshRegisteredFaces;
  String? selectedRegisteredFacePath;
  double distanceFaceID;
  int timeoutSecond;
  double livenessFaceID;

  /// Order Active has a validated, server-managed threshold. Other callers
  /// retain the SDK's existing minimum-liveness policy by default.
  final bool useConfiguredLivenessThreshold;
  double matchFaceID;
  final bool allowZeroMatchThreshold;
  final double? directionLivenessThreshold;
  final double? directionMatchThreshold;
  final double? rightMatchThreshold;
  final double? rightLivenessThreshold;
  final double? leftMatchThreshold;
  final double? leftLivenessThreshold;
  final double? cameraExposureOffset;
  int? differentCountFaceID;
  String? backgroundUserGuideFaceID;
  bool isDebugMode;
  bool? isSaveDebugFaceID;
  String deviceName;
  String? imageHelpFaceID;
  String? videoHelpFaceID;
  bool? isOffVideoFaceID;
  bool allowTimeout;
  String timeoutTitle;
  HelpText helpText;
  String? userID;
  int? countAllowSave;
  double? scale;
  double? radius;
  final FaceMotionChallenge? motionChallenge;
  final bool showStatusOverlay;
  double? offsetX;
  double? offsetY;
  bool _verificationPassed = false;
  double? _verifiedSimilarity;
  double? _verifiedThreshold;
  double? _verifiedLiveness;
  double? _verifiedLivenessThreshold;
  int _verifiedFaceCount = 0;
  int _verifiedSampleCount = 0;
  int _verifiedMatchedSampleCount = 0;

  bool get verificationPassed => _verificationPassed;
  double? get verifiedSimilarity => _verifiedSimilarity;
  double? get verifiedThreshold => _verifiedThreshold;
  double? get verifiedLiveness => _verifiedLiveness;
  double? get verifiedLivenessThreshold => _verifiedLivenessThreshold;
  int get verifiedFaceCount => _verifiedFaceCount;
  int get verifiedSampleCount => _verifiedSampleCount;
  int get verifiedMatchedSampleCount => _verifiedMatchedSampleCount;
  bool get hasValidVerification =>
      _verificationPassed &&
      _verifiedFaceCount == 1 &&
      hasSuccessfulFaceSampleQuorum(
        totalSampleCount: _verifiedSampleCount,
        matchedSampleCount: _verifiedMatchedSampleCount,
      ) &&
      _verifiedSimilarity != null &&
      _verifiedThreshold != null &&
      _verifiedLiveness != null &&
      _verifiedLivenessThreshold != null &&
      _verifiedSimilarity!.isFinite &&
      _verifiedThreshold!.isFinite &&
      _verifiedLiveness!.isFinite &&
      _verifiedLivenessThreshold!.isFinite &&
      (allowZeroMatchThreshold
          ? _verifiedThreshold! >= 0
          : _verifiedThreshold! > 0) &&
      _verifiedThreshold! <= 1 &&
      _verifiedSimilarity! >= _verifiedThreshold! &&
      _verifiedLivenessThreshold! > 0 &&
      _verifiedLivenessThreshold! <= 1 &&
      _verifiedLiveness! >= _verifiedLivenessThreshold! &&
      (motionChallenge?.isComplete ?? true);

  void resetVerification({bool resetMotionChallenge = true}) {
    _verificationPassed = false;
    _verifiedSimilarity = null;
    _verifiedThreshold = null;
    _verifiedLiveness = null;
    _verifiedLivenessThreshold = null;
    _verifiedFaceCount = 0;
    _verifiedSampleCount = 0;
    _verifiedMatchedSampleCount = 0;
    if (resetMotionChallenge) motionChallenge?.reset();
  }

  void markVerificationPassed({
    required double similarity,
    required double threshold,
    required double liveness,
    required double livenessThreshold,
    required int faceCount,
    required int sampleCount,
    required int matchedSampleCount,
  }) {
    if (!similarity.isFinite ||
        !threshold.isFinite ||
        (allowZeroMatchThreshold ? threshold < 0 : threshold <= 0) ||
        threshold > 1 ||
        similarity < threshold ||
        !liveness.isFinite ||
        !livenessThreshold.isFinite ||
        livenessThreshold <= 0 ||
        livenessThreshold > 1 ||
        liveness < livenessThreshold ||
        faceCount != 1 ||
        !hasSuccessfulFaceSampleQuorum(
          totalSampleCount: sampleCount,
          matchedSampleCount: matchedSampleCount,
        )) {
      throw StateError('Invalid FaceID verification result');
    }
    _verificationPassed = true;
    _verifiedSimilarity = similarity;
    _verifiedThreshold = threshold;
    _verifiedLiveness = liveness;
    _verifiedLivenessThreshold = livenessThreshold;
    _verifiedFaceCount = faceCount;
    _verifiedSampleCount = sampleCount;
    _verifiedMatchedSampleCount = matchedSampleCount;
  }

  FaceIDModel({
    this.imageTrainPath,
    this.registeredFaceFiles,
    this.refreshRegisteredFaces,
    this.backgroundUserGuideFaceID,
    required this.deviceName,
    this.differentCountFaceID,
    this.distanceFaceID = 1.0,
    this.imageHelpFaceID,
    this.isDebugMode = false,
    this.isOffVideoFaceID,
    this.isSaveDebugFaceID,
    this.livenessFaceID = 0.8,
    this.useConfiguredLivenessThreshold = false,
    required this.matchFaceID,
    this.allowZeroMatchThreshold = false,
    this.directionLivenessThreshold,
    this.directionMatchThreshold,
    this.rightMatchThreshold,
    this.rightLivenessThreshold,
    this.leftMatchThreshold,
    this.leftLivenessThreshold,
    this.cameraExposureOffset,
    required this.successCallback,
    this.timeoutSecond = -1,
    this.allowTimeout = false,
    this.videoHelpFaceID,
    this.timeoutTitle = '',
    required this.helpText,
    this.userID,
    this.logCallback,
    this.countAllowSave,
    this.scale,
    this.offsetX,
    this.offsetY,
    this.radius,
    this.motionChallenge,
    this.showStatusOverlay = true,
  });

  double get effectiveRightMatchThreshold =>
      rightMatchThreshold ??
      directionMatchThreshold ??
      defaultTurningMatchThreshold;
  double get effectiveRightLivenessThreshold =>
      rightLivenessThreshold ??
      directionLivenessThreshold ??
      defaultTurningLivenessThreshold;
  double get effectiveLeftMatchThreshold =>
      leftMatchThreshold ??
      directionMatchThreshold ??
      defaultTurningMatchThreshold;
  double get effectiveLeftLivenessThreshold =>
      leftLivenessThreshold ??
      directionLivenessThreshold ??
      defaultTurningLivenessThreshold;
}
