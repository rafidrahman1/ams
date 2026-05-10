import 'dart:convert';

import 'package:nfc_manager/nfc_manager.dart';

class NfcParser {
  static Future<String?> extractTagValue(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      return null;
    }

    final message = ndef.cachedMessage ?? await ndef.read();

    for (final record in message.records) {
      final value = _parseRecordPayload(record);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static String? _parseRecordPayload(NdefRecord record) {
    if (record.payload.isEmpty) {
      return null;
    }

    final type = utf8.decode(record.type, allowMalformed: true);

    // 1. Handle Custom MIME Type
    // We allow both 'assets' and 'assests' (common typo) to be robust.
    if (record.typeNameFormat == NdefTypeNameFormat.media && (type == 'application/vnd.com.example.assets' || type == 'application/vnd.com.example.assests')) {
      return utf8.decode(record.payload, allowMalformed: true).trim();
    }

    // 2. Handle Standard NFC Text Record (Type 'T')
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown && type == 'T') {
      final statusByte = record.payload.first;
      final languageCodeLength = statusByte & 0x3F;
      if (record.payload.length <= languageCodeLength + 1) {
        return null;
      }
      return utf8.decode(record.payload.sublist(languageCodeLength + 1), allowMalformed: true).trim();
    }

    return null;
  }
}
