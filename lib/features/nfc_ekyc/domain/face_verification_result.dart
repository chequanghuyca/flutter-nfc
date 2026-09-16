import 'dart:typed_data';

class FaceVerificationResult {
  const FaceVerificationResult({
    required this.similarity,
    required this.threshold,
    required this.liveness,
    required this.livenessThreshold,
    required this.captureBytes,
  });

  final double similarity;
  final double threshold;
  final double liveness;
  final double livenessThreshold;
  final Uint8List captureBytes;

  bool get isMatched =>
      similarity >= threshold && liveness >= livenessThreshold;
}
