import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/document_access_data.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/vietnamese_cccd_profile.dart';

void main() {
  const profile = VietnameseCccdProfile();

  test('accepts a 9-digit Vietnamese MRZ document number', () {
    final data = DocumentAccessData(
      documentNumber: '000000000',
      dateOfBirth: DateTime(2003, 2, 1),
      dateOfExpiry: DateTime(2031, 2, 1),
    );

    expect(profile.validate(data), isNull);
    expect(profile.accessDocumentNumbers(data), ['000000000']);
  });

  test('rejects the 12-digit personal identity number as BAC input', () {
    final data = DocumentAccessData(
      documentNumber: '000000000000',
      dateOfBirth: DateTime(2003, 2, 1),
      dateOfExpiry: DateTime(2031, 2, 1),
    );

    expect(profile.validate(data), isNotNull);
  });
}
