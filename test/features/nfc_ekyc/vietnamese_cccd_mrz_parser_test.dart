import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/data/vietnamese_cccd_mrz_parser.dart';

void main() {
  const parser = VietnameseCccdMrzParser();

  test('extracts the 12-digit identity number from front OCR text', () {
    const text = '''
CĂN CƯỚC CÔNG DÂN
Số / No: 079 203 012 345
NGUYỄN VĂN AN
''';

    expect(parser.extractFrontIdentityNumber(text), '079203012345');
  });

  test('parses BAC fields from Vietnamese CCCD MRZ', () {
    const text = '''
IDVNM025203000<079203012345<<<<<<<<
0302011M3102012VNM<<<<<<<<<<<<<<<<<<<
NGUYEN<<VAN<AN<<<<<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.identityNumber, '079203012345');
    expect(result.accessData.documentNumber, '025203000');
    expect(result.accessData.dateOfBirth, DateTime(2003, 2, 1));
    expect(result.accessData.dateOfExpiry, DateTime(2031, 2, 1));
  });

  test('normalizes common OCR mistakes in numeric MRZ fields', () {
    const text = '''
IDVNM0252O3OOO<0792O3O12345<<<<<<<<
O3O2O11M31O2O12VNM<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.identityNumber, '079203012345');
    expect(result.accessData.documentNumber, '025203000');
  });

  test('skips the document check digit before the identity number', () {
    const text = '''
IDVNM0990079121087099007912KK2
0302011M3102012VNM<<<<<<<<<<<<<<<<<<<
NGUYEN<<VAN<AN<<<<<<<<<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.accessData.documentNumber, '099007912');
    expect(result.identityNumber, '087099007912');
  });

  test('recovers a split MRZ line and common marker OCR mistakes', () {
    const text = '''
1DVNM0990079121
O87099007912KK2
99O9O92M39O9O9OVNMKKKKKKKKKK6
CHE<<QUANG<HUY<<<<<<<<<<<<<<<
''';

    final result = parser.parseBack(text);

    expect(result, isNotNull);
    expect(result!.accessData.documentNumber, '099007912');
    expect(result.identityNumber, '087099007912');
    expect(result.accessData.dateOfBirth, DateTime(1999, 9, 9));
    expect(result.accessData.dateOfExpiry, DateTime(2039, 9, 9));
  });

  test('rejects incomplete OCR text', () {
    expect(parser.parseBack('IDVNM025203000'), isNull);
    expect(parser.extractFrontIdentityNumber('không có số giấy tờ'), isNull);
  });
}
