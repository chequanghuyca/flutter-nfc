import 'package:flutter_face_sdk/flutter_face_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'movement framing allows a small face offset but final framing stays strict',
    () {
      FaceFramingDecision framing(bool movement) => evaluateFaceFraming(
        faceCenterX: 320,
        faceCenterY: 700,
        faceWidth: 128,
        frameWidth: 640,
        frameHeight: 960,
        movementCheckpoint: movement,
      );
      expect(framing(true), FaceFramingDecision.accepted);
      expect(framing(false), FaceFramingDecision.tooFar);
    },
  );
  test('accepts quorum only when the final straight sample also matches', () {
    expect(
      hasSuccessfulFaceSampleSet(
        totalSampleCount: 3,
        matchedSampleCount: 2,
        finalStraightSampleMatched: true,
      ),
      isTrue,
    );
  });

  test('rejects quorum when the final straight sample does not match', () {
    expect(
      hasSuccessfulFaceSampleSet(
        totalSampleCount: 3,
        matchedSampleCount: 2,
        finalStraightSampleMatched: false,
      ),
      isFalse,
    );
  });

  test(
    'rejects quorum when match count is below required count for 3 samples',
    () {
      expect(
        hasSuccessfulFaceSampleSet(
          totalSampleCount: 3,
          matchedSampleCount: 1,
          finalStraightSampleMatched: true,
        ),
        isFalse,
      );
    },
  );

  test(
    'accepts quorum for 2 samples when the final close-up sample matches',
    () {
      expect(
        hasSuccessfulFaceSampleSet(
          totalSampleCount: 2,
          matchedSampleCount: 1,
          finalStraightSampleMatched: true,
        ),
        isTrue,
      );
    },
  );

  test(
    'dynamic direction thresholds relax turning steps to 0.5 and enforce strict center',
    () {
      expect(
        resolveLivenessThresholdForStep(
          isCenter: false,
          configuredCenterThreshold: 0.80,
        ),
        0.50,
      );
      expect(
        resolveLivenessThresholdForStep(
          isCenter: true,
          configuredCenterThreshold: 0.80,
        ),
        0.80,
      );
      expect(
        resolveMatchThresholdForStep(
          isCenter: false,
          configuredCenterThreshold: 0.81,
        ),
        0.50,
      );
      expect(
        resolveMatchThresholdForStep(
          isCenter: true,
          configuredCenterThreshold: 0.81,
        ),
        0.81,
      );
    },
  );
}
