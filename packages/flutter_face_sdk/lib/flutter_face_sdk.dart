library flutter_face_sdk;

import 'dart:ffi';
import 'dart:io';

import 'package:screen_brightness/screen_brightness.dart';

import 'src/core/flutter_face_sdk.dart' as face_sdk;
import 'src/core/utils.dart';
import 'src/data/key.dart';

export 'src/presentation/faceid_view.dart';
export 'src/models/helptext_model.dart';
export 'src/models/faceid_model.dart';
export 'src/data/dbhelper.dart';
export 'src/data/key.dart';
export 'src/core/flutter_face_sdk.dart';
export 'src/core/utils.dart';
export 'src/core/converter.dart';
export 'src/core/face_tracker.dart';
export 'src/core/face_verification_policy.dart';
export 'src/core/face_motion_challenge.dart';
export 'src/core/registered_face_validation.dart';

bool? _isFaceSdkAvailable;

Future<void> setFaceScreenBrightnessToMaximum() async {
  final screenBrightness = ScreenBrightness();
  await screenBrightness.setScreenBrightness(1);
  await Future<void>.delayed(const Duration(milliseconds: 100));
  final currentBrightness = await screenBrightness.current;
  if (currentBrightness < 1) {
    await screenBrightness.setScreenBrightness(1);
  }
}

Future<void> resetFaceScreenBrightness() =>
    ScreenBrightness().resetScreenBrightness();

bool isFaceSdkAvailable({bool refresh = false}) {
  if (!refresh && _isFaceSdkAvailable != null) {
    return _isFaceSdkAvailable!;
  }

  try {
    if (!canUseLuxand83ForCurrentPlatform(
      isAndroid: Platform.isAndroid,
      isIOS: Platform.isIOS,
    )) {
      return _isFaceSdkAvailable = false;
    }
    final faceSdk =
        getDynamicLibrary('facesdk', libShortName: 'fsdk', iOSStatic: true);
    faceSdk.lookup<NativeFunction<Int32 Function()>>('FSDK_Initialize');

    if (Platform.isAndroid || Platform.isLinux) {
      final bridge = getDynamicLibrary('flutter_face_sdk');
      bridge.lookup<NativeFunction<Void Function()>>('YUV420ToRGB');
    }

    // Loading the native symbols is not enough: an incompatible Luxand key
    // leaves FaceIDView on an unusable blank screen. Verify Android activation
    // before allowing callers to enter the native attendance flow.
    if (Platform.isAndroid) {
      face_sdk.ActivateLibrary(lienceKey);
    }

    return _isFaceSdkAvailable = true;
  } catch (_) {
    return _isFaceSdkAvailable = false;
  }
}
