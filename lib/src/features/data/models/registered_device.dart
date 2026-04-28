class RegisteredDevice {
  final int? id;
  final String name;
  final String details;
  final String addressLine;
  final String? status;
  final String? location;
  final String? block;
  final String? imagePath;
  final DateTime createdAt;
  final bool synced;

  const RegisteredDevice({
    this.id,
    required this.name,
    required this.details,
    required this.addressLine,
    this.status,
    this.location,
    this.block,
    this.imagePath,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'address_line': addressLine,
      'status': status,
      'location': location,
      'block': block,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }

  factory RegisteredDevice.fromMap(Map<String, dynamic> map) {
    return RegisteredDevice(
      id: map['id'] as int?,
      name: map['name'] as String,
      details: map['details'] as String,
      addressLine: map['address_line'] as String,
      status: map['status'] as String?,
      location: map['location'] as String?,
      block: map['block'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      synced: (map['synced'] as int) == 1,
    );
  }

  RegisteredDevice copyWith({
    int? id,
    String? name,
    String? details,
    String? addressLine,
    String? status,
    String? location,
    String? block,
    String? imagePath,
    DateTime? createdAt,
    bool? synced,
  }) {
    return RegisteredDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      addressLine: addressLine ?? this.addressLine,
      status: status ?? this.status,
      location: location ?? this.location,
      block: block ?? this.block,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}
