import 'package:flutter/widgets.dart';

Size orientedCameraPreviewSize(
  Size sensorPreviewSize,
  Orientation orientation,
) {
  if (orientation == Orientation.landscape) return sensorPreviewSize;
  return Size(sensorPreviewSize.height, sensorPreviewSize.width);
}
