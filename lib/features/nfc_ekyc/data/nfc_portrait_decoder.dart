import 'dart:ui' as ui;

import 'package:flutter/services.dart';

typedef PlatformPortraitDecoder =
    Future<Uint8List?> Function(Uint8List sourceBytes);

class NfcPortraitDecoder {
  const NfcPortraitDecoder({
    this.platformDecoder = _decodePortraitWithPlatform,
  });

  final PlatformPortraitDecoder platformDecoder;

  Future<Uint8List?> decodeToPng(Uint8List sourceBytes) async {
    if (sourceBytes.isEmpty) return null;

    for (final candidate in _candidates(sourceBytes)) {
      ui.Codec? codec;
      ui.FrameInfo? frame;
      try {
        codec = await ui.instantiateImageCodec(candidate);
        frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          return byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
        }
      } catch (_) {
        // DG2 can wrap JPEG/PNG/JPEG2000 bytes with a biometric header.
      } finally {
        frame?.image.dispose();
        codec?.dispose();
      }

      try {
        final decoded = await platformDecoder(candidate);
        if (decoded != null && decoded.isNotEmpty) return decoded;
      } on MissingPluginException {
        // The native fallback is currently implemented only by the iOS host.
      } on PlatformException {
        // Try the next embedded image candidate before reporting failure.
      }
    }
    return null;
  }

  List<Uint8List> _candidates(Uint8List bytes) {
    final candidates = <Uint8List>[bytes];
    for (final header in const <List<int>>[
      [0xFF, 0xD8],
      [0x89, 0x50, 0x4E, 0x47],
      [0x00, 0x00, 0x00, 0x0C, 0x6A, 0x50],
      [0xFF, 0x4F, 0xFF, 0x51],
    ]) {
      final offset = _indexOfHeader(bytes, header);
      if (offset > 0) candidates.add(Uint8List.sublistView(bytes, offset));
    }
    return candidates;
  }

  int _indexOfHeader(Uint8List bytes, List<int> header) {
    for (var index = 0; index <= bytes.length - header.length; index++) {
      var matches = true;
      for (var headerIndex = 0; headerIndex < header.length; headerIndex++) {
        if (bytes[index + headerIndex] != header[headerIndex]) {
          matches = false;
          break;
        }
      }
      if (matches) return index;
    }
    return -1;
  }
}

const _portraitDecoderChannel = MethodChannel(
  'com.example.nfc_ekyc_demo/portrait_decoder',
);

Future<Uint8List?> _decodePortraitWithPlatform(Uint8List sourceBytes) async {
  return _portraitDecoderChannel.invokeMethod<Uint8List>(
    'decodeToPng',
    sourceBytes,
  );
}
