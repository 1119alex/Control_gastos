class User {
  final int? id;
  final String email;
  final String name;
  final String currency;
  final bool isActive;
  final DateTime createdAt;

  const User({
    this.id,
    required this.email,
    required this.name,
    this.currency = 'BOB',
    this.isActive = true,
    required this.createdAt,
  });

  // Regla de negocio: ¿Es un email válido?
  bool get hasValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Regla de negocio: ¿Es un nombre válido?
  bool get hasValidName {
    return name.trim().length >= 2;
  }

  // Regla de negocio: ¿Es un usuario válido?
  bool get isValid {
    return hasValidEmail && hasValidName && isActive;
  }

  // Regla de negocio: Nombre formateado
  String get displayName {
    return name
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // Regla de negocio: Iniciales del usuario
  String get initials {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  // Regla de negocio: ¿Es un usuario nuevo?
  bool get isNewUser {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation <= 7;
  }

  // Crear copia con cambios
  User copyWith({
    int? id,
    String? email,
    String? name,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;
}
