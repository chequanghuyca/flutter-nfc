import '../domain/document_access_data.dart';

class VietnameseCccdMrzResult {
  const VietnameseCccdMrzResult({
    required this.identityNumber,
    required this.accessData,
  });

  final String identityNumber;
  final DocumentAccessData accessData;
}

class VietnameseCccdMrzParser {
  const VietnameseCccdMrzParser();

  String? extractFrontIdentityNumber(String recognizedText) {
    for (final rawLine in recognizedText.split('\n')) {
      final line = _normalizeNumericLine(rawLine);
      final match = RegExp(r'\d{12}').firstMatch(line);
      if (match != null) return match.group(0);
    }
    return null;
  }

  VietnameseCccdMrzResult? parseBack(String recognizedText) {
    final lines = recognizedText
        .split('\n')
        .map(_normalizeMrzLine)
        .where((line) => line.isNotEmpty)
        .toList();
    final candidates = <String>[...lines];
    for (var index = 0; index + 1 < lines.length; index++) {
      candidates.add('${lines[index]}${lines[index + 1]}');
    }

    final documentLine = _findDocumentLine(candidates);
    final dateLine = _findDateLine(candidates);
    if (documentLine == null || dateLine == null) return null;

    final documentNumber = documentLine.substring(5, 14);
    if (!RegExp(r'^\d{9}$').hasMatch(documentNumber)) return null;

    // TD1 position 14 is the document-number check digit. The Vietnamese
    // 12-digit identity number starts in optional data at position 15.
    final identityMatch = RegExp(
      r'\d{12}',
    ).firstMatch(documentLine.substring(15));
    if (identityMatch == null) return null;

    final dates = _extractDates(dateLine);
    if (dates == null) return null;

    try {
      return VietnameseCccdMrzResult(
        identityNumber: identityMatch.group(0)!,
        accessData: DocumentAccessData(
          documentNumber: documentNumber,
          dateOfBirth: _parseCompactDate(dates.$1, futureDate: false),
          dateOfExpiry: _parseCompactDate(dates.$2, futureDate: true),
        ),
      );
    } on FormatException {
      return null;
    }
  }

  String? _findDocumentLine(List<String> lines) {
    for (final line in lines) {
      final start = line.indexOf('IDVNM');
      if (start < 0) continue;
      final candidate = line.substring(start);
      if (candidate.length >= 26) return candidate;
    }
    return null;
  }

  String? _findDateLine(List<String> lines) {
    for (final line in lines) {
      if (line.contains('IDVNM') || !line.contains('VNM')) continue;
      if (_extractDates(line) != null) return line;
    }
    return null;
  }

  (String, String)? _extractDates(String line) {
    final structured = RegExp(r'(\d{6})\d?[MF<](\d{6})\d?VNM').firstMatch(line);
    if (structured != null) {
      return (structured.group(1)!, structured.group(2)!);
    }

    final matches = RegExp(r'\d{6}').allMatches(line).toList();
    if (matches.length < 2) return null;
    return (matches[0].group(0)!, matches[1].group(0)!);
  }

  String _normalizeMrzLine(String value) {
    final compact = value
        .toUpperCase()
        .replaceAll('«', '<')
        .replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < compact.length; index++) {
      final character = compact[index];
      if (character == '<' ||
          (character.codeUnitAt(0) >= 65 && character.codeUnitAt(0) <= 90) ||
          int.tryParse(character) != null) {
        buffer.write(character);
      }
    }

    final normalized = buffer.toString();
    final documentMarker = RegExp(r'[I1L][D0]VNM').firstMatch(normalized);
    if (documentMarker != null) {
      final numeric = _replaceNumericConfusions(
        normalized.substring(documentMarker.end),
      );
      return 'IDVNM$numeric';
    }
    return _replaceNumericConfusionsExceptMarkers(normalized);
  }

  String _normalizeNumericLine(String value) {
    return _replaceNumericConfusions(
      value.toUpperCase(),
    ).replaceAll(RegExp(r'[\s.\-]'), '');
  }

  String _replaceNumericConfusionsExceptMarkers(String value) {
    return value
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('K', '<');
  }

  String _replaceNumericConfusions(String value) {
    return value
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('Z', '2')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('K', '<');
  }

  DateTime _parseCompactDate(String value, {required bool futureDate}) {
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      throw const FormatException('Invalid MRZ date');
    }

    final now = DateTime.now();
    var year = 2000 + int.parse(value.substring(0, 2));
    final month = int.parse(value.substring(2, 4));
    final day = int.parse(value.substring(4, 6));
    final maximumYear = futureDate ? now.year + 20 : now.year;
    if (year > maximumYear) year -= 100;

    final result = DateTime(year, month, day);
    if (result.year != year || result.month != month || result.day != day) {
      throw const FormatException('Invalid MRZ date');
    }
    return result;
  }
}
