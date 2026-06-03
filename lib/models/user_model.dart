import 'dart:convert';
import '../providers/role_provider.dart';

class UserAccount {
  final String id;
  final String name;
  final String username;
  final String password; // Simple plain-text password for mock storage/validation
  final UserRole role;
  final bool isActive;

  UserAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role.index, // Serialize enum as index
      'isActive': isActive,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      role: UserRole.values[(map['role'] as int? ?? 0)],
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory UserAccount.fromJson(String source) => UserAccount.fromMap(json.decode(source));

  UserAccount copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    UserRole? role,
    bool? isActive,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
