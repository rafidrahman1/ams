import 'dart:convert';

String? normalizeAstId(String? value) {
  if (value == null) return null;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      final fromAstId = decoded['ast_ID'] ?? decoded['ast_id'] ?? decoded['astId'];
      final astId = fromAstId?.toString().trim();
      if (astId != null && astId.isNotEmpty) {
        return astId;
      }
    }
  } catch (_) {
    // Not a JSON payload; treat the scanned value as a plain astId.
  }

  return trimmed;
}

/// Uses the RFID tag EPC as the asset ID (registration), without QR JSON parsing.
String? normalizeRfidEpcAsAstId(String? value) {
  if (value == null) return null;

  final withoutWhitespace = value.replaceAll(RegExp(r'\s+'), '');
  if (withoutWhitespace.isEmpty) return null;

  // Strip signed-byte artifacts (e.g. ffffff90 → 90) from native hex strings.
  final hex = withoutWhitespace
      .toUpperCase()
      .replaceAll(RegExp(r'FFFFFF([0-9A-F]{2})'), r'$1');
  if (hex.isEmpty) return null;

  return hex;
}
