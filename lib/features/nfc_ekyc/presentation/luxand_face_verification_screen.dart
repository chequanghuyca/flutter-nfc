import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_face_sdk/flutter_face_sdk.dart' as face_sdk;
import 'package:path_provider/path_provider.dart';

import '../data/nfc_portrait_decoder.dart';
import '../domain/face_verification_result.dart';
import '../domain/luxand_verification_config.dart';

class LuxandFaceVerificationScreen extends StatefulWidget {
  const LuxandFaceVerificationScreen({
    super.key,
    required this.nfcPortraitBytes,
    this.config,
    this.portraitDecoder = const NfcPortraitDecoder(),
  });

  final Uint8List nfcPortraitBytes;
  final LuxandVerificationConfig? config;
  final NfcPortraitDecoder portraitDecoder;

  @override
  State<LuxandFaceVerificationScreen> createState() =>
      _LuxandFaceVerificationScreenState();
}

class _LuxandFaceVerificationScreenState
    extends State<LuxandFaceVerificationScreen> {
  late final LuxandVerificationConfig _config;
  late final face_sdk.FaceMotionChallenge _motionChallenge;
  face_sdk.FaceIDModel? _model;
  FaceVerificationResult? _successResult;
  Directory? _temporaryDirectory;
  File? _referenceFile;
  File? _sourceFile;
  Future<void> _sdkDisposal = Future<void>.value();
  String? _errorMessage;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? LuxandVerificationConfig.fromEnvironment();
    _motionChallenge = face_sdk.FaceMotionChallenge();
    unawaited(_prepareReference());
  }

  Future<void> _prepareReference() async {
    File? pendingReference;
    File? pendingSource;
    try {
      if (_config.validationError case final error?) {
        throw StateError(error);
      }
      if (!face_sdk.canUseLuxand83ForCurrentPlatform(
        isAndroid: Platform.isAndroid,
        isIOS: Platform.isIOS,
      )) {
        throw StateError(
          'Luxand 8.3 chưa được bật bằng file env cho nền tảng này.',
        );
      }

      final pngBytes = await widget.portraitDecoder.decodeToPng(
        widget.nfcPortraitBytes,
      );
      if (pngBytes == null || pngBytes.isEmpty) {
        throw StateError('Không giải mã được ảnh chân dung DG2 từ chip.');
      }

      final temporaryDirectory = await getTemporaryDirectory();
      final reference = File('${temporaryDirectory.path}/server_face.jpg');
      final source = File('${temporaryDirectory.path}/server_face.source');
      pendingReference = File('${reference.path}.nfc-pending');
      pendingSource = File('${source.path}.nfc-pending');
      final sourceToken =
          'nfc-dg2-${DateTime.now().microsecondsSinceEpoch.toString()}';

      await pendingReference.writeAsBytes(pngBytes, flush: true);
      await pendingSource.writeAsString(sourceToken, flush: true);
      await _delete(reference);
      await _delete(source);
      await pendingReference.rename(reference.path);
      await pendingSource.rename(source.path);
      pendingReference = null;
      pendingSource = null;

      if (!mounted) {
        await _delete(reference);
        await _delete(source);
        return;
      }

      setState(() {
        _temporaryDirectory = temporaryDirectory;
        _referenceFile = reference;
        _sourceFile = source;
        _model = face_sdk.FaceIDModel(
          imageTrainPath: sourceToken,
          deviceName: Platform.operatingSystem,
          distanceFaceID: 1,
          timeoutSecond: -1,
          livenessFaceID: _config.livenessThreshold,
          useConfiguredLivenessThreshold: true,
          matchFaceID: _config.matchThreshold,
          cameraExposureOffset: _config.cameraExposureOffset,
          differentCountFaceID: _motionChallenge.totalStepCount,
          countAllowSave: _motionChallenge.totalStepCount,
          motionChallenge: _motionChallenge,
          showStatusOverlay: false,
          successCallback: _handleVerifiedCapture,
          helpText: face_sdk.HelpText(
            moveFaceOut: 'Đưa điện thoại ra xa hơn',
            moveFaceIn: 'Đưa điện thoại lại gần hơn',
            moveFaceCenter: 'Đặt khuôn mặt vào giữa khung hình',
            detecting: 'Giữ yên, đang kiểm tra khuôn mặt',
            faceInvalid: 'Chưa xác minh được người thật. Hãy thử lại.',
            faceNotMatch: 'Khuôn mặt không khớp ảnh trên chip CCCD.',
            initial: 'Đặt khuôn mặt vào giữa khung hình',
            multiFace: 'Chỉ để một khuôn mặt trong khung',
            verifying: 'Đang so khớp với ảnh trên chip...',
            retryTitle: 'Chưa xác minh được',
            retryAction: 'Thử lại',
            closeAction: 'Đóng',
          ),
        );
      });
    } catch (error) {
      await _delete(pendingReference);
      await _delete(pendingSource);
      if (mounted) {
        setState(() {
          _errorMessage = error is StateError
              ? error.message.toString()
              : 'Không thể chuẩn bị Luxand FaceSDK 8.3.';
        });
      }
    }
  }

  Future<void> _handleVerifiedCapture(
    String similarityValue,
    File capture,
    face_sdk.FaceIDModel verifiedModel,
  ) async {
    if (_didComplete || !verifiedModel.hasValidVerification) return;
    final similarity = double.tryParse(similarityValue);
    final liveness = verifiedModel.verifiedLiveness;
    if (similarity == null ||
        similarity < _config.matchThreshold ||
        liveness == null ||
        liveness < _config.livenessThreshold) {
      return;
    }

    try {
      final captureBytes = await capture.readAsBytes();
      if (!mounted || captureBytes.isEmpty) return;
      _didComplete = true;
      setState(() {
        _successResult = FaceVerificationResult(
          similarity: similarity,
          threshold: _config.matchThreshold,
          liveness: liveness,
          livenessThreshold: _config.livenessThreshold,
          captureBytes: captureBytes,
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Đã so khớp nhưng không đọc được ảnh xác minh.';
        });
      }
    }
  }

  Future<void> _delete(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup must not replace the verification result.
    }
  }

  Future<void> _cleanup() async {
    await _delete(_referenceFile);
    await _delete(_sourceFile);
    final directory = _temporaryDirectory;
    if (directory == null || !await directory.exists()) return;
    try {
      await for (final entity in directory.list()) {
        if (entity is File &&
            entity.path
                .split(Platform.pathSeparator)
                .last
                .startsWith('face_sample_')) {
          await _delete(entity);
        }
      }
    } catch (_) {
      // Best-effort cleanup of Luxand's temporary samples.
    }
  }

  @override
  void dispose() {
    unawaited(
      Future<void>.delayed(Duration.zero)
          .then((_) => _sdkDisposal)
          .then((_) => _cleanup(), onError: (_) => _cleanup())
          .whenComplete(_motionChallenge.dispose),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    final successResult = _successResult;
    final Widget content;
    if (_errorMessage case final error?) {
      content = _ErrorView(message: error);
    } else if (successResult != null) {
      content = _SuccessView(
        result: successResult,
        onDone: () => Navigator.of(context).pop(successResult),
      );
    } else if (model == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = face_sdk.FaceIDView(
        model: model,
        embedded: true,
        onClose: () => Navigator.maybePop(context),
        onDisposing: (future) => _sdkDisposal = future,
        onInitializationFailure: (reason) {
          if (mounted) setState(() => _errorMessage = reason);
        },
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_errorMessage == null && _successResult == null)
              FaceScanGuidance(challenge: _motionChallenge),
            Expanded(child: content),
            if (_errorMessage == null && _successResult == null)
              const FaceScanInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Quay lại',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF121B2E),
                  size: 32,
                ),
              ),
              const Expanded(
                child: Text(
                  'Xác thực khuôn mặt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _motionChallenge,
            builder: (context, _) => SizedBox(
              width: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  key: const Key('face-verification-progress'),
                  minHeight: 5,
                  value: _motionChallenge.progress,
                  backgroundColor: const Color(0xFFE1E5EA),
                  color: const Color(0xFF007AA8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceScanGuidance extends StatelessWidget {
  const FaceScanGuidance({super.key, required this.challenge});

  final face_sdk.FaceMotionChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: challenge,
      builder: (context, _) => Semantics(
        liveRegion: true,
        child: SizedBox(
          height: 128,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  key: const Key('face-guidance-banner'),
                  duration: const Duration(milliseconds: 220),
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: 58,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: challenge.isComplete
                        ? const Color(0xFF008A78)
                        : const Color(0xFF006A9D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4CA2C3),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26003B5C),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    challenge.displayInstruction,
                    key: const Key('face-scan-guidance-text'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    challenge.isCloserStep
                        ? 'Bước 2/2  ·  Đưa điện thoại lại gần'
                        : challenge.isComplete
                        ? 'Đã hoàn tất xác thực khuôn mặt'
                        : 'Bước 1/2  ·  Căn chỉnh khuôn mặt',
                    key: ValueKey(challenge.step),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaceScanInstructions extends StatelessWidget {
  const FaceScanInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1.5,
        shadowColor: const Color(0x1A0F4C66),
        child: InkWell(
          key: const Key('face-verification-help'),
          onTap: () => _showFaceVerificationHelp(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hướng dẫn',
                  style: TextStyle(
                    color: Color(0xFF087FC3),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.help_rounded, color: Color(0xFF6A9CF4), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showFaceVerificationHelp(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hướng dẫn xác thực',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            _HelpItem(
              number: '1',
              text: 'Giữ điện thoại ngang tầm mắt và nhìn thẳng vào camera.',
            ),
            SizedBox(height: 12),
            _HelpItem(
              number: '2',
              text: 'Đặt khuôn mặt vào giữa khung và làm theo hướng dẫn.',
            ),
            SizedBox(height: 12),
            _HelpItem(
              number: '3',
              text: 'Đảm bảo khuôn mặt đủ sáng, không bị che khuất.',
            ),
          ],
        ),
      ),
    ),
  );
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFE8F4FA),
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Color(0xFF007AA8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result, required this.onDone});

  final FaceVerificationResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFF63D6AD), width: 6),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(result.captureBytes, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF1789E8)),
              SizedBox(width: 8),
              Text(
                'Thành công',
                style: TextStyle(
                  color: Color(0xFF1789E8),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Match ${LuxandVerificationConfig.percent(result.similarity)} '
            '• Liveness ${LuxandVerificationConfig.percent(result.liveness)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF526071),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF168A65),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.face_retouching_off_rounded,
              color: Color(0xFFE6405B),
              size: 58,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF334155), fontSize: 16),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}
