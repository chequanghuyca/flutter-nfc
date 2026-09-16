import 'dart:async';

class RegisteredFaceUnavailable implements Exception {
  const RegisteredFaceUnavailable();
}

class RegisteredFaceSelectionCancelled implements Exception {
  const RegisteredFaceSelectionCancelled();
}

/// Only reference-specific validation failures should return false. SDK/license
/// errors must propagate to the caller's SDK fallback, not trigger registration.
Future<String> selectRegisteredFace({
  required Map<String, String> files,
  required FutureOr<bool> Function(String file) validate,
  Future<Map<String, String>> Function()? refresh,
  bool Function()? shouldContinue,
}) async {
  void checkActive() {
    if (shouldContinue != null && !shouldContinue()) {
      throw const RegisteredFaceSelectionCancelled();
    }
  }

  for (final file in files.values) {
    checkActive();
    final valid = await validate(file);
    checkActive();
    if (valid) return file;
  }
  if (refresh != null) {
    checkActive();
    final fresh = await refresh();
    for (final file in fresh.values) {
      checkActive();
      final valid = await validate(file);
      checkActive();
      if (valid) return file;
    }
  }
  checkActive();
  throw const RegisteredFaceUnavailable();
}
