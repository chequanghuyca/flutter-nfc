import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/luxand_verification_config.dart';

void main() {
  test(
    'loads core thresholds and exposure offset from dart define environment',
    () {
      final config = LuxandVerificationConfig.fromEnvironment();

      expect(config.matchThreshold, 0.85);
      expect(config.livenessThreshold, 0.85);
      expect(config.cameraExposureOffset, 0.60);
    },
  );

  test('interprets 0.85 as 85 percent', () {
    expect(LuxandVerificationConfig.percent(0.85), '85%');
  });

  test('accepts match and liveness ratios in the supported range', () {
    const config = LuxandVerificationConfig(
      matchThreshold: 0.85,
      livenessThreshold: 0.85,
      cameraExposureOffset: 0.60,
    );

    expect(config.validationError, isNull);
  });

  test('rejects percentage values written as 85 instead of 0.85', () {
    const config = LuxandVerificationConfig(
      matchThreshold: 85,
      livenessThreshold: 0.85,
    );

    expect(config.validationError, contains('LUXAND_MATCH_THRESHOLD'));
  });

  test('rejects invalid liveness threshold', () {
    const config = LuxandVerificationConfig(
      matchThreshold: 0.85,
      livenessThreshold: 1.5,
    );

    expect(config.validationError, contains('LUXAND_LIVENESS_THRESHOLD'));
  });
}
