import '../../domain/entities/user.dart';

class UserModel {
  final int? id;
  final String email;
  final String name;
  final String passwordHash;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    this.currency = 'BOB',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convertir de Entity (a Model
  factory UserModel.fromEntity(User entity, String passwordHash) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      passwordHash: passwordHash,
      currency: entity.currency,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  // Convertir de Model  a Entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      currency: currency,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  // Convertir de SQLite a UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toInt(),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      passwordHash: map['password_hash'] ?? '',
      currency: map['currency'] ?? 'BOB',
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // Convertir de UserModel a  SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email.toLowerCase(),
      'name': name,
      'password_hash': passwordHash,
      'currency': currency,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Crear una copia con campos modificados
  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? passwordHash,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validar antes de guardar en base de datos
  bool get isValidForDatabase {
    return email.isNotEmpty &&
        name.isNotEmpty &&
        passwordHash.isNotEmpty &&
        currency.isNotEmpty;
  }

  // Obtener datos seguros
  Map<String, dynamic> toSafeMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'currency': currency,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, currency: $currency, isActive: $isActive)';
  }

  // Comparación de objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.currency == currency &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        name.hashCode ^
        currency.hashCode ^
        isActive.hashCode;
  }
}
