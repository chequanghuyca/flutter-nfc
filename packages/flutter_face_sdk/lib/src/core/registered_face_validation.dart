import 'dart:io';
import 'flutter_face_sdk.dart' as fsdk;

/// SDK must be initialized by the caller. Only reference-specific errors are
/// false; runtime/license failures propagate and must not force registration.
bool isUsableLuxandRegisteredFace(String path) {
  fsdk.Image? image;
  fsdk.FacePositions? positions;
  fsdk.FaceTemplate? template;
  try {
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) return false;
    image = fsdk.LoadImageFromFile(path);
    positions = image.detectMultipleFaces();
    if (positions.length != 1) return false;
    template = fsdk.GetFaceTemplateInRegion(image, positions.first);
    return true;
  } on fsdk.Error catch (error) {
    if (const [
      fsdk.Error.FaceNotFound,
      fsdk.Error.ImageTooSmall,
      fsdk.Error.BadFileFormat,
      fsdk.Error.CannotOpenFile,
      fsdk.Error.FileNotFound,
      fsdk.Error.UnsupportedImageExtension,
    ].contains(error.code)) return false;
    rethrow;
  } on FileSystemException {
    return false;
  } finally {
    template?.free();
    positions?.free();
    image?.free();
  }
}
