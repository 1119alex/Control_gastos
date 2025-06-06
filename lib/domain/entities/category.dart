class Category {
  final int? id;
  final String name;
  final String color;
  final String icon;
  final double defaultBudget;
  final bool isActive;
  final int userId;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    this.color = '#2196F3',
    this.icon = 'category',
    this.defaultBudget = 0.0,
    this.isActive = true,
    required this.userId,
    required this.createdAt,
  });

  // Regla de negocio: ¿Es un nombre válido?
  bool get hasValidName {
    return name.trim().length >= 2 && name.trim().length <= 50;
  }

  // Regla de negocio: ¿Es un color válido?
  bool get hasValidColor {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color);
  }

  // Regla de negocio: ¿Es un presupuesto válido?
  bool get hasValidBudget {
    return defaultBudget >= 0 && defaultBudget <= 100000; // Máximo 100k BOB
  }

  // Regla de negocio: ¿Es una categoría válida?
  bool get isValid {
    return hasValidName && hasValidColor && hasValidBudget && isActive;
  }

  // Regla de negocio: Nombre formateado
  String get formattedName {
    return name
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // Regla de negocio: ¿Tiene presupuesto definido?
  bool get hasBudget {
    return defaultBudget > 0;
  }

  // Regla de negocio: Presupuesto formateado
  String get formattedBudget {
    if (!hasBudget) return 'Sin presupuesto';
    return 'Bs. ${defaultBudget.toStringAsFixed(2)}';
  }

  // Regla de negocio: Obtener el tipo de categoría según el nombre
  CategoryType get type {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('comida') ||
        lowerName.contains('alimentación') ||
        lowerName.contains('restaurante') ||
        lowerName.contains('supermercado')) {
      return CategoryType.food;
    }

    if (lowerName.contains('transporte') ||
        lowerName.contains('taxi') ||
        lowerName.contains('bus') ||
        lowerName.contains('gasolina')) {
      return CategoryType.transport;
    }

    if (lowerName.contains('entretenimiento') ||
        lowerName.contains('diversión') ||
        lowerName.contains('cine') ||
        lowerName.contains('juego')) {
      return CategoryType.entertainment;
    }

    if (lowerName.contains('salud') ||
        lowerName.contains('médico') ||
        lowerName.contains('farmacia') ||
        lowerName.contains('hospital')) {
      return CategoryType.health;
    }

    if (lowerName.contains('educación') ||
        lowerName.contains('libro') ||
        lowerName.contains('curso') ||
        lowerName.contains('universidad')) {
      return CategoryType.education;
    }

    if (lowerName.contains('casa') ||
        lowerName.contains('hogar') ||
        lowerName.contains('alquiler') ||
        lowerName.contains('servicios')) {
      return CategoryType.home;
    }

    return CategoryType.other;
  }

  // Regla de negocio: Sugerir ícono basado en el tipo
  String get suggestedIcon {
    switch (type) {
      case CategoryType.food:
        return 'restaurant';
      case CategoryType.transport:
        return 'directions_car';
      case CategoryType.entertainment:
        return 'movie';
      case CategoryType.health:
        return 'local_hospital';
      case CategoryType.education:
        return 'school';
      case CategoryType.home:
        return 'home';
      case CategoryType.other:
        return 'category';
    }
  }

  // Regla de negocio: Prioridad de la categoría (para ordenamiento)
  int get priority {
    switch (type) {
      case CategoryType.food:
        return 6; // Más importante
      case CategoryType.transport:
        return 5;
      case CategoryType.home:
        return 4;
      case CategoryType.health:
        return 3;
      case CategoryType.education:
        return 2;
      case CategoryType.entertainment:
        return 1;
      case CategoryType.other:
        return 0; // Menos importante
    }
  }

  // Crear copia con cambios
  Category copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    double? defaultBudget,
    bool? isActive,
    int? userId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      defaultBudget: defaultBudget ?? this.defaultBudget,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $formattedName, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ userId.hashCode;
}

// Enum para los tipos de categoría
enum CategoryType {
  food,
  transport,
  entertainment,
  health,
  education,
  home,
  other,
}
