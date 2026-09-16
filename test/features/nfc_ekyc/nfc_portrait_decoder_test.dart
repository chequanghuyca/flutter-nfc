import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_ekyc_demo/features/nfc_ekyc/data/nfc_portrait_decoder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const decoder = NfcPortraitDecoder();

  test('normalizes a directly encoded DG2 portrait to PNG', () async {
    final png = await _createPng();

    final decoded = await decoder.decodeToPng(png);

    expect(decoded, isNotNull);
    expect(decoded!.sublist(0, 4), const [0x89, 0x50, 0x4E, 0x47]);
  });

  test('finds an image wrapped behind a biometric header', () async {
    final png = await _createPng();
    final wrapped = Uint8List.fromList(<int>[0x7F, 0x61, 0x01, ...png]);

    final decoded = await decoder.decodeToPng(wrapped);

    expect(decoded, isNotNull);
    expect(decoded!.sublist(0, 4), const [0x89, 0x50, 0x4E, 0x47]);
  });

  test('uses native fallback for a wrapped JPEG2000 codestream', () async {
    final png = await _createPng();
    final receivedCandidates = <Uint8List>[];
    final decoder = NfcPortraitDecoder(
      platformDecoder: (candidate) async {
        receivedCandidates.add(candidate);
        return candidate.length >= 4 &&
                candidate[0] == 0xFF &&
                candidate[1] == 0x4F &&
                candidate[2] == 0xFF &&
                candidate[3] == 0x51
            ? png
            : null;
      },
    );
    final wrapped = Uint8List.fromList(const <int>[
      0x7F,
      0x61,
      0x01,
      0xFF,
      0x4F,
      0xFF,
      0x51,
      0x00,
    ]);

    final decoded = await decoder.decodeToPng(wrapped);

    expect(decoded, png);
    expect(
      receivedCandidates.any(
        (candidate) =>
            candidate.length >= 4 &&
            candidate[0] == 0xFF &&
            candidate[1] == 0x4F,
      ),
      isTrue,
    );
  });
}

Future<Uint8List> _createPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFF008577), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
}
