import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/data/vietnamese_cccd_mrz_parser.dart';

void main() {
  const parser = VietnameseCccdMrzParser();

  test('extracts the 12-digit identity number from front OCR text', () {
    const text = '''
CĂN CƯỚC CÔNG DÂN
Số / No: 000 000 000 000
NGƯỜI DÙNG THỬ
''';

    expect(parser.extractFrontIdentityNumber(text), '000000000000');
  });

  test('parses BAC fields from Vietnamese CCCD MRZ', () {
    const text = '''
IDVNM000000000<000000000000<<<<<<<<
0302011M3102012VNM<<<<<<<<<<<<<<<<<<<
TEST<<USER<<<<<<<<<<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.identityNumber, '000000000000');
    expect(result.accessData.documentNumber, '000000000');
    expect(result.accessData.dateOfBirth, DateTime(2003, 2, 1));
    expect(result.accessData.dateOfExpiry, DateTime(2031, 2, 1));
  });

  test('normalizes common OCR mistakes in numeric MRZ fields', () {
    const text = '''
IDVNMOOOOOOOOO<OOOOOOOOOOOO<<<<<<<<
O3O2O11M31O2O12VNM<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.identityNumber, '000000000000');
    expect(result.accessData.documentNumber, '000000000');
  });

  test('skips the document check digit before the identity number', () {
    const text = '''
IDVNM1111111111222222222222KK2
0302011M3102012VNM<<<<<<<<<<<<<<<<<<<
TEST<<USER<<<<<<<<<<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.accessData.documentNumber, '111111111');
    expect(result.identityNumber, '222222222222');
  });

  test('recovers a split MRZ line and common marker OCR mistakes', () {
    const text = '''
1DVNM1111111111
222222222222KK2
OOO1O12M4OO1O1OVNMKKKKKKKKKK6
TEST<<USER<<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.accessData.documentNumber, '111111111');
    expect(result.identityNumber, '222222222222');
    expect(result.accessData.dateOfBirth, DateTime(2000, 1, 1));
    expect(result.accessData.dateOfExpiry, DateTime(2040, 1, 1));
  });

  test('rejects incomplete OCR text', () {
    expect(parser.parseBack('IDVNM000000000'), isNull);
    expect(parser.extractFrontIdentityNumber('không có số giấy tờ'), isNull);
  });
}
