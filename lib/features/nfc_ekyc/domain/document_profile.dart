import 'dart:typed_data';

import 'package:dmrtd/dmrtd.dart';

import 'document_access_data.dart';
import 'document_read_result.dart';

abstract interface class DocumentProfile {
  String get code;

  String get displayName;

  String get documentNumberLabel;

  String get documentNumberHint;

  String? validate(DocumentAccessData data);

  List<String> accessDocumentNumbers(DocumentAccessData data);

  DocumentReadResult mapResult({
    required MRZ mrz,
    required List<String> availableDataGroups,
    required bool sodWasRead,
    Uint8List? portraitBytes,
  });
}
