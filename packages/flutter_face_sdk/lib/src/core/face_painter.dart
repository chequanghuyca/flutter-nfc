import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import '../data/dbhelper.dart';
import '../models/faceid_model.dart';
import '../presentation/widgets/dialog_custom.dart';
import '../presentation/widgets/face_fill_light.dart';
import 'converter.dart';
import 'face_tracker.dart';
import 'face_verification_policy.dart';
import 'flutter_face_sdk.dart' as fsdk;

class FacesPainter extends CustomPainter {
  final BuildContext context;
  final FaceIDModel model;
  final FacesTracker tracker;
  final FaceIDDBHelper dbHelper;
  final int sensorOrientation;
  final Future<void> Function() cameraPause;
  final Future<void> Function() cameraResume;
  final Future<void> Function() cameraClose;
  final String tryAgainBtnTitle;
  final String exitBtnTitle;
  final bool managesNavigation;
  final VoidCallback? onExit;
  final bool compactEmbedded;
  final double radius1;
  final double radius2;

  FacesPainter({
    required this.context,
    required this.model,
    required this.tracker,
    required this.dbHelper,
    required this.sensorOrientation,
    required this.cameraPause,
    required this.cameraResume,
    required this.cameraClose,
    required this.tryAgainBtnTitle,
    required this.exitBtnTitle,
    this.managesNavigation = true,
    this.onExit,
    this.compactEmbedded = false,
    required this.radius1,
    required this.radius2,
  }) : super(repaint: tracker);

  int livenessCount = 0;
  bool _isMatching = false;
  bool _verificationCompleted = false;
  bool _loadingDialogVisible = false;
  int _lastProcessedFrame = -1;
  FaceFramingDecision? _lastFramingDecision;
  double _lowestPassingLiveness = 1;

  dynamic fileToCompare;

