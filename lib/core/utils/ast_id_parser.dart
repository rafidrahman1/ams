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
