class AssetChecklistItem {
  final int responseId;
  final String title;
  final bool response;

  const AssetChecklistItem({
    required this.responseId,
    required this.title,
    required this.response,
  });

  factory AssetChecklistItem.fromJson(Map<String, dynamic> json) {
    return AssetChecklistItem(
      responseId: _asInt(json['response_id']),
      title: (json['title'] ?? '').toString(),
      response: _asBool(json['response']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