  ImageConverter converter = ImageConverter();

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    textWidthBasis: TextWidthBasis.longestLine,
  );

  var overlayPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 500
    ..style = PaintingStyle.stroke;

  var strokePaint = Paint()
    ..color = const Color(0XFFFC2E55)
    ..strokeWidth = 10
    ..style = PaintingStyle.stroke;

  final Paint _compactOverlayPaint = Paint()
    // The clipped preview BackdropFilter supplies the soft fill light.
    ..color = Colors.transparent
    ..style = PaintingStyle.fill;

  // Keep only normalized JPEG paths. Holding CameraImage instances retains the
  // camera plane buffers and the plugin may reuse them before matching starts.
  final List<File> _sampleFiles = <File>[];
  int? _sampleFaceId;
  Path? overlayPath;
  Path? circlePath;
  Path? circle;
  Size? _overlaySize;
  var angle = (pi * 2) / 50;

  @override
  void paint(Canvas canvas, Size size) async {
    if (_isMatching || _verificationCompleted) {
      if (compactEmbedded) {
        _ensureOverlayPaths(size);
        _drawOverlay(canvas);
      }
      return;
    }
    _ensureOverlayPaths(size);
    if (!tracker.isReady) {
      _drawOverlay(canvas);
      if (compactEmbedded) {
        strokePaint
          ..color = const Color(0xFFA5B4FC)
          ..strokeWidth = 4;
      }
      canvas.drawPath(circlePath!, strokePaint);
      tracker.next();
      return;
    }

    _drawOverlay(canvas);

    // Layout/animation repaints are not new camera frames. Never count them
    // as consecutive observations or save the same frame twice.
    if (_lastProcessedFrame == tracker.completedFrameCount) return;
    _lastProcessedFrame = tracker.completedFrameCount;

    //--------------------------

    final trackedFaces = tracker.faces();
    if (trackedFaces.isEmpty) {
      livenessCount = 0;
      runError(
        text: 'Đưa điện thoại ngang tầm mắt và đặt mặt vào khung hình',
        canvas: canvas,
        size: size,
      );
      tracker.next();
    } else if (!hasExactlyOneFace(trackedFaces.length)) {
      // Samples from different people must never be combined into a successful
      // attendance attempt.
      _clearSamples();
      livenessCount = 0;
      runError(
        text: model.helpText.multiFace,
        canvas: canvas,
        size: size,
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        tracker.resetTracker();
        tracker.next();
      });
    } else {
      try {
        for (final face in trackedFaces) {
          final position = face.position;
          final rotation = Platform.isAndroid
              ? androidFrontCameraImageQuarterTurns()
              : -(sensorOrientation ~/ 90) + 1;
          final swapsDimensions = rotation.isOdd;
          final frameWidth =
              (swapsDimensions ? tracker.height : tracker.width).toDouble();
          final frameHeight =
              (swapsDimensions ? tracker.width : tracker.height).toDouble();
          final framingDecision = evaluateFaceFraming(
            faceCenterX: position.xc.toDouble(),
            faceCenterY: position.yc.toDouble(),
            faceWidth: position.w.toDouble(),
            frameWidth: frameWidth,
            frameHeight: frameHeight,
            movementCheckpoint: model.motionChallenge != null &&
                !model.motionChallenge!.isFinalCenterStep,
          );

          if (_lastFramingDecision != framingDecision) {
            final ratio = position.w / frameWidth;
            debugPrint(
              'FaceID framing: decision=${framingDecision.name} '
              'widthRatio=${ratio.toStringAsFixed(3)} '
              'center=${position.xc},${position.yc} '
              'frame=${frameWidth.toInt()}x${frameHeight.toInt()}',
            );
            _lastFramingDecision = framingDecision;
          }

          if (model.isDebugMode) {
            final tl = Offset(
                    position.xc - position.w / 2, position.yc - position.w / 2)
                .scale(model.scale!, model.scale!)
                .translate(model.offsetX!, model.offsetY!);
            final br = Offset(
                    position.xc + position.w / 2, position.yc + position.w / 2)
                .scale(model.scale!, model.scale!)
                .translate(model.offsetX!, model.offsetY!);
            canvas.drawCircle(tl, 3, strokePaint);
            canvas.drawCircle(br, 3, strokePaint);
          }

          if (framingDecision != FaceFramingDecision.accepted) {
            livenessCount = 0;
            var message =
                model.helpText.moveFaceCenter ?? model.helpText.moveFaceIn;
            if (framingDecision == FaceFramingDecision.tooFar) {
              message = model.helpText.moveFaceIn;
            } else if (framingDecision == FaceFramingDecision.tooClose) {
              message = model.helpText.moveFaceOut;
            }
            runError(
              text: message,
              canvas: canvas,
              size: size,
            );
            tracker.next();
            return;
          }

          if (framingDecision == FaceFramingDecision.accepted) {
            runCorrect(
              text: model.helpText.detecting,
              canvas: canvas,
              size: size,
            );

            final livenessThreshold = resolveFaceLivenessThreshold(
              model.livenessFaceID,
              useConfiguredThreshold: model.useConfiguredLivenessThreshold,
            );
            if (_sampleFaceId != null && _sampleFaceId != face.id) {
              // Luxand may allocate a new tracker id while the same user turns
              // far enough. Preserve completed checkpoints; each saved frame
              // is still independently checked against the DG2 portrait.
              _sampleFaceId = face.id;
            }
            final liveness = face.liveness;
            final livenessDecision =
                evaluateFaceLiveness(liveness, livenessThreshold);

            final motion = model.motionChallenge;
            if (motion != null) {
              final pose = face.poseMetrics(position.angle)?.copyWith(
                    faceWidthRatio: position.w / frameWidth,
                    faceCenterX: position.xc.toDouble(),
                    faceCenterY: position.yc.toDouble(),
                  );
              if (pose == null) {
                motion.interruptObservation(
                    'Giữ điện thoại ngang tầm mắt để thấy rõ khuôn mặt');
                tracker.next();
                return;
              }

              final isClose = motion.isCloserStep;
              final currentLivenessThreshold = resolveLivenessThresholdForStep(
                isCenter: isClose,
                configuredCenterThreshold: model.livenessFaceID,
                turningThreshold: model.directionLivenessThreshold ??
                    defaultTurningLivenessThreshold,
                useConfiguredThreshold: model.useConfiguredLivenessThreshold,
              );
              final livenessDecision =
                  evaluateFaceLiveness(liveness, currentLivenessThreshold);

              final allowedToAdvance = isClose
                  ? livenessDecision == FaceLivenessDecision.accepted
                  : livenessDecision != FaceLivenessDecision.rejected;

              final advanced =
                  motion.observe(pose, allowAdvance: allowedToAdvance);

              if (isClose) {
                motion.setFeedback(
                    !allowedToAdvance && motion.currentStepProgress >= 0.95
                        ? 'Giữ yên một chút, đang kiểm tra người thật'
                        : null);
              }

              if (advanced) {
                _sampleFaceId = face.id;
                if (isClose && liveness != null) {
                  _lowestPassingLiveness = liveness;
                } else if (liveness != null &&
                    liveness >= currentLivenessThreshold) {
                  _lowestPassingLiveness =
                      min(_lowestPassingLiveness, liveness);
                }
                _sampleFiles.add(_saveCurrentFrame());
                if (motion.isComplete) {
                  await cameraPause();
                  await matchFace();
                } else {
                  tracker.next();
                }
              } else {
                // Keep feeding Luxand's liveness window, including during a
                // turn. Resetting it here prevents the score from settling.
                tracker.next();
              }
              return;
            }

            if (livenessDecision == FaceLivenessDecision.pending) {
              // AttributeNotDetected is normal while Luxand accumulates its
              // liveness window. Feed another frame without penalizing/resetting
              // the real user or discarding already valid samples.
              Future.delayed(const Duration(milliseconds: 150), () {
                tracker.next();
              });
              return;
            }

            if (livenessDecision == FaceLivenessDecision.rejected) {
              livenessCount++;
              developer.log(
                'liveness rejected: $liveness, count: $livenessCount',
              );
              if (livenessCount > 5) {
                // hide previous text
                drawText(
                  color: Colors.white,
                  text: model.helpText.detecting,
                  width: size.width,
                  canvas: canvas,
                  size: size,
                );

                saveToLog(
                    desc: model.helpText.faceInvalid,
                    liveness: liveness ?? -1,
                    matching: -1,
                    allowSaveOnly: false);
                livenessCount = 0;

                runError(
                  text: model.helpText.faceInvalid,
                  canvas: canvas,
                  size: size,
                );

                Future.delayed(const Duration(milliseconds: 800), () {
                  tracker.resetTracker();
                  tracker.next();
                });
              } else {
                Future.delayed(const Duration(milliseconds: 300), () {
                  tracker.next();
                });
              }
            } else if (livenessDecision == FaceLivenessDecision.accepted) {
              livenessCount = 0;
              _sampleFaceId = face.id;
              if (liveness != null && liveness < _lowestPassingLiveness) {
                _lowestPassingLiveness = liveness;
              }

              final sample = _saveCurrentFrame();
              _sampleFiles.add(sample);
              final hasEnoughSamples = _sampleFiles.length >=
                  requiredFaceSampleCount(model.differentCountFaceID);
              if (hasEnoughSamples) {
                tracker.resetTracker();
                await cameraPause();
                await matchFace();
              } else {
                Future.delayed(const Duration(milliseconds: 300), () {
                  tracker.next();
                });
              }
            }
          }
        }
      } on fsdk.IdNotFoundError {
        developer.log('catch 1');
        tracker.next();
      } catch (e) {
        developer.log('catch 2 $e');
        if (model.motionChallenge?.completedStepCount != _sampleFiles.length &&
            model.motionChallenge != null) {
          // A checkpoint cannot survive a failed JPEG write.
          _clearSamples();
        }
        tracker.next();
      }
    }
  }

  double? _lastOverlayScale;

  void _ensureOverlayPaths(Size size) {
    final targetScale = model.motionChallenge?.targetFrameScale ?? 1.0;
    if (_overlaySize == size &&
        _lastOverlayScale == targetScale &&
        overlayPath != null &&
        circlePath != null) {
      return;
    }
    _overlaySize = size;
    _lastOverlayScale = targetScale;

    circlePath = Path()
      ..addRRect(embeddedFaceGuideRRect(size, scale: targetScale));
    overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      circlePath!,
    );
  }

  void _drawOverlay(Canvas canvas) {
    canvas.drawPath(
      overlayPath!,
      compactEmbedded ? _compactOverlayPaint : overlayPaint,
    );
  }

  void runError({
    required String text,
    required Canvas canvas,
    required Size size,
  }) {
    if (compactEmbedded && model.motionChallenge != null) {
      model.motionChallenge!.interruptObservation(text);
      return;
    }
    drawText(
      color: const Color(0XFFFC2E55),
      text: text,
      width: size.width,
      canvas: canvas,
      size: size,
      force: true,
    );
    strokePaint
      ..color =
          compactEmbedded ? const Color(0xFFFF6B7A) : const Color(0XFFFC2E55)
      ..strokeWidth = compactEmbedded ? 4 : 10;
    canvas.drawPath(circlePath!, strokePaint);
  }

  void runCorrect({
    required String text,
    required Canvas canvas,
    required Size size,
  }) {
    if (compactEmbedded && model.motionChallenge != null) return;
    drawText(
      color: const Color(0xFF00B850),
      text: text,
      width: size.width,
      canvas: canvas,
      size: size,
    );
    strokePaint
      ..color =
          compactEmbedded ? const Color(0xFF34D399) : const Color(0xFF00B850)
      ..strokeWidth = compactEmbedded ? 4 : 10;
    if (compactEmbedded && model.motionChallenge != null) {
      _drawMotionProgressRing(canvas, size);
    } else {
      canvas.drawPath(circlePath!, strokePaint);
    }
  }

  void drawText({
    required Color color,
    required String text,
    required double width,
    required Canvas canvas,
    required Size size,
    bool force = false,
  }) {
    if (!model.showStatusOverlay && !force) return;
    if (compactEmbedded) {
      _drawCompactStatus(
        canvas: canvas,
        size: size,
        text: text,
        accentColor: color,
      );
      return;
    }
    textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ));
    textPainter.layout(maxWidth: size.width, minWidth: size.width);
    textPainter.paint(canvas, Offset(0, size.height / 6));
  }

  void _drawMotionProgressRing(Canvas canvas, Size size) {
    final guide = embeddedFaceGuide(size);
    final progress = model.motionChallenge?.progress ?? 0;
    canvas.drawArc(
      guide,
      -pi / 2,
      pi * 2,
      false,
      Paint()
        ..color = const Color(0xFFD7E8E2)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      guide,
      -pi / 2,
      pi * 2 * progress,
      false,
      Paint()
        ..color = const Color(0xFF28B887)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawCompactStatus({
    required Canvas canvas,
    required Size size,
    required String text,
    required Color accentColor,
  }) {
    final maxPillWidth = max(0.0, size.width - 32);
    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout(maxWidth: max(0.0, maxPillWidth - 32));
    final pillWidth = min(maxPillWidth, textPainter.width + 32);
    final pillHeight = max(42.0, textPainter.height + 18);
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, pillHeight / 2 + 14),
        width: pillWidth,
        height: pillHeight,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = const Color(0xE611172A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = accentColor.withValues(alpha: 0.85)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        pillRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void saveToLog({
    required String desc,
    double liveness = -1,
    double matching = -1,
    String? path,
    bool allowSaveOnly = false, // save 1 ngay lập tức không cần đếm
  }) {
    if (model.logCallback == null) {
      return;
    }

    String imagePath =
        '${dbHelper.tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    if (path == null) {
      fsdk.Image? sourceImage;
      fsdk.Image? cameraImage;
      try {
        sourceImage = converter.convert(tracker.cameraImage!);
        if (Platform.isAndroid) {
          final rotation = androidFrontCameraImageQuarterTurns();
          cameraImage =
              rotation == 0 ? sourceImage : sourceImage.rotate90(rotation);
          cameraImage.mirror(true);
        } else {
          cameraImage = sourceImage;
        }
        cameraImage.saveToFile(imagePath);
      } finally {
        if (!identical(cameraImage, sourceImage)) {
          cameraImage?.free();
        }
        sourceImage?.free();
      }
    } else {
      imagePath = path;
    }

    dbHelper.addData(
      description: desc,
      liveness: liveness,
      matching: matching,
      imagePath: imagePath,
      deviceName: model.deviceName,
      sub: model.userID,
      callback: model.logCallback!,
      countAllowSave: allowSaveOnly ? 1 : model.countAllowSave,
    );
  }

  File _saveCurrentFrame() {
    final cameraFrame = tracker.cameraImage;
    if (cameraFrame == null) {
      throw StateError('Camera frame is unavailable');
    }

    final sampleFile = File(
      '${dbHelper.tempDir.path}/face_sample_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    fsdk.Image? sourceImage;
    fsdk.Image? normalizedImage;
    try {
      sourceImage = converter.convert(cameraFrame);
      if (Platform.isAndroid) {
        final rotation = androidFrontCameraImageQuarterTurns();
        normalizedImage =
            rotation == 0 ? sourceImage : sourceImage.rotate90(rotation);
        normalizedImage.mirror(true);
      } else {
        normalizedImage = sourceImage;
      }
      normalizedImage.saveToFile(sampleFile.path);
      return sampleFile;
    } finally {
      if (!identical(normalizedImage, sourceImage)) {
        normalizedImage?.free();
      }
      sourceImage?.free();
    }
  }

  void _clearSamples() {
    final staleSamples = List<File>.of(_sampleFiles);
    _sampleFiles.clear();
    _sampleFaceId = null;
    _lowestPassingLiveness = 1;
    model.motionChallenge?.reset();
    for (final sample in staleSamples) {
      try {
        if (sample.existsSync()) sample.deleteSync();
      } catch (_) {
        // A stale camera sample must not interrupt the verification flow.
      }
    }
  }

  Future<void> matchFace() async {
    if (_isMatching || _verificationCompleted) {
      return;
    }
    _isMatching = true;
    model.resetVerification(resetMotionChallenge: false);
    developer.log('RUN MATCH FACE');

    _showLoadingDialog();

    final serverFaceFile = File(model.selectedRegisteredFacePath ??
        '${dbHelper.tempDir.path}/server_face.jpg');
    fsdk.Image? serverImage;
    fsdk.FacePositions? serverFaces;
    fsdk.FacialFeatures? serverFeatures;
    fsdk.FaceTemplate? serverTemplate;
    File? verifiedFaceFile;
    File? bestAttemptFile;
    var bestSimilarity = -1.0;
    double? finalStraightSimilarity;
    var finalStraightMatched = false;
    var matchedSampleCount = 0;

    try {
      if (model.registeredFaceFiles != null &&
          model.selectedRegisteredFacePath == null) {
        throw StateError('No validated reference for this FaceID session');
      }
      if (!serverFaceFile.existsSync() || serverFaceFile.lengthSync() == 0) {
        throw StateError('Registered FaceID cache is missing');
      }

      serverImage = fsdk.LoadImageFromFile(serverFaceFile.path);
      serverFaces = serverImage.detectMultipleFaces();
      if (!hasExactlyOneFace(serverFaces.length)) {
        throw StateError(
          'Registered FaceID image must contain exactly one face',
        );
      }
      serverFeatures =
          fsdk.DetectFacialFeaturesInRegion(serverImage, serverFaces.first);
      serverTemplate =
          fsdk.GetFaceTemplateUsingFeatures(serverImage, serverFeatures);

      final sdkReferenceThreshold =
          fsdk.GetMatchingThresholdAtFAR(attendanceFaceMatchFar);
      final matchingThreshold = resolveFaceMatchThreshold(model.matchFaceID,
          allowZero: model.allowZeroMatchThreshold);
      if (!matchingThreshold.isFinite) {
        throw StateError('Face matching threshold is invalid');
      }
      debugPrint(
        '[FaceMatch] configured threshold: $matchingThreshold '
        '(local env), '
        'Luxand FAR 1% reference: $sdkReferenceThreshold',
      );
      final finalStraightFile = _sampleFiles.last;

      for (final cameraFaceFile in _sampleFiles) {
        fsdk.Image? cameraImage;
        fsdk.FacePositions? cameraFaces;
        fsdk.FacialFeatures? cameraFeatures;
        fsdk.FaceTemplate? cameraTemplate;

        try {
          cameraImage = fsdk.LoadImageFromFile(cameraFaceFile.path);

          cameraFaces = cameraImage.detectMultipleFaces();
          if (!hasExactlyOneFace(cameraFaces.length)) {
            final description = cameraFaces.length > 1
                ? model.helpText.multiFace
                : model.helpText.moveFaceIn;
            developer.log('INVALID FACE COUNT ${cameraFaces.length}');
            saveToLog(
              desc: description,
              path: cameraFaceFile.path,
              allowSaveOnly: false,
            );
            _closeLoadingDialog();
            _showRetryDialog(description);
            return;
          }

          cameraFeatures =
              fsdk.DetectFacialFeaturesInRegion(cameraImage, cameraFaces.first);
          cameraTemplate =
              fsdk.GetFaceTemplateUsingFeatures(cameraImage, cameraFeatures);
          final similarity = fsdk.MatchFaces(cameraTemplate, serverTemplate);
          final isFinalStraightSample =
              cameraFaceFile.path == finalStraightFile.path;
          if (isFinalStraightSample) {
            finalStraightSimilarity = similarity;
          }

          final sampleIndex = _sampleFiles.indexOf(cameraFaceFile);
          final turningThreshold = sampleIndex == 0
              ? model.effectiveRightMatchThreshold
              : model.effectiveLeftMatchThreshold;

          // Dynamic match threshold: right/left thresholds for turning samples, env threshold for final straight sample
          final sampleTargetThreshold = resolveMatchThresholdForStep(
            isCenter: isFinalStraightSample,
            configuredCenterThreshold: model.matchFaceID,
            turningThreshold: turningThreshold,
            allowZero: model.allowZeroMatchThreshold,
          );

          debugPrint(
            '[FaceMatch] sample ${isFinalStraightSample ? "straight" : "turning"}: '
            'similarity=$similarity, threshold=$sampleTargetThreshold',
          );

          if (similarity > bestSimilarity) {
            bestSimilarity = similarity;
            bestAttemptFile = cameraFaceFile;
          }

          if (meetsFaceMatchThreshold(similarity, sampleTargetThreshold,
              allowZero: model.allowZeroMatchThreshold)) {
            matchedSampleCount++;
            if (isFinalStraightSample) finalStraightMatched = true;
            verifiedFaceFile = cameraFaceFile;
          }
        } finally {
          cameraTemplate?.free();
          cameraFeatures?.free();
          cameraFaces?.free();
          cameraImage?.free();
        }
      }

      final requiredSamples =
          requiredFaceSampleCount(model.differentCountFaceID);
      if (_sampleFiles.length < requiredSamples) {
        throw StateError('Not enough verified FaceID samples');
      }
      if (verifiedFaceFile == null ||
          finalStraightSimilarity == null ||
          !hasSuccessfulFaceSampleSet(
            totalSampleCount: _sampleFiles.length,
            matchedSampleCount: matchedSampleCount,
            finalStraightSampleMatched: finalStraightMatched,
          )) {
        _closeLoadingDialog();
        developer.log(
          'FACE NOT MATCH $matchedSampleCount/${_sampleFiles.length}, '
          'best: $bestSimilarity',
        );
        saveToLog(
          desc: model.helpText.faceNotMatch,
          matching: bestSimilarity,
          path: bestAttemptFile?.path,
          allowSaveOnly: false,
        );
        _showRetryDialog(model.helpText.faceNotMatch);
        return;
      }
      // The last checkpoint is the strict straight pose. It must independently
      // pass matching and is always the returned/admin-review image.
      verifiedFaceFile = finalStraightFile;
      final verificationSimilarity = finalStraightSimilarity;

      model.markVerificationPassed(
        similarity: verificationSimilarity,
        threshold: matchingThreshold,
        liveness: _lowestPassingLiveness,
        livenessThreshold: resolveFaceLivenessThreshold(
          model.livenessFaceID,
          useConfiguredThreshold: model.useConfiguredLivenessThreshold,
        ),
        faceCount: 1,
        sampleCount: _sampleFiles.length,
        matchedSampleCount: matchedSampleCount,
      );
      _verificationCompleted = true;
      developer.log(
        'FACE MATCHED $verificationSimilarity '
        '($matchedSampleCount/${_sampleFiles.length} samples)',
      );
      saveToLog(
        desc: 'Nhận diện thành công',
        matching: verificationSimilarity,
        path: verifiedFaceFile.path,
        allowSaveOnly: true,
      );
      _closeLoadingDialog();
      if (managesNavigation && context.mounted) {
        Navigator.pop(context);
      }
      model.successCallback(
        verificationSimilarity.toString(),
        verifiedFaceFile,
        model,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Face Match Error: $error',
        stackTrace: stackTrace,
      );
      _closeLoadingDialog();
      _showRetryDialog(model.helpText.faceNotMatch);
    } finally {
      serverTemplate?.free();
      serverFeatures?.free();
      serverFaces?.free();
      serverImage?.free();
      _isMatching = false;
    }
  }

  void _closeLoadingDialog() {
    if (!_loadingDialogVisible) return;
    _loadingDialogVisible = false;
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _showLoadingDialog() {
    final dialogContext = context;
    if (!dialogContext.mounted) return;
    _loadingDialogVisible = true;
    if (!compactEmbedded) {
      DialogCustom.showLoadingDialog(dialogContext);
      return;
    }
    showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: const Color(0x660B1020),
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          elevation: 0,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF343FA0),
                  ),
                ),
                SizedBox(width: 16),
                Flexible(
                  child: Text(
                    model.helpText.verifying,
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRetryDialog(String description) {
    if (!context.mounted) {
      return;
    }
    if (compactEmbedded) {
      _showCompactRetryDialog(context, description);
      return;
    }
    DialogCustom.showMessageDialogIOS(
      context,
      title: 'Thông báo',
      description: description,
      onPress: () async {
        Navigator.pop(context);
        model.resetVerification();
        _clearSamples();
        await cameraResume();
        tracker.next();
      },
      buttonText: tryAgainBtnTitle,
      buttonNoText: exitBtnTitle,
      enableCancel: true,
      onPressX: () {
        Navigator.pop(context);
        if (managesNavigation) {
          Navigator.pop(context);
        } else {
          onExit?.call();
        }
      },
    );
  }

  void _showCompactRetryDialog(
    BuildContext dialogContext,
    String description,
  ) {
    showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: const Color(0x730B1020),
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_off_rounded,
                    color: Color(0xFFE6405B),
                    size: 29,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  model.helpText.retryTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onExit?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFD8E0EC)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(exitBtnTitle),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          model.resetVerification();
                          _clearSamples();
                          await cameraResume();
                          tracker.next();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF343FA0),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(tryAgainBtnTitle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
