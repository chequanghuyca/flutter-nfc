const double attendanceFaceMatchFar = 0.01;
const double minimumFaceLivenessThreshold = 0.8;

int androidFrontCameraImageQuarterTurns() {
  // The app is locked to portraitUp and only uses the Android front camera.
  // Flutter rotates CameraPreview independently, while the YUV stream remains
  // landscape. Luxand's Android front-camera pipeline requires one
  // counter-clockwise quarter turn followed by horizontal mirroring.
  return -1;
}

/// Use screen brightness for face illumination, never positive camera EV.
/// Shared by embedded/fullscreen Luxand and the app's selfie/EIR cameras.
const double neutralFaceExposureOffset = 0.0;
const double minimumFaceWidthRatio = 0.22;
const double maximumFaceWidthRatio = 0.74;
const double maximumHorizontalFaceCenterOffsetRatio = 0.36;
const double maximumVerticalFaceCenterOffsetRatio = 0.36;

enum FaceLivenessDecision { pending, rejected, accepted }

enum FaceFramingDecision { tooFar, tooClose, offCenter, accepted }

bool hasExactlyOneFace(int faceCount) => faceCount == 1;

FaceFramingDecision evaluateFaceFraming({
  required double faceCenterX,
  required double faceCenterY,
  required double faceWidth,
  required double frameWidth,
  required double frameHeight,
  bool movementCheckpoint = false,
}) {
  if (!faceCenterX.isFinite ||
      !faceCenterY.isFinite ||
      !faceWidth.isFinite ||
      !frameWidth.isFinite ||
      !frameHeight.isFinite ||
      faceWidth <= 0 ||
      frameWidth <= 0 ||
      frameHeight <= 0) {
    return FaceFramingDecision.offCenter;
  }

  final faceWidthRatio = faceWidth / frameWidth;
  if (faceWidthRatio < (movementCheckpoint ? 0.15 : minimumFaceWidthRatio)) {
    return FaceFramingDecision.tooFar;
  }
  if (faceWidthRatio > (movementCheckpoint ? 0.82 : maximumFaceWidthRatio)) {
    return FaceFramingDecision.tooClose;
  }

  final horizontalOffsetRatio =
      (faceCenterX - frameWidth / 2).abs() / frameWidth;
  final verticalOffsetRatio =
      (faceCenterY - frameHeight / 2).abs() / frameHeight;
  if (horizontalOffsetRatio >
          (movementCheckpoint
              ? 0.44
              : maximumHorizontalFaceCenterOffsetRatio) ||
      verticalOffsetRatio >
          (movementCheckpoint ? 0.44 : maximumVerticalFaceCenterOffsetRatio)) {
    return FaceFramingDecision.offCenter;
  }

  return FaceFramingDecision.accepted;
}

bool meetsFaceMatchThreshold(double similarity, double threshold,
    {bool allowZero = false}) {
  return similarity.isFinite &&
      threshold.isFinite &&
      (allowZero ? threshold >= 0 : threshold > 0) &&
      threshold <= 1 &&
      similarity >= threshold;
}

double resolveFaceMatchThreshold(double configuredThreshold,
    {bool allowZero = false}) {
  if (!configuredThreshold.isFinite ||
      (allowZero ? configuredThreshold < 0 : configuredThreshold <= 0) ||
      configuredThreshold > 1) {
    return double.infinity;
  }
  return configuredThreshold;
}

int requiredFaceSampleCount(int? configuredCount) {
  if (configuredCount == null || configuredCount < 2) {
    return 2;
  }
  if (configuredCount > 5) {
    return 5;
  }
  return configuredCount;
}

int requiredSuccessfulFaceSampleCount(int totalSampleCount) {
  if (totalSampleCount <= 2) {
    return 1;
  }
  return totalSampleCount ~/ 2 + 1;
}

bool hasSuccessfulFaceSampleQuorum({
  required int totalSampleCount,
  required int matchedSampleCount,
}) {
  return totalSampleCount >= 2 &&
      matchedSampleCount >=
          requiredSuccessfulFaceSampleCount(totalSampleCount) &&
      matchedSampleCount <= totalSampleCount;
}

bool hasSuccessfulFaceSampleSet({
  required int totalSampleCount,
  required int matchedSampleCount,
  required bool finalStraightSampleMatched,
}) =>
    finalStraightSampleMatched &&
    hasSuccessfulFaceSampleQuorum(
      totalSampleCount: totalSampleCount,
      matchedSampleCount: matchedSampleCount,
    );

double resolveFaceLivenessThreshold(double configuredThreshold,
    {bool useConfiguredThreshold = false}) {
  if (useConfiguredThreshold) {
    return configuredThreshold.isFinite &&
            configuredThreshold >= 0 &&
            configuredThreshold <= 1
        ? configuredThreshold
        : 0.85;
  }
  if (!configuredThreshold.isFinite ||
      configuredThreshold < minimumFaceLivenessThreshold ||
      configuredThreshold > 1) {
    return minimumFaceLivenessThreshold;
  }
  return configuredThreshold;
}

FaceLivenessDecision evaluateFaceLiveness(
  double? liveness,
  double threshold,
) {
  if (liveness == null || !liveness.isFinite) {
    return FaceLivenessDecision.pending;
  }
  return liveness >= threshold
      ? FaceLivenessDecision.accepted
      : FaceLivenessDecision.rejected;
}

/// Default thresholds for turning directions (Phải, Dưới, Trái, Trên).
/// These are relaxed to 0.5 for easy scanning and matching during rotation,
/// while the final center (Thẳng) pose strictly enforces the environment thresholds.
const double defaultTurningLivenessThreshold = 0.50;
const double defaultTurningMatchThreshold = 0.50;

double resolveLivenessThresholdForStep({
  required bool isCenter,
  required double configuredCenterThreshold,
  double turningThreshold = defaultTurningLivenessThreshold,
  bool useConfiguredThreshold = false,
}) {
  if (isCenter) {
    return resolveFaceLivenessThreshold(
      configuredCenterThreshold,
      useConfiguredThreshold: useConfiguredThreshold,
    );
  }
  return turningThreshold;
}

double resolveMatchThresholdForStep({
  required bool isCenter,
  required double configuredCenterThreshold,
  double turningThreshold = defaultTurningMatchThreshold,
  bool allowZero = false,
}) {
  if (isCenter) {
    return resolveFaceMatchThreshold(
      configuredCenterThreshold,
      allowZero: allowZero,
    );
  }
  return resolveFaceMatchThreshold(
    turningThreshold,
    allowZero: allowZero,
  );
}
