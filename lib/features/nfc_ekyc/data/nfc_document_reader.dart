import 'dart:io';

import 'package:dmrtd/dmrtd.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

import '../domain/document_access_data.dart';
import '../domain/document_profile.dart';
import '../domain/document_read_result.dart';

enum NfcAvailability { unknown, available, disabled, unsupported }

enum NfcReadFailureType {
  unavailable,
  cancelled,
  timeout,
  tagLost,
  accessDenied,
  communication,
  invalidDocument,
  unknown,
}

class NfcReadFailure implements Exception {
  const NfcReadFailure(this.type, this.message);

  final NfcReadFailureType type;
  final String message;

  @override
  String toString() => message;
}

typedef NfcProgressCallback = void Function(String message, double progress);

abstract interface class NfcDocumentReader {
  Future<NfcAvailability> checkAvailability();

  Future<DocumentReadResult> read({
    required DocumentProfile profile,
    required DocumentAccessData accessData,
    required NfcProgressCallback onProgress,
  });

  Future<void> cancel();
}

class MrtdNfcDocumentReader implements NfcDocumentReader {
  static const tagPollingTimeout = Duration(seconds: 60);

  NfcProvider? _activeProvider;
  bool _cancelRequested = false;

  @override
  Future<NfcAvailability> checkAvailability() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return NfcAvailability.unsupported;
    }

    try {
      final status = await NfcProvider.nfcStatus;
      return switch (status) {
        NfcStatus.enabled => NfcAvailability.available,
        NfcStatus.disabled => NfcAvailability.disabled,
        NfcStatus.notSupported => NfcAvailability.unsupported,
      };
    } catch (_) {
      return NfcAvailability.unsupported;
    }
  }

  @override
  Future<DocumentReadResult> read({
    required DocumentProfile profile,
    required DocumentAccessData accessData,
    required NfcProgressCallback onProgress,
  }) async {
    final availability = await checkAvailability();
    if (availability != NfcAvailability.available) {
      throw NfcReadFailure(
        NfcReadFailureType.unavailable,
        availability == NfcAvailability.disabled
            ? 'NFC đang tắt. Hãy bật NFC trong cài đặt thiết bị.'
            : 'Thiết bị này không hỗ trợ NFC.',
      );
    }

    final provider = NfcProvider();
    _activeProvider = provider;
    _cancelRequested = false;
    var succeeded = false;

    try {
      onProgress('Đặt giấy tờ sát vùng NFC và giữ nguyên', 0.08);
      await provider.connect(
        timeout: tagPollingTimeout,
        iosAlertMessage: 'Giữ giấy tờ sát mặt lưng iPhone để đọc chip.',
      );
      _throwIfCancelled();

      if (!provider.isConnected()) {
        throw const NfcReadFailure(
          NfcReadFailureType.invalidDocument,
          'Thẻ vừa quét không phải chip ISO 7816 được hỗ trợ.',
        );
      }

      final passport = Passport(provider);
      onProgress('Đã nhận chip, đang chuẩn bị xác thực', 0.2);
      try {
        await passport.readEfCardAccess();
      } catch (_) {
        // EF.CardAccess is optional for the BAC flow.
      }
      _throwIfCancelled();

      await _startBacSession(
        passport: passport,
        profile: profile,
        accessData: accessData,
        onProgress: onProgress,
      );
      _throwIfCancelled();

      onProgress('Đang đọc danh sách dữ liệu trên chip', 0.45);
      final com = await passport.readEfCOM();
      _throwIfCancelled();

      if (!com.dgTags.contains(EfDG1.TAG)) {
        throw const NfcReadFailure(
          NfcReadFailureType.invalidDocument,
          'Chip không có nhóm dữ liệu định danh DG1.',
        );
      }

      onProgress('Đang đọc thông tin định danh (DG1)', 0.58);
      final dg1 = await passport.readEfDG1();
      _throwIfCancelled();

      EfDG2? dg2;
      if (com.dgTags.contains(EfDG2.TAG)) {
        onProgress('Đang đọc ảnh chân dung (DG2)', 0.7);
        try {
          dg2 = await passport.readEfDG2();
        } catch (_) {
          // Identity data remains useful if the optional portrait cannot be read.
        }
      }
      _throwIfCancelled();

      if (com.dgTags.contains(EfDG13.TAG)) {
        onProgress('Đang đọc dữ liệu bổ sung (DG13)', 0.82);
        try {
          await passport.readEfDG13();
        } catch (_) {
          // DG13 is country-specific and optional.
        }
      }
      _throwIfCancelled();

      var sodWasRead = false;
      onProgress('Đang đọc dữ liệu bảo mật (SOD)', 0.92);
      try {
        await passport.readEfSOD();
        sodWasRead = true;
      } catch (_) {
        // This demo reports SOD availability; it does not claim authenticity.
      }

      succeeded = true;
      onProgress('Đọc chip hoàn tất', 1);
      return profile.mapResult(
        mrz: dg1.mrz,
        availableDataGroups: _dataGroupNames(com),
        sodWasRead: sodWasRead,
        portraitBytes: dg2?.imageData,
      );
    } on NfcReadFailure {
      rethrow;
    } catch (error) {
      throw _mapFailure(error);
    } finally {
      if (identical(_activeProvider, provider)) {
        _activeProvider = null;
      }
      await _finishSession(provider, succeeded: succeeded);
    }
  }

  Future<void> _startBacSession({
    required Passport passport,
    required DocumentProfile profile,
    required DocumentAccessData accessData,
    required NfcProgressCallback onProgress,
  }) async {
    final candidates = profile.accessDocumentNumbers(accessData);
    Object? lastError;

    for (var index = 0; index < candidates.length; index++) {
      _throwIfCancelled();
      onProgress('Đang xác thực BAC', 0.3 + (index * 0.04));
      try {
        await passport.startSession(
          DBAKey(
            candidates[index],
            accessData.dateOfBirth,
            accessData.dateOfExpiry,
          ),
        );
        return;
      } catch (error) {
        lastError = error;
      }
    }

    throw NfcReadFailure(
      NfcReadFailureType.accessDenied,
      lastError == null
          ? 'Không có dữ liệu phù hợp để mở chip.'
          : 'Không thể mở chip. Kiểm tra lại số MRZ, ngày sinh và ngày hết hạn.',
    );
  }

  List<String> _dataGroupNames(EfCOM com) {
    final groups = <String>[];
    if (com.dgTags.contains(EfDG1.TAG)) groups.add('DG1');
    if (com.dgTags.contains(EfDG2.TAG)) groups.add('DG2');
    if (com.dgTags.contains(EfDG13.TAG)) groups.add('DG13');
    return groups;
  }

  void _throwIfCancelled() {
    if (_cancelRequested) {
      throw const NfcReadFailure(
        NfcReadFailureType.cancelled,
        'Đã hủy phiên đọc NFC.',
      );
    }
  }

  NfcReadFailure _mapFailure(Object error) {
    if (_cancelRequested) {
      return const NfcReadFailure(
        NfcReadFailureType.cancelled,
        'Đã hủy phiên đọc NFC.',
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('timeout') || message.contains('timed out')) {
      return const NfcReadFailure(
        NfcReadFailureType.timeout,
        'Hết thời gian chờ. Đặt giấy tờ sát điện thoại rồi thử lại.',
      );
    }
    if (message.contains('tag was lost') ||
        message.contains('tag already removed')) {
      return const NfcReadFailure(
        NfcReadFailureType.tagLost,
        'Mất kết nối với chip. Hãy giữ giấy tờ cố định lâu hơn.',
      );
    }
    if (message.contains('security status') ||
        message.contains('bac') ||
        message.contains('authentication')) {
      return const NfcReadFailure(
        NfcReadFailureType.accessDenied,
        'Không thể mở chip. Kiểm tra lại ba trường dữ liệu MRZ.',
      );
    }
    if (message.contains('communication') || message.contains('transceive')) {
      return const NfcReadFailure(
        NfcReadFailureType.communication,
        'Kết nối NFC không ổn định. Giữ giấy tờ sát máy và thử lại.',
      );
    }
    return const NfcReadFailure(
      NfcReadFailureType.unknown,
      'Không thể đọc chip. Vui lòng thử lại.',
    );
  }

  Future<void> _finishSession(
    NfcProvider provider, {
    required bool succeeded,
  }) async {
    try {
      if (provider.isConnected()) {
        await provider.disconnect(
          iosAlertMessage: succeeded ? 'Đọc chip hoàn tất.' : null,
          iosErrorMessage: succeeded ? null : 'Không thể đọc chip.',
        );
      } else {
        await FlutterNfcKit.finish();
      }
    } catch (_) {
      // Session cleanup must not replace the original read result/error.
    }
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    final provider = _activeProvider;
    try {
      if (provider?.isConnected() ?? false) {
        await provider!.disconnect(iosErrorMessage: 'Đã hủy đọc chip.');
      } else {
        await FlutterNfcKit.finish();
      }
    } catch (_) {
      // Native sessions may already have been closed by the platform.
    }
  }
}
