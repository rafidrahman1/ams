class AssetChecklistItem {
  final int featureId;
  final String title;
  final bool response;

  const AssetChecklistItem({required this.featureId, required this.title, required this.response});

  factory AssetChecklistItem.fromJson(Map<String, dynamic> json) {
    return AssetChecklistItem(
      featureId: _asInt(json['feature_id'] ?? json['featureId']),
      title: (json['feature'] ?? json['title'] ?? '').toString(),
      response: _asBool(json['response']),
    );
  }

  factory AssetChecklistItem.fromCacheJson(Map<String, dynamic> json) {
    return AssetChecklistItem(
      featureId: _asInt(json['featureId'] ?? json['feature_id']),
      title: (json['title'] ?? json['feature'] ?? '').toString(),
      response: _asBool(json['response']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'featureId': featureId, 'title': title, 'response': response};
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
