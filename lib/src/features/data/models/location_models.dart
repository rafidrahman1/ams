class IdNamePair {
  final int id;
  final String name;

  IdNamePair({required this.id, required this.name});

  factory IdNamePair.fromJson(Map<String, dynamic> json) {
    return IdNamePair(id: json['id'] as int? ?? 0, name: (json['name'] ?? json['asset_type'] ?? '').toString());
  }

  factory IdNamePair.fromCacheJson(Map<String, dynamic> json) {
    return IdNamePair(id: json['id'] as int? ?? 0, name: (json['name'] ?? '').toString());
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;
}
