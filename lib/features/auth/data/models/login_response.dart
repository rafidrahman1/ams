class LoginResponse {
  final int code;
  final String access;
  final String refresh;
  final String tokenType;
  final int? expiry;
  final UserObject? userObject;
  final bool isEmployee;
  final bool isVendor;
  final List<String> permissions;

  LoginResponse({
    required this.code,
    required this.access,
    required this.refresh,
    required this.tokenType,
    required this.expiry,
    required this.userObject,
    required this.isEmployee,
    required this.isVendor,
    required this.permissions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      code: json['code'] ?? 0,
      access: json['access_token'] ?? '',
      refresh: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? '',
      expiry: json['expiry'] as int?,
      userObject: json['user_object'] == null
          ? null
          : UserObject.fromJson(json['user_object'] as Map<String, dynamic>),
      isEmployee: json['is_employee'] ?? false,
      isVendor: json['is_vendor'] ?? false,
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class UserObject {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? lastLogin;
  final bool isActive;
  final String? photo;
  final String fullName;

  UserObject({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.lastLogin,
    required this.isActive,
    required this.photo,
    required this.fullName,
  });

  factory UserObject.fromJson(Map<String, dynamic> json) {
    return UserObject(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      lastLogin: json['last_login']?.toString(),
      isActive: json['is_active'] ?? false,
      photo: json['photo']?.toString(),
      fullName: json['full_name'] ?? '',
    );
  }
}