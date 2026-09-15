import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/identity_document_recognition_service.dart';
import '../domain/identity_capture_result.dart';
import 'camera_preview_geometry.dart';

enum _CaptureSide { front, back }

class IdentityCaptureScreen extends StatefulWidget {
  const IdentityCaptureScreen({super.key, this.recognitionService});

  final IdentityDocumentRecognitionService? recognitionService;

  @override
  State<IdentityCaptureScreen> createState() => _IdentityCaptureScreenState();
}

class _IdentityCaptureScreenState extends State<IdentityCaptureScreen>
    with WidgetsBindingObserver {
  late final IdentityDocumentRecognitionService _recognitionService;
  CameraController? _cameraController;
  _CaptureSide _side = _CaptureSide.front;
  Uint8List? _frontImageBytes;
  String? _errorMessage;
  String? _statusMessage;
  String? _pendingMrzSignature;
  Timer? _mrzAutoScanTimer;
  bool _initializing = false;
  bool _processing = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recognitionService =
        widget.recognitionService ?? MlKitIdentityDocumentRecognitionService();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopMrzAutoScan();
      _pendingMrzSignature = null;
      final controller = _cameraController;
      _cameraController = null;
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed && !_disposed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializing || _cameraController != null || _disposed) return;
    _initializing = true;
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    CameraController? pendingController;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('camera_missing', 'No camera available');
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      pendingController = CameraController(
        camera,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      await pendingController.initialize();
      if (_disposed || !mounted) {
        await pendingController.dispose();
        return;
      }
      setState(() {
        _cameraController = pendingController;
      });
      if (_side == _CaptureSide.back) _startMrzAutoScan();
    } on CameraException {
      await pendingController?.dispose();
      if (!_disposed && mounted) {
        setState(() {
          _errorMessage =
              'Không thể mở camera. Hãy cấp quyền camera rồi thử lại.';
        });
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _capture({bool automatic = false}) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _processing) {
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
      if (!automatic) _statusMessage = null;
    });

    XFile? photo;
    try {
      photo = await controller.takePicture();
      if (_side == _CaptureSide.front) {
        await _processFront(photo.path);
      } else {
        await _processBack(photo.path, requireStableResult: automatic);
      }
    } on CameraException {
      _showError(
        automatic
            ? 'Camera chưa chụp được. App sẽ tự thử lại.'
            : 'Không thể chụp ảnh. Vui lòng thử lại.',
      );
    } catch (_) {
      _showError(
        automatic
            ? 'Chưa nhận diện được giấy tờ. Giữ thẻ trong khung để app thử lại.'
            : 'Không thể nhận diện giấy tờ. Vui lòng chụp lại ảnh rõ hơn.',
      );
    } finally {
      if (photo != null) await _deleteFile(photo.path);
      if (!_disposed && mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _processFront(String path) async {
    final bytes = await File(path).readAsBytes();
    if (_disposed || !mounted) return;
    setState(() {
      _frontImageBytes = bytes;
      _side = _CaptureSide.back;
      _errorMessage = null;
      _statusMessage = null;
      _pendingMrzSignature = null;
    });
    _startMrzAutoScan();
  }

  Future<void> _processBack(
    String path, {
    required bool requireStableResult,
  }) async {
    final mrz = await _recognitionService.recognizeBackMrz(path);
    if (mrz == null) {
      _pendingMrzSignature = null;
      _showError(
        'Chưa đọc rõ MRZ. Giữ ba dòng MRZ trong khung, app sẽ tự thử lại.',
      );
      return;
    }

    final signature = [
      mrz.accessData.documentNumber,
      mrz.accessData.dateOfBirth.toIso8601String(),
      mrz.accessData.dateOfExpiry.toIso8601String(),
      mrz.identityNumber,
    ].join('|');
    if (requireStableResult && _pendingMrzSignature != signature) {
      _pendingMrzSignature = signature;
      _showStatus('Đã thấy MRZ. Giữ yên thêm một nhịp để xác nhận ảnh.');
      return;
    }

    final backBytes = await File(path).readAsBytes();
    final frontBytes = _frontImageBytes;
    if (_disposed || !mounted || frontBytes == null) return;
    _stopMrzAutoScan();
    Navigator.of(context).pop(
      IdentityCaptureResult(
        frontImageBytes: frontBytes,
        backImageBytes: backBytes,
        identityNumber: mrz.identityNumber,
        accessData: mrz.accessData,
      ),
    );
  }

  void _showError(String message) {
    if (_disposed || !mounted) return;
    setState(() {
      _errorMessage = message;
      _statusMessage = null;
    });
  }

  void _showStatus(String message) {
    if (_disposed || !mounted) return;
    setState(() {
      _errorMessage = null;
      _statusMessage = message;
    });
  }

  Future<void> _restartFromFront() async {
    _stopMrzAutoScan();
    setState(() {
      _side = _CaptureSide.front;
      _frontImageBytes = null;
      _errorMessage = null;
      _statusMessage = null;
      _pendingMrzSignature = null;
    });
  }

  void _startMrzAutoScan() {
    _stopMrzAutoScan();
    if (_disposed || _side != _CaptureSide.back) return;

    _mrzAutoScanTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final controller = _cameraController;
      if (_disposed ||
          _side != _CaptureSide.back ||
          _processing ||
          controller == null ||
          !controller.value.isInitialized ||
          controller.value.isTakingPicture) {
        return;
      }
      unawaited(_capture(automatic: true));
    });
  }

  void _stopMrzAutoScan() {
    _mrzAutoScanTimer?.cancel();
    _mrzAutoScanTimer = null;
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The camera plugin may already have removed its temporary file.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopMrzAutoScan();
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _recognitionService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _side == _CaptureSide.front
              ? '1/2 · Chụp mặt trước'
              : '2/2 · Chụp MRZ mặt sau',
        ),
        actions: [
          if (_side == _CaptureSide.back)
            TextButton(
              onPressed: _processing ? null : _restartFromFront,
              child: const Text('Chụp lại từ đầu'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: controller == null || !controller.value.isInitialized
                  ? _CameraPlaceholder(
                      errorMessage: _errorMessage,
                      onRetry: _initializeCamera,
                    )
                  : _CameraView(controller: controller, side: _side),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              color: const Color(0xFF111111),
              child: Column(
                children: [
                  Text(
                    _side == _CaptureSide.front
                        ? 'Căn toàn bộ mặt trước CCCD, đủ bốn góc và không bị lóa.'
                        : 'Đặt ba dòng MRZ vào khung vàng. App tự quét mỗi 3 giây.',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage case final message?) ...[
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(color: Color(0xFFFF8A80)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_statusMessage case final message?) ...[
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(color: Color(0xFF80CBC4)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('capture-document-button'),
                    onPressed: controller == null || _processing
                        ? null
                        : _capture,
                    icon: _processing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _processing
                          ? 'Đang nhận diện...'
                          : _side == _CaptureSide.back
                          ? 'Quét ngay'
                          : 'Chụp ảnh',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.controller, required this.side});

  final CameraController controller;
  final _CaptureSide side;

  @override
  Widget build(BuildContext context) {
    final sensorPreviewSize = controller.value.previewSize;
    final previewSize = sensorPreviewSize == null
        ? null
        : orientedCameraPreviewSize(
            sensorPreviewSize,
            MediaQuery.orientationOf(context),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (previewSize == null)
              CameraPreview(controller)
            else
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize.width,
                    height: previewSize.height,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            Container(color: Colors.black.withValues(alpha: 0.18)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AspectRatio(
                  aspectRatio: 85.6 / 54,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF4DD0C8),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: side == _CaptureSide.back
                        ? const Alignment(0, 0.72)
                        : Alignment.center,
                    child: side == _CaptureSide.back
                        ? Container(
                            height: 72,
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.yellowAccent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.errorMessage, required this.onRetry});

  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Đang mở camera...',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
