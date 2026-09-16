import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_sdk/src/core/flutter_face_sdk.dart' as fsdk;
import 'package:flutter_face_sdk/src/data/key.dart';
import 'package:flutter_face_sdk/src/presentation/widgets/appbar_widget.dart';
import 'package:flutter_face_sdk/src/presentation/widgets/camera_preview.dart';
import 'package:screen_brightness/screen_brightness.dart';
// import 'package:flutter_face_sdk/src/presentation/widgets/shape_painter.dart';

import '../core/face_painter.dart';
import '../core/face_motion_challenge.dart';
import 'widgets/face_fill_light.dart';
import '../core/face_tracker.dart';
import '../core/face_verification_policy.dart';
import '../core/registered_face_selection.dart';
import '../core/registered_face_validation.dart';
import '../data/dbhelper.dart';
import '../models/faceid_model.dart';

class FaceIDView extends StatefulWidget {
  final FaceIDModel model;
  final bool embedded;
  final VoidCallback? onClose;
  final ValueChanged<String>? onInitializationFailure;
  final VoidCallback? onReferenceUnavailable;

  /// Hosts can await teardown before opening another camera, including cancel.
  final ValueChanged<Future<void>>? onDisposing;

  const FaceIDView({
    super.key,
    required this.model,
    this.embedded = false,
    this.onClose,
    this.onInitializationFailure,
    this.onReferenceUnavailable,
    this.onDisposing,
  });

  @override
  State<FaceIDView> createState() => _FaceIDViewState();
}

