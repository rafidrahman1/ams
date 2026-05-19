import 'dart:convert';

String? _volunteerIdFromMap(Map<String, dynamic> map) {
  final direct = map['volunteer_id'] ?? map['volunteerId'] ?? map['volunteer_ID'] ?? map['Volunteer_ID'];
  final directId = direct?.toString().trim();
  if (directId != null && directId.isNotEmpty) {
    return directId;
  }

  final nested = map['volunteer_data'];
  if (nested is Map<String, dynamic>) {
    return _volunteerIdFromMap(nested);
  }

  return null;
}

String? normalizeVolunteerId(String? value) {
  if (value == null) return null;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasQuery) {
    final fromQuery = uri.queryParameters['volunteer_id'] ?? uri.queryParameters['volunteerId'];
    final queryId = fromQuery?.trim();
    if (queryId != null && queryId.isNotEmpty) {
      return queryId;
    }
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return _volunteerIdFromMap(decoded);
    }
  } catch (_) {
    // Not JSON; treat as plain volunteer ID below.
  }

  return trimmed;
}
