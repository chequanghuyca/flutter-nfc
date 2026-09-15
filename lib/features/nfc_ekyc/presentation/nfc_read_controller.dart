import 'package:flutter/foundation.dart';

import '../data/nfc_document_reader.dart';
import '../domain/document_access_data.dart';
import '../domain/document_profile.dart';
import '../domain/document_read_result.dart';

enum NfcReadPhase { idle, reading, success, error }

class NfcReadState {
  const NfcReadState({
    this.phase = NfcReadPhase.idle,
    this.availability = NfcAvailability.unknown,
    this.status = 'Sẵn sàng kiểm tra NFC',
    this.progress = 0,
    this.result,
    this.errorMessage,
  });

  final NfcReadPhase phase;
  final NfcAvailability availability;
  final String status;
  final double progress;
  final DocumentReadResult? result;
  final String? errorMessage;

  bool get isReading => phase == NfcReadPhase.reading;
}

class NfcReadController extends ChangeNotifier {
  NfcReadController({
    required NfcDocumentReader reader,
    required DocumentProfile profile,
  }) : _reader = reader,
       _profile = profile;

  final NfcDocumentReader _reader;
  final DocumentProfile _profile;
  NfcReadState _state = const NfcReadState();
  var _operation = 0;
  bool _disposed = false;

  NfcReadState get state => _state;

  Future<void> refreshAvailability() async {
    final availability = await _reader.checkAvailability();
    if (_disposed) return;
    _setState(
      NfcReadState(
        availability: availability,
        status: switch (availability) {
          NfcAvailability.available => 'NFC đã sẵn sàng',
          NfcAvailability.disabled => 'NFC đang tắt',
          NfcAvailability.unsupported => 'Thiết bị không hỗ trợ NFC',
          NfcAvailability.unknown => 'Chưa xác định trạng thái NFC',
        },
      ),
    );
  }

  Future<void> start(DocumentAccessData accessData) async {
    if (_state.isReading) return;

    final validationError = _profile.validate(accessData);
    if (validationError != null) {
      _setState(
        NfcReadState(
          availability: _state.availability,
          phase: NfcReadPhase.error,
          status: 'Dữ liệu chưa hợp lệ',
          errorMessage: validationError,
        ),
      );
      return;
    }

    final operation = ++_operation;
    _setState(
      NfcReadState(
        availability: _state.availability,
        phase: NfcReadPhase.reading,
        status: 'Đang chuẩn bị đọc chip',
      ),
    );

    try {
      final result = await _reader.read(
        profile: _profile,
        accessData: accessData,
        onProgress: (status, progress) {
          if (_disposed || operation != _operation) return;
          _setState(
            NfcReadState(
              availability: NfcAvailability.available,
              phase: NfcReadPhase.reading,
              status: status,
              progress: progress.clamp(0, 1),
            ),
          );
        },
      );
      if (_disposed || operation != _operation) return;
      _setState(
        NfcReadState(
          availability: NfcAvailability.available,
          phase: NfcReadPhase.success,
          status: 'Đọc chip thành công',
          progress: 1,
          result: result,
        ),
      );
    } on NfcReadFailure catch (failure) {
      if (_disposed || operation != _operation) return;
      _setState(
        NfcReadState(
          availability: failure.type == NfcReadFailureType.unavailable
              ? _state.availability == NfcAvailability.unsupported
                    ? NfcAvailability.unsupported
                    : NfcAvailability.disabled
              : _state.availability,
          phase: NfcReadPhase.error,
          status: 'Không thể đọc chip',
          errorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> cancel() async {
    if (!_state.isReading) return;
    _operation++;
    await _reader.cancel();
    if (_disposed) return;
    _setState(
      NfcReadState(
        availability: _state.availability,
        status: 'Đã hủy phiên đọc NFC',
      ),
    );
  }

  void reset() {
    _operation++;
    _setState(
      NfcReadState(
        availability: _state.availability,
        status: 'Sẵn sàng đọc lại',
      ),
    );
  }

  void _setState(NfcReadState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_state.isReading) {
      _reader.cancel();
    }
    super.dispose();
  }
}
