import '../../domain/entities/category.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String color;
  final String icon;
  final double defaultBudget;
  final bool isActive;
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    this.id,
    required this.name,
    this.color = '#2196F3',
    this.icon = 'category',
    this.defaultBudget = 0.0,
    this.isActive = true,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  // =============================================
  // CONVERSIÓN DESDE/HACIA ENTITY (DOMAIN)
  // =============================================

  // Convertir de Entity (Domain) a Model (Data)
  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      icon: entity.icon,
      defaultBudget: entity.defaultBudget,
      isActive: entity.isActive,
      userId: entity.userId,
      createdAt: entity.createdAt,
    );
  }

  // Convertir de Model (Data) a Entity (Domain)
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      color: color,
      icon: icon,
      defaultBudget: defaultBudget,
      isActive: isActive,
      userId: userId,
      createdAt: createdAt,
    );
  }

  // =============================================
  // CONVERSIÓN DESDE/HACIA DATABASE (SQLITE)
  // =============================================

  // Convertir de Map (SQLite) a CategoryModel
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      color: map['color'] ?? '#2196F3',
      icon: map['icon'] ?? 'category',
      defaultBudget: (map['default_budget'] ?? 0.0).toDouble(),
      isActive: (map['is_active'] ?? 1) == 1,
      userId: map['user_id']?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // Convertir de CategoryModel a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'color': color,
      'icon': icon,
      'default_budget': defaultBudget,
      'is_active': isActive ? 1 : 0,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // =============================================
  // MÉTODOS DE UTILIDAD
  // =============================================

  // Crear una copia con campos modificados
  CategoryModel copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    double? defaultBudget,
    bool? isActive,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      defaultBudget: defaultBudget ?? this.defaultBudget,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validar antes de guardar en base de datos
  bool get isValidForDatabase {
    return name.isNotEmpty &&
        color.isNotEmpty &&
        icon.isNotEmpty &&
        userId > 0 &&
        defaultBudget >= 0;
  }

  // Crear categoría predefinida
  factory CategoryModel.createDefault({
    required String name,
    required String color,
    required String icon,
    required int userId,
    double defaultBudget = 0.0,
  }) {
    return CategoryModel(
      name: name,
      color: color,
      icon: icon,
      defaultBudget: defaultBudget,
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  // Obtener categorías predefinidas para un usuario
  static List<CategoryModel> getDefaultCategories(int userId) {
    final now = DateTime.now();

    return [
      CategoryModel(
        name: 'Alimentación',
        color: '#4CAF50',
        icon: 'restaurant',
        defaultBudget: 1500.0,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Transporte',
        color: '#2196F3',
        icon: 'directions_car',
        defaultBudget: 800.0,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Entretenimiento',
        color: '#FF9800',
        icon: 'movie',
        defaultBudget: 500.0,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Salud',
        color: '#F44336',
        icon: 'local_hospital',
        defaultBudget: 600.0,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Educación',
        color: '#9C27B0',
        icon: 'school',
        defaultBudget: 400.0,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Hogar',
        color: '#795548',
        icon: 'home',
        defaultBudget: 1000.0,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Otros',
        color: '#607D8B',
        icon: 'category',
        defaultBudget: 300.0,
        userId: userId,
        createdAt: now,
      ),
    ];
  }

  // Verificar si coincide con criterios de búsqueda
  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();
    return name.toLowerCase().contains(lowerQuery);
  }

  // Verificar si pertenece a un usuario específico
  bool belongsToUser(int targetUserId) {
    return userId == targetUserId;
  }

  // Obtener datos para dropdown/selector
  Map<String, dynamic> toSelectorMap() {
    return {'id': id, 'name': name, 'color': color, 'icon': icon};
  }

  // Obtener datos para reportes
  Map<String, dynamic> toReportMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'default_budget': defaultBudget,
      'is_active': isActive,
    };
  }

  // Desactivar categoría (soft delete)
  CategoryModel deactivate() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  // Activar categoría
  CategoryModel activate() {
    return copyWith(isActive: true, updatedAt: DateTime.now());
  }

  // Obtener representación como String para dropdowns
  String get displayName => name;

  // Para debugging y logs
  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, color: $color, userId: $userId, isActive: $isActive)';
  }

  // Comparación de objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.icon == icon &&
        other.userId == userId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        color.hashCode ^
        icon.hashCode ^
        userId.hashCode ^
        isActive.hashCode;
  }
}
