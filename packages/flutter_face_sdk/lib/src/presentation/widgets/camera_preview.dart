import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

@visibleForTesting
double portraitPreviewAspectRatio(Size previewSize) {
  if (!previewSize.width.isFinite ||
      !previewSize.height.isFinite ||
      previewSize.width <= 0 ||
      previewSize.height <= 0) return 3 / 4;
  final ratio = previewSize.height / previewSize.width;
  return ratio.isFinite && ratio > 0 ? ratio : 3 / 4;
}

class CameraView extends StatelessWidget {
  final CameraController? controller;

  const CameraView({
    super.key,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    if (camera == null || !camera.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final previewSize = camera.value.previewSize;
    if (previewSize == null ||
        !previewSize.width.isFinite ||
        !previewSize.height.isFinite ||
        previewSize.width <= 0 ||
        previewSize.height <= 0) {
      return const SizedBox.shrink();
    }

    // The YUV frame is normalized to portrait before Luxand receives it.
    // Display that same full portrait frame instead of using BoxFit.cover.
    // Cover cropped both sides and visually enlarged the face, so users moved
    // the phone farther away even though Luxand was processing a much smaller
    // face from the uncropped frame.
    final portraitAspectRatio = portraitPreviewAspectRatio(previewSize);
    return Center(
      child: AspectRatio(
        aspectRatio: portraitAspectRatio,
        child: CameraPreview(camera),
      ),
    );
  }
}
