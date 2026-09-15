import 'dart:typed_data';

import 'document_access_data.dart';

class IdentityCaptureResult {
  const IdentityCaptureResult({
    required this.frontImageBytes,
    required this.backImageBytes,
    required this.identityNumber,
    required this.accessData,
  });

  final Uint8List frontImageBytes;
  final Uint8List backImageBytes;
  final String identityNumber;
  final DocumentAccessData accessData;
}