class _FaceIDViewState extends State<FaceIDView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  FacesTracker? tracker;

  FacesPainter? _painter;
  CameraController? cameraController;

  FaceIDDBHelper dbHelper = FaceIDDBHelper();

  Animation<double>? animation;
  Animation<double>? animation2;
  AnimationController? animationController;

  bool isTrackerReady = false;
  bool isCameraReady = false;
  bool _isInitializing = false;
  bool _acceptCameraFrames = false;
  bool _appIsActive = true;
  int _cameraLifecycleGeneration = 0;
  String? _initializationError;
  bool _didReportInitializationFailure = false;
  Future<void> _cameraLifecycle = Future<void>.value();
  final ScreenBrightness _screenBrightness = ScreenBrightness.instance;
  Future<void> _screenBrightnessOperation = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.model.resetVerification();

    unawaited(_startFaceId());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appIsActive = false;
    _acceptCameraFrames = false;
    final trackerToDispose = tracker;
    tracker = null;
    final cleanup = Future.wait([
      _disposeFaceIdResources(trackerToDispose),
      resetBrightness(),
    ]).then<void>((_) {}).catchError((Object error) {
      debugPrint('FaceID resource cleanup failed: ${error.runtimeType}');
    });
    widget.onDisposing?.call(cleanup);
    unawaited(cleanup);
    animationController?.dispose();
    super.dispose();
  }

  Future<void> _disposeFaceIdResources(
    FacesTracker? trackerToDispose,
  ) async {
    await closeCamera();
    trackerToDispose?.dispose();
    await dbHelper.closeDB();
  }

  Future<void> _startFaceId() async {
    await setBrightness(1);
    if (!mounted) {
      return;
    }
    await callActiveSDK();
  }

  Future<void> setBrightness(double brightness) {
    _screenBrightnessOperation = _screenBrightnessOperation.then((_) async {
      if (!mounted || !_appIsActive) return;
      try {
        await _screenBrightness.setApplicationScreenBrightness(brightness);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted || !_appIsActive) return;
        final currentBrightness = await _screenBrightness.application;
        if (mounted && _appIsActive && currentBrightness < brightness) {
          await _screenBrightness.setApplicationScreenBrightness(brightness);
        }
        debugPrint('FaceID screen brightness: $currentBrightness');
      } catch (e) {
        debugPrint('Failed to set brightness: $e');
      }
    });
    return _screenBrightnessOperation;
  }

  Future<void> resetBrightness() {
    // A delayed enable/retry must finish before pause/dispose restores brightness.
    _screenBrightnessOperation = _screenBrightnessOperation.then((_) async {
      try {
        await _screenBrightness.resetApplicationScreenBrightness();
      } catch (e) {
        debugPrint('Failed to reset brightness: $e');
      }
    });
    return _screenBrightnessOperation;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appIsActive = true;
      unawaited(setBrightness(1));
      unawaited(_resumeFaceIdCameraAfterLifecycle());
      return;
    }
    _appIsActive = false;
    _acceptCameraFrames = false;
    unawaited(resetBrightness());
    unawaited(closeCamera());
  }

  Future<void> _resumeFaceIdCameraAfterLifecycle() async {
    try {
      await _cameraLifecycle;
      await _ensureFaceIdCamera();
    } catch (error) {
      debugPrint('Failed to resume FaceID camera: $error');
    }
  }

  Future<void> _ensureFaceIdCamera() async {
    if (!mounted ||
        !_appIsActive ||
        _isInitializing ||
        _initializationError != null ||
        tracker == null ||
        cameraController != null) {
      return;
    }
    await openCamera();
  }

  Future<void> _setup() async {
    if (!mounted) {
      return;
    }
    _painter = null;
    tracker = FacesTracker(
      // The medium camera stream is typically 720 px wide. Upscaling it to
      // 1024 adds latency without adding facial detail; 640 keeps landmarks
      // responsive while the final full-resolution samples remain unchanged.
      internalResizeWidth: widget.embedded ? 640 : 256,
      faceDetectionThreshold: widget.embedded ? 3 : 5,
      trimOutOfScreenFaces: !widget.embedded,
      persistTracker: !widget.embedded,
    );
    if (!isTrackerReady) {
      tracker?.addListener(trackerListener);
    }
    await dbHelper.openDB(enableLogging: widget.model.logCallback != null);
    if (!mounted) {
      return;
    }
    await _validateRegisteredFace();
    if (!mounted) return;
    await openCamera();
  }

  Future<void> _validateRegisteredFace() async {
    final files = widget.model.registeredFaceFiles;
    if (files != null) {
      widget.model.selectedRegisteredFacePath = null;
      final selected = await selectRegisteredFace(
        files: files,
        validate: (file) => mounted && _isUsableRegisteredFace(file),
        refresh: widget.model.refreshRegisteredFaces,
        shouldContinue: () => mounted,
      );
      if (mounted) widget.model.selectedRegisteredFacePath = selected;
      return;
    }
    // Legacy NFC callers keep their own source-token validation.
    final expectedSource =
        widget.model.imageTrainPath?.trim().split(';').first.trim() ?? '';
    if (expectedSource.isEmpty) {
      throw StateError('Registered FaceID image is missing');
    }

    final registeredFace = File('${dbHelper.tempDir.path}/server_face.jpg');
    final registeredSource =
        File('${dbHelper.tempDir.path}/server_face.source');
    if (!registeredFace.existsSync() || registeredFace.lengthSync() == 0) {
      throw StateError('Registered FaceID cache is missing');
    }
    if (!registeredSource.existsSync() ||
        registeredSource.readAsStringSync().trim() != expectedSource) {
      throw StateError('Registered FaceID cache does not belong to this user');
    }

    fsdk.Image? image;
    fsdk.FacePositions? positions;
    fsdk.FaceTemplate? template;
    try {
      image = fsdk.LoadImageFromFile(registeredFace.path);
      positions = image.detectMultipleFaces();
      if (!hasExactlyOneFace(positions.length)) {
        throw StateError(
          'Registered FaceID image must contain exactly one face',
        );
      }
      template = fsdk.GetFaceTemplateInRegion(image, positions.first);
    } finally {
      template?.free();
      positions?.free();
      image?.free();
    }
  }

  bool _isUsableRegisteredFace(String path) =>
      isUsableLuxandRegisteredFace(path);

  Future<void> callActiveSDK() async {
    if (!mounted || _isInitializing) {
      return;
    }
    _isInitializing = true;
    if (mounted) {
      setState(() => _initializationError = null);
    }
    try {
      if (!canUseLuxand83ForCurrentPlatform(
        isAndroid: Platform.isAndroid,
        isIOS: Platform.isIOS,
      )) {
        throw StateError(
          'Luxand FaceSDK 8.3 runtime/license is not enabled for this platform',
        );
      }
      final licenseKey = Platform.isIOS ? keyIosStandard : lienceKey;
      fsdk.ActivateLibrary(licenseKey);
      fsdk.Initialize();
      fsdk.SetNumThreads(2);
      // Tracker and still-image detection have separate Luxand parameters.
      // Configure both so the final sample check cannot approve a frame whose
      // smaller/edge secondary face was missed by the live tracker.
      fsdk.SetFaceDetectionParameters(
        false,
        false,
        widget.embedded ? 1024 : 512,
      );
      fsdk.SetFaceDetectionThreshold(widget.embedded ? 3 : 5);
      fsdk.SetParameters({
        'TrimOutOfScreenFaces': !widget.embedded,
      });

      await _setup();
    } on RegisteredFaceSelectionCancelled {
      // The user closed this session while its reference was loading.
      return;
    } on RegisteredFaceUnavailable {
      if (mounted) {
        setState(() =>
            _initializationError = 'Ảnh khuôn mặt đăng ký chưa sẵn sàng.');
        if (widget.onReferenceUnavailable != null) {
          widget.onReferenceUnavailable!();
        } else {
          _showInitializationError('Không thể chuẩn bị ảnh khuôn mặt đăng ký.');
        }
      }
    } on fsdk.NotActivatedError catch (error) {
      debugPrint(
        'FaceSDK activation failed: code=${error.code}, callee=${error.callee}',
      );
      _showInitializationError(
        'Luxand FaceSDK chưa được kích hoạt. Vui lòng kiểm tra license FaceSDK 8.3.',
      );
    } on fsdk.Error catch (error, stackTrace) {
      debugPrint(
        'FaceSDK native error: code=${error.code}, callee=${error.callee}, info=${error.info}',
      );
      debugPrintStack(stackTrace: stackTrace);
      _showInitializationError(
        'Không thể khởi tạo FaceID. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
      );
    } on Error catch (error, stackTrace) {
      debugPrint('FaceSDK initialization error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showInitializationError(
        'Không thể khởi tạo FaceID. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
      );
    } catch (error, stackTrace) {
      debugPrint('FaceSDK initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showInitializationError(
        'Không thể chuẩn bị dữ liệu khuôn mặt. Vui lòng tải lại thông tin người dùng và thử lại.',
      );
    } finally {
      _isInitializing = false;
      if (mounted && _appIsActive) {
        unawaited(_ensureFaceIdCamera());
      }
    }
  }

  void _showInitializationError(String message) {
    if (!mounted) return;
    setState(() => _initializationError = message);
    if (!_didReportInitializationFailure &&
        widget.onInitializationFailure != null) {
      _didReportInitializationFailure = true;
      widget.onInitializationFailure!(message);
    }
  }

  void initAnimationOverlay() {
    callCaculateRadius();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    Tween<double> radiusTween = Tween(begin: 800, end: 430);
    Tween<double> radiusTween2 = Tween(begin: 550, end: 177);

    animation = radiusTween.animate(animationController!);

    animation2 = radiusTween2.animate(animationController!)
      ..addListener(() {
        setState(() {
          isTrackerReady = true;
        });
      });

    animationController!.forward();

    Future.delayed(const Duration(seconds: 2), () {
      tracker!.setReady();
    });
  }

  void callCaculateRadius() {
    int width = 0;
    int height = 0;

    final extra = Platform.isIOS ? 90 : 0;

    if ((cameraController!.description.sensorOrientation + extra) % 180 != 0) {
      width = tracker!.height;
      height = tracker!.width;
    } else {
      width = tracker!.width;
      height = tracker!.height;
    }

    final renderObject = context.findRenderObject();
    final viewport = renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size
        : MediaQuery.sizeOf(context);
    final wc = viewport.width / width;
    final hc = viewport.height / height;

    final scale = min(wc, hc);

    final offsetX = (viewport.width - width * scale) / 2;
    final offsetY = (viewport.height - height * scale) / 2;

    double radius = viewport.width * scale * widget.model.distanceFaceID / 6;

    widget.model.radius = radius;
    widget.model.offsetY = offsetY;
    widget.model.offsetX = offsetX;
    widget.model.scale = scale;
  }

  /* void timeoutCallback() {
    int count = 30 /* widget.model.timeoutSecond */;
    Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) async {
        if (count == 0) {
          timer.cancel();
          tracker.dispose();
          closeCamera();

          await dbHelper.saveDataToServer(
            callback: (desc) {},
            countAllowSave: -1,
          );

          if (context.mounted) {
            DialogCustom.showMessageDialogIOS(
              context,
              description: widget.model.timeoutTitle,
              onPress: () {
                Navigator.pop(context);
              },
            );
          }
        } else {
          count--;
        }
      },
    );
  } */

  void process(CameraImage image) {
    final currentTracker = tracker;
    final controller = cameraController;
    if (!_acceptCameraFrames ||
        currentTracker == null ||
        controller == null ||
        currentTracker.faces().isNotEmpty) {
      return;
    }

    currentTracker.process(
      image,
      controller.description.sensorOrientation,
      true, //CameraLensDirection.front
    );
  }

  void trackerListener() {
    if (tracker?.width != -1 && tracker?.height != -1) {
      tracker?.removeListener(trackerListener);
      initAnimationOverlay();
    }
  }

  Future<void> closeCamera() async {
    _acceptCameraFrames = false;
    _cameraLifecycleGeneration++;
    return _enqueueCameraLifecycle(() async {
      final controller = cameraController;
      cameraController = null;
      isCameraReady = false;
      await _disposeCameraController(controller);
    });
  }

  Future<void> _disposeCameraController(CameraController? controller) async {
    if (controller == null) {
      return;
    }
    try {
      if (controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } on CameraException catch (error) {
      debugPrint('Failed to stop FaceID camera stream: $error');
    }
    try {
      await controller.dispose();
    } on CameraException catch (error) {
      debugPrint('Failed to dispose FaceID camera: $error');
    }
  }

  Future<void> pauseCamera() async {
    _acceptCameraFrames = false;
    return _enqueueCameraLifecycle(() async {
      final controller = cameraController;
      if (controller == null || !controller.value.isInitialized) {
        return;
      }
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    });
  }

  Future<void> resumeCamera() async {
    return _enqueueCameraLifecycle(() async {
      final controller = cameraController;
      if (controller == null || !controller.value.isInitialized) {
        return;
      }
      if (!controller.value.isStreamingImages) {
        await controller.startImageStream(process);
      }
      _acceptCameraFrames = true;
    });
  }

  Future<void> _enqueueCameraLifecycle(
    Future<void> Function() operation,
  ) {
    final nextOperation = _cameraLifecycle.catchError((Object error) {
      debugPrint('Previous FaceID camera operation failed: $error');
    }).then((_) => operation());
    _cameraLifecycle = nextOperation;
    return nextOperation;
  }

  Future<void> openCamera() {
    final lifecycleGeneration = _cameraLifecycleGeneration;
    return _enqueueCameraLifecycle(() async {
      final previousController = cameraController;
      cameraController = null;
      isCameraReady = false;
      await _disposeCameraController(previousController);
      if (!mounted ||
          !_appIsActive ||
          lifecycleGeneration != _cameraLifecycleGeneration) {
        return;
      }

      final cameras = await availableCameras();
      if (!mounted ||
          !_appIsActive ||
          lifecycleGeneration != _cameraLifecycleGeneration) {
        return;
      }
      if (cameras.isEmpty) {
        throw StateError('No camera is available for FaceID');
      }
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        // Production used `high`, while `low` produces only 320x240 on several
        // Android devices and makes facial features unreliable. `medium` keeps
        // enough detail for Luxand without restoring the large-object GC load
        // observed with the production preset.
        ResolutionPreset.medium,
        enableAudio: false,
        // Give Luxand enough fresh frames for quick motion feedback while the
        // tracker gate still guarantees only one frame is processed at a time.
        fps: 20,
        // Android supplies three-plane YUV420, while camera_avfoundation uses
        // two-plane NV12 for YUV420 on iOS. Request BGRA on iOS so the existing
        // one-plane converter is used and never reads a missing third plane.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      cameraController = controller;
      try {
        await controller.initialize();
        if (!mounted ||
            !_appIsActive ||
            lifecycleGeneration != _cameraLifecycleGeneration ||
            !identical(cameraController, controller)) {
          if (identical(cameraController, controller)) {
            cameraController = null;
          }
          await _disposeCameraController(controller);
          return;
        }
        debugPrint(
          'FaceID camera preview: ${controller.value.previewSize}, '
          'sensor: ${frontCamera.sensorOrientation}',
        );
        await _configureCameraForFaceLighting(controller);
        if (!mounted ||
            !_appIsActive ||
            lifecycleGeneration != _cameraLifecycleGeneration ||
            !identical(cameraController, controller)) {
          if (identical(cameraController, controller)) {
            cameraController = null;
          }
          await _disposeCameraController(controller);
          return;
        }

        setState(() => isCameraReady = true);
        await setBrightness(1);
        await controller.startImageStream(process);
        if (!mounted ||
            !_appIsActive ||
            lifecycleGeneration != _cameraLifecycleGeneration ||
            !identical(cameraController, controller)) {
          if (identical(cameraController, controller)) {
            cameraController = null;
          }
          await _disposeCameraController(controller);
          return;
        }
        _acceptCameraFrames = true;
      } catch (_) {
        if (identical(cameraController, controller)) {
          cameraController = null;
        }
        isCameraReady = false;
        await _disposeCameraController(controller);
        rethrow;
      }
    });
  }

  Future<void> _configureCameraForFaceLighting(
    CameraController controller,
  ) async {
    final configuredOffset = widget.model.cameraExposureOffset ?? 0.60;
    await _tryCameraSetting('exposure offset', () async {
      final minOffset = await controller.getMinExposureOffset();
      final maxOffset = await controller.getMaxExposureOffset();
      final targetOffset = configuredOffset.clamp(minOffset, maxOffset);
      await controller.setExposureOffset(targetOffset);
      debugPrint(
        'FaceID exposure offset: $targetOffset (min=$minOffset, max=$maxOffset)',
      );
    });
    await _tryCameraSetting('exposure point', () async {
      await controller.setExposurePoint(const Offset(0.5, 0.5));
    });
    await _tryCameraSetting('focus point', () async {
      await controller.setFocusPoint(const Offset(0.5, 0.5));
    });
  }

  Future<void> _tryCameraSetting(
    String name,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on CameraException catch (error) {
      debugPrint('FaceID camera $name is unsupported: $error');
    } catch (error) {
      debugPrint('Failed to configure FaceID camera $name: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return _buildInitializationError();
    }

    final cameraContent = _buildCameraContent();
    if (widget.embedded) {
      return ClipRect(
        child: ColoredBox(
          color: const Color(0xFFF7F8FC),
          child: cameraContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appbarWidget(context),
      extendBodyBehindAppBar: true,
      body: cameraContent,
    );
  }

  Widget _buildCameraContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isCameraReady)
          CameraView(
            controller: cameraController,
          ),
        if (widget.embedded &&
            isCameraReady &&
            (!isTrackerReady || widget.model.motionChallenge == null))
          Positioned.fill(
            child: FaceFillLight(
              scale: widget.model.motionChallenge?.targetFrameScale ?? 1.0,
            ),
          ),
        if (!isTrackerReady && isCameraReady)
          Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(
                    widget.model.helpText.initial,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isTrackerReady)
          CustomPaint(
            painter: _painter ??= FacesPainter(
              context: context,
              model: widget.model,
              tracker: tracker!,
              sensorOrientation: cameraController != null
                  ? cameraController!.description.sensorOrientation
                  : -1,
              cameraResume: resumeCamera,
              cameraPause: pauseCamera,
              dbHelper: dbHelper,
              cameraClose: closeCamera,
              exitBtnTitle: widget.model.helpText.closeAction,
              tryAgainBtnTitle: widget.model.helpText.retryAction,
              managesNavigation: !widget.embedded,
              onExit: widget.onClose,
              compactEmbedded: widget.embedded,
              radius1: animation!.value,
              radius2: animation2!.value,
            ),
          ),
        if (widget.embedded &&
            isTrackerReady &&
            widget.model.motionChallenge != null)
          Positioned.fill(
            child: _MotionDirectionOverlay(
              challenge: widget.model.motionChallenge!,
            ),
          ),
      ],
    );
  }

  Widget _buildInitializationError() {
    final errorContent = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.face_retouching_off,
              color: Color(0XFFFC2E55),
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              _initializationError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0XFFFC2E55),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: callActiveSDK,
              child: Text(widget.model.helpText.retryAction),
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) return errorContent;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appbarWidget(context),
      body: SafeArea(child: errorContent),
    );
  }
}

