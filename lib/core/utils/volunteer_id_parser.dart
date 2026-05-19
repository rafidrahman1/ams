import 'dart:convert';

String? normalizeVolunteerId(String? value) {
  if (value == null) return null;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      final fromId = decoded['volunteer_id'] ?? decoded['volunteerId'];
      final volunteerId = fromId?.toString().trim();
      if (volunteerId != null && volunteerId.isNotEmpty) {
        return volunteerId;
      }
    }
  } catch (_) {
    // Not a JSON payload; treat the scanned value as a plain volunteer ID.
  }

  return trimmed;
}
