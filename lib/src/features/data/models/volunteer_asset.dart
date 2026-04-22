class VolunteerAsset {
  final String name;
  final String details;
  final String astId;

  const VolunteerAsset({required this.name, required this.details, required this.astId});

  factory VolunteerAsset.fromAssignmentJson(Map<String, dynamic> json) {
    final asset = json['asset'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return VolunteerAsset(name: (asset['name'] ?? '').toString(), details: (asset['details'] ?? '').toString(), astId: (asset['ast_ID'] ?? '').toString());
  }

  factory VolunteerAsset.fromCacheJson(Map<String, dynamic> json) {
    return VolunteerAsset(name: (json['name'] ?? '').toString(), details: (json['details'] ?? '').toString(), astId: (json['astId'] ?? json['ast_ID'] ?? '').toString());
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'details': details, 'astId': astId};
  }
}
