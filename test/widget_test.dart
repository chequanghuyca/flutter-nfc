import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/data/nfc_document_reader.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/document_access_data.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/document_profile.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/domain/document_read_result.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/presentation/nfc_home_screen.dart';

void main() {
  testWidgets('shows the minimal Vietnamese CCCD input flow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: NfcHomeScreen(reader: _FakeReader())),
    );
    await tester.pump();

    expect(find.text('NFC eKYC Demo'), findsOneWidget);
    expect(find.text('CCCD Việt Nam'), findsOneWidget);
    expect(find.text('1. Chụp CCCD và đọc MRZ'), findsOneWidget);
    expect(find.text('2. Kiểm tra dữ liệu MRZ'), findsOneWidget);
    expect(
      find.byKey(const Key('start-document-capture-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('document-number-field')), findsOneWidget);
    expect(find.byKey(const Key('start-reading-button')), findsOneWidget);
  });

  testWidgets('validates required BAC fields before reading', (tester) async {
    final reader = _FakeReader();
    await tester.pumpWidget(MaterialApp(home: NfcHomeScreen(reader: reader)));
    await tester.pump();

    final startButton = find.byKey(const Key('start-reading-button'));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pump();

    expect(find.text('Nhập đúng 9 chữ số.'), findsOneWidget);
    expect(find.text('Chọn đủ ngày sinh và ngày hết hạn.'), findsOneWidget);
    expect(reader.readCount, 0);
  });
}

class _FakeReader implements NfcDocumentReader {
  int readCount = 0;

  @override
  Future<void> cancel() async {}

  @override
  Future<NfcAvailability> checkAvailability() async {
    return NfcAvailability.available;
  }

  @override
  Future<DocumentReadResult> read({
    required DocumentProfile profile,
    required DocumentAccessData accessData,
    required NfcProgressCallback onProgress,
  }) async {
    readCount++;
    throw UnimplementedError();
  }
}
