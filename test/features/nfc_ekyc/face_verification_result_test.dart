import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/face_verification_result.dart';

void main() {
  group('FaceVerificationResult', () {
    test('accepts a score exactly at the configured threshold', () {
      final result = FaceVerificationResult(
        similarity: 0.81,
        threshold: 0.81,
        liveness: 0.85,
        livenessThreshold: 0.85,
        captureBytes: Uint8List.fromList(const [1]),
      );

      expect(result.isMatched, isTrue);
    });

    test('rejects a score below the configured threshold', () {
      final result = FaceVerificationResult(
        similarity: 0.809,
        threshold: 0.81,
        liveness: 0.85,
        livenessThreshold: 0.85,
        captureBytes: Uint8List.fromList(const [1]),
      );

      expect(result.isMatched, isFalse);
    });

    test('rejects a liveness score below its threshold', () {
      final result = FaceVerificationResult(
        similarity: 0.9,
        threshold: 0.85,
        liveness: 0.849,
        livenessThreshold: 0.85,
        captureBytes: Uint8List.fromList(const [1]),
      );

      expect(result.isMatched, isFalse);
    });
  });
}