class _MotionDirectionOverlay extends StatefulWidget {
  const _MotionDirectionOverlay({required this.challenge});

  final FaceMotionChallenge challenge;

  @override
  State<_MotionDirectionOverlay> createState() =>
      _MotionDirectionOverlayState();
}

class _MotionDirectionOverlayState extends State<_MotionDirectionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutCubic),
    );
    if (widget.challenge.isCloserStep || widget.challenge.isComplete) {
      _scaleController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_MotionDirectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.challenge.isCloserStep || widget.challenge.isComplete) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [widget.challenge, _ringController, _scaleAnimation]),
        builder: (context, _) {
          if (widget.challenge.isCloserStep || widget.challenge.isComplete) {
            if (!_scaleController.isAnimating && _scaleController.value < 1.0) {
              _scaleController.forward();
            }
          } else {
            if (!_scaleController.isAnimating && _scaleController.value > 0.0) {
              _scaleController.reverse();
            }
          }

          final scale = _scaleAnimation.value;
          return Stack(
            children: [
              Positioned.fill(
                child: FaceFillLight(scale: scale),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _FaceScanFramePainter(
                    challenge: widget.challenge,
                    animation: _ringController,
                    scale: scale,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FaceScanFramePainter extends CustomPainter {
  _FaceScanFramePainter({
    required this.challenge,
    required this.animation,
    required this.scale,
  }) : super(repaint: Listenable.merge([challenge, animation]));

  final FaceMotionChallenge challenge;
  final Animation<double> animation;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = embeddedFaceGuideRRect(size, scale: scale);
    final progress = challenge.progress.clamp(0.0, 1.0);
    final framePath = Path()..addRRect(guide);

    canvas.drawRRect(
      guide,
      Paint()
        ..color = const Color(0xFFD6E4EE)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke,
    );

    final metrics = framePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    if (progress > 0) {
      final progressPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(
        progressPath,
        Paint()
          ..color = challenge.isComplete
              ? const Color(0xFF008A78)
              : const Color(0xFF0083B6)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    if (!challenge.isComplete) {
      final sweepStart = animation.value * metric.length;
      final sweepEnd = (sweepStart + 48) % metric.length;
      final sweepPaint = Paint()
        ..color = const Color(0xFF60BEDA).withValues(alpha: 0.75)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (sweepStart < sweepEnd) {
        canvas.drawPath(metric.extractPath(sweepStart, sweepEnd), sweepPaint);
      } else {
        canvas.drawPath(
          metric.extractPath(sweepStart, metric.length),
          sweepPaint,
        );
        canvas.drawPath(metric.extractPath(0, sweepEnd), sweepPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_FaceScanFramePainter oldDelegate) =>
      oldDelegate.challenge != challenge ||
      oldDelegate.animation != animation ||
      oldDelegate.scale != scale;
}
