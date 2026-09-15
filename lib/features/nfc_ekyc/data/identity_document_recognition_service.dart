import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'vietnamese_cccd_mrz_parser.dart';

abstract interface class IdentityDocumentRecognitionService {
  Future<String?> recognizeFrontIdentityNumber(String imagePath);

  Future<VietnameseCccdMrzResult?> recognizeBackMrz(String imagePath);

  Future<void> close();
}

class MlKitIdentityDocumentRecognitionService
    implements IdentityDocumentRecognitionService {
  MlKitIdentityDocumentRecognitionService({
    VietnameseCccdMrzParser parser = const VietnameseCccdMrzParser(),
  }) : _parser = parser;

  final VietnameseCccdMrzParser _parser;
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  Future<String?> recognizeFrontIdentityNumber(String imagePath) async {
    final text = await _recognize(imagePath);
    return _parser.extractFrontIdentityNumber(text);
  }

  @override
  Future<VietnameseCccdMrzResult?> recognizeBackMrz(String imagePath) async {
    final text = await _recognize(imagePath);
    return _parser.parseBack(text);
  }

  Future<String> _recognize(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  @override
  Future<void> close() => _recognizer.close();
}
