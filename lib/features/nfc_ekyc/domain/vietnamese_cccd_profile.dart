import 'dart:typed_data';

import 'package:dmrtd/dmrtd.dart';

import 'document_access_data.dart';
import 'document_profile.dart';
import 'document_read_result.dart';

class VietnameseCccdProfile implements DocumentProfile {
  const VietnameseCccdProfile();

  @override
  String get code => 'VNM_CCCD';

  @override
  String get displayName => 'CCCD Việt Nam';

  @override
  String get documentNumberLabel => 'Số tài liệu MRZ';

  @override
  String get documentNumberHint => '9 số ngay sau IDVNM ở mặt sau CCCD';

  @override
  String? validate(DocumentAccessData data) {
    if (!RegExp(r'^\d{9}$').hasMatch(data.documentNumber)) {
      return 'Số tài liệu MRZ phải gồm đúng 9 chữ số.';
    }
    if (data.dateOfBirth.isAfter(DateTime.now())) {
      return 'Ngày sinh không hợp lệ.';
    }
    return null;
  }

  @override
  List<String> accessDocumentNumbers(DocumentAccessData data) {
    return <String>[data.documentNumber];
  }

  @override
  DocumentReadResult mapResult({
    required MRZ mrz,
    required List<String> availableDataGroups,
    required bool sodWasRead,
    Uint8List? portraitBytes,
  }) {
    return DocumentReadResult(
      documentCode: mrz.documentCode,
      issuingCountry: mrz.country,
      nationality: mrz.nationality,
      documentNumber: mrz.documentNumber,
      identityNumber: _extractIdentityNumber(mrz),
      fullName: '${mrz.lastName} ${mrz.firstName}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      dateOfBirth: mrz.dateOfBirth,
      dateOfExpiry: mrz.dateOfExpiry,
      gender: mrz.gender,
      availableDataGroups: availableDataGroups,
      sodWasRead: sodWasRead,
      portraitBytes: portraitBytes,
    );
  }

  String _extractIdentityNumber(MRZ mrz) {
    final optionalDigits = '${mrz.optionalData}${mrz.optionalData2 ?? ''}'
        .replaceAll(RegExp(r'\D'), '');
    final match = RegExp(r'\d{12}').firstMatch(optionalDigits);
    return match?.group(0) ?? mrz.documentNumber;
  }
}
