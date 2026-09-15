import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/presentation/camera_preview_geometry.dart';

void main() {
  test('swaps sensor dimensions for a portrait camera preview', () {
    const sensorSize = Size(1280, 720);

    expect(
      orientedCameraPreviewSize(sensorSize, Orientation.portrait),
      const Size(720, 1280),
    );
  });

  test('keeps sensor dimensions for a landscape camera preview', () {
    const sensorSize = Size(1280, 720);

    expect(
      orientedCameraPreviewSize(sensorSize, Orientation.landscape),
      sensorSize,
    );
  });
}
