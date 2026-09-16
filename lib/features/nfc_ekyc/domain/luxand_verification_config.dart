class LuxandVerificationConfig {
  const LuxandVerificationConfig({
    required this.matchThreshold,
    required this.livenessThreshold,
    this.cameraExposureOffset = 0.60,
  });

  factory LuxandVerificationConfig.fromEnvironment() {
    const matchRaw = String.fromEnvironment(
      'LUXAND_MATCH_THRESHOLD',
      defaultValue: '0.85',
    );
    const livenessRaw = String.fromEnvironment(
      'LUXAND_LIVENESS_THRESHOLD',
      defaultValue: '0.85',
    );
    const exposureOffsetRaw = String.fromEnvironment(
      'LUXAND_CAMERA_EXPOSURE_OFFSET',
      defaultValue: '0.60',
    );

    return LuxandVerificationConfig(
      matchThreshold: double.tryParse(matchRaw.trim()) ?? double.nan,
      livenessThreshold: double.tryParse(livenessRaw.trim()) ?? double.nan,
      cameraExposureOffset: double.tryParse(exposureOffsetRaw.trim()) ?? 0.60,
    );
  }

  final double matchThreshold;
  final double livenessThreshold;
  final double cameraExposureOffset;

  String? get validationError {
    if (!_isRatio(matchThreshold)) {
      return 'LUXAND_MATCH_THRESHOLD phải lớn hơn 0 và không vượt quá 1.';
    }
    if (!_isRatio(livenessThreshold)) {
      return 'LUXAND_LIVENESS_THRESHOLD phải lớn hơn 0 và không vượt quá 1.';
    }
    return null;
  }

  static bool _isRatio(double value) =>
      value.isFinite && value > 0 && value <= 1;

  static String percent(double value) =>
      '${(value * 100).toStringAsFixed(value * 100 % 1 == 0 ? 0 : 1)}%';
}
