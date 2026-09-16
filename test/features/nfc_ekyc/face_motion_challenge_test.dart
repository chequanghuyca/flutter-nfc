import 'package:flutter_face_sdk/flutter_face_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FacePoseMetrics pose({
    double yaw = 0,
    double pitch = 0.5,
    double roll = 0,
    double faceWidthRatio = 0.32,
  }) => FacePoseMetrics(
    yaw: yaw,
    pitch: pitch,
    roll: roll,
    faceWidthRatio: faceWidthRatio,
  );

  bool hold(FaceMotionChallenge challenge, FacePoseMetrics value) {
    var advanced = false;
    final frameCount = challenge.requiredFramesForCurrentStep;
    for (var index = 0; index < frameCount; index++) {
      advanced = challenge.observe(value);
    }
    return advanced;
  }

  test('requires initial framing then closer proximity step', () {
    final challenge = FaceMotionChallenge();

    expect(challenge.step, FaceMotionStep.initial);
    expect(challenge.direction, FaceMotionDirection.initial);

    // Step 1: Initial small frame
    expect(hold(challenge, pose(faceWidthRatio: 0.32)), isTrue);
    expect(challenge.step, FaceMotionStep.closer);
    expect(challenge.direction, FaceMotionDirection.closer);

    // Step 2: Closer proximity
    expect(hold(challenge, pose(faceWidthRatio: 0.54)), isTrue);
    expect(challenge.step, FaceMotionStep.complete);
    expect(challenge.isComplete, isTrue);
    expect(challenge.progress, 1.0);
  });

  test('rejects face if turned or tilted too much', () {
    final challenge = FaceMotionChallenge();

    // Turned head (yaw > 0.12)
    expect(challenge.observe(pose(yaw: 0.20)), isFalse);
    expect(challenge.hasFeedback, isTrue);

    // Tilted head (roll > 14)
    expect(challenge.observe(pose(roll: 20)), isFalse);
    expect(challenge.hasFeedback, isTrue);
  });

  test('exposes dynamic progress as face moves closer', () {
    final challenge = FaceMotionChallenge();

    // Complete initial step with baseline ratio 0.30
    expect(hold(challenge, pose(faceWidthRatio: 0.30)), isTrue);
    expect(challenge.step, FaceMotionStep.closer);

    // Intermediate proximity (halfway between 0.30 and 0.52)
    expect(challenge.observe(pose(faceWidthRatio: 0.41)), isFalse);
    expect(challenge.currentStepProgress, greaterThan(0.4));
    expect(challenge.currentStepProgress, lessThan(0.7));

    // Fully close
    expect(hold(challenge, pose(faceWidthRatio: 0.54)), isTrue);
    expect(challenge.step, FaceMotionStep.complete);
    expect(challenge.progress, 1.0);
  });

  test('estimates normalized pose from Luxand landmark coordinates', () {
    final metrics = estimateFacePose(
      leftEyeX: 30,
      leftEyeY: 30,
      rightEyeX: 70,
      rightEyeY: 30,
      noseX: 54,
      noseY: 50,
      mouthLeftX: 40,
      mouthLeftY: 70,
      mouthRightX: 60,
      mouthRightY: 70,
      roll: 2,
      faceWidthRatio: 0.35,
    );

    expect(metrics, isNotNull);
    expect(metrics!.yaw, closeTo(0.1, 0.001));
    expect(metrics.pitch, closeTo(0.5, 0.001));
    expect(metrics.roll, 2);
    expect(metrics.faceWidthRatio, 0.35);
  });

  test('updates progress while liveness is pending without advancing', () {
    final challenge = FaceMotionChallenge();
    expect(
      challenge.observe(pose(faceWidthRatio: 0.32), allowAdvance: false),
      isFalse,
    );
    expect(challenge.step, FaceMotionStep.initial);
    expect(challenge.observe(pose(faceWidthRatio: 0.32)), isTrue);
    expect(challenge.step, FaceMotionStep.closer);
  });

  test('interruptObservation resets stability streak', () {
    final challenge = FaceMotionChallenge();
    expect(hold(challenge, pose(faceWidthRatio: 0.32)), isTrue);
    expect(challenge.step, FaceMotionStep.closer);

    challenge.observe(pose(faceWidthRatio: 0.54), allowAdvance: false);
    challenge.interruptObservation('Đưa mặt vào khung');
    expect(challenge.hasFeedback, isTrue);
    expect(challenge.observe(pose(faceWidthRatio: 0.54)), isFalse);
    expect(challenge.observe(pose(faceWidthRatio: 0.54)), isTrue);
    expect(challenge.isComplete, isTrue);
  });
}
