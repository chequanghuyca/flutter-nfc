import 'dart:typed_data';

class DocumentReadResult {
  const DocumentReadResult({
    required this.documentCode,
    required this.issuingCountry,
    required this.nationality,
    required this.documentNumber,
    required this.identityNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    required this.gender,
    required this.availableDataGroups,
    required this.sodWasRead,
    this.portraitBytes,
  });

  final String documentCode;
  final String issuingCountry;
  final String nationality;
  final String documentNumber;
  final String identityNumber;
  final String fullName;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;
  final String gender;
  final List<String> availableDataGroups;
  final bool sodWasRead;
  final Uint8List? portraitBytes;
}
