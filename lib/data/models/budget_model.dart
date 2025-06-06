import '../../domain/entities/budget.dart';

class BudgetModel {
  final int? id;
  final int categoryId;
  final int userId;
  final int month;
  final int year;
  final double limitAmount;
  final double spentAmount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.userId,
    required this.month,
    required this.year,
    required this.limitAmount,
    this.spentAmount = 0.0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // =============================================
  // CONVERSIÓN DESDE/HACIA ENTITY (DOMAIN)
  // =============================================

  // Convertir de Entity (Domain) a Model (Data)
  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      id: entity.id,
      categoryId: entity.categoryId,
      userId: entity.userId,
      month: entity.month,
      year: entity.year,
      limitAmount: entity.limitAmount,
      spentAmount: entity.spentAmount,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Convertir de Model (Data) a Entity (Domain)
  Budget toEntity() {
    return Budget(
      id: id,
      categoryId: categoryId,
      userId: userId,
      month: month,
      year: year,
      limitAmount: limitAmount,
      spentAmount: spentAmount,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // =============================================
  // CONVERSIÓN DESDE/HACIA DATABASE (SQLITE)
  // =============================================

  // Convertir de Map (SQLite) a BudgetModel
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id']?.toInt(),
      categoryId: map['category_id']?.toInt() ?? 0,
      userId: map['user_id']?.toInt() ?? 0,
      month: map['month']?.toInt() ?? 1,
      year: map['year']?.toInt() ?? DateTime.now().year,
      limitAmount: (map['limit_amount'] ?? 0.0).toDouble(),
      spentAmount: (map['spent_amount'] ?? 0.0).toDouble(),
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // Convertir de BudgetModel a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'user_id': userId,
      'month': month,
      'year': year,
      'limit_amount': limitAmount,
      'spent_amount': spentAmount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // =============================================
  // MÉTODOS DE UTILIDAD
  // =============================================

  // Crear una copia con campos modificados
  BudgetModel copyWith({
    int? id,
    int? categoryId,
    int? userId,
    int? month,
    int? year,
    double? limitAmount,
    double? spentAmount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validar antes de guardar en base de datos
  bool get isValidForDatabase {
    return categoryId > 0 &&
        userId > 0 &&
        month >= 1 &&
        month <= 12 &&
        year >= 2020 &&
        limitAmount > 0;
  }

  // Crear presupuesto automático basado en gastos anteriores
  factory BudgetModel.createFromPreviousSpending({
    required int categoryId,
    required int userId,
    required int month,
    required int year,
    required double averageSpending,
    double marginPercentage = 20.0, // 20% más que el promedio
  }) {
    final suggestedLimit = averageSpending * (1 + marginPercentage / 100);

    return BudgetModel(
      categoryId: categoryId,
      userId: userId,
      month: month,
      year: year,
      limitAmount: suggestedLimit,
      createdAt: DateTime.now(),
    );
  }

  // Obtener datos para reportes
  Map<String, dynamic> toReportMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'month': month,
      'year': year,
      'limit_amount': limitAmount,
      'spent_amount': spentAmount,
      'remaining_amount': limitAmount - spentAmount,
      'spent_percentage': limitAmount > 0
          ? (spentAmount / limitAmount) * 100
          : 0,
      'is_exceeded': spentAmount > limitAmount,
    };
  }

  // Verificar si coincide con criterios de búsqueda
  bool matchesPeriod(int targetMonth, int targetYear) {
    return month == targetMonth && year == targetYear;
  }

  // Verificar si pertenece a una categoría específica
  bool belongsToCategory(int targetCategoryId) {
    return categoryId == targetCategoryId;
  }

  // Verificar si pertenece a un usuario específico
  bool belongsToUser(int targetUserId) {
    return userId == targetUserId;
  }

  // Obtener período como string único (para índices)
  String get periodKey {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  // Actualizar monto gastado
  BudgetModel updateSpentAmount(double newSpentAmount) {
    return copyWith(spentAmount: newSpentAmount, updatedAt: DateTime.now());
  }

  // Desactivar presupuesto (soft delete)
  BudgetModel deactivate() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  // Activar presupuesto
  BudgetModel activate() {
    return copyWith(isActive: true, updatedAt: DateTime.now());
  }

  // Para debugging y logs
  @override
  String toString() {
    return 'BudgetModel(id: $id, categoryId: $categoryId, period: $month/$year, limit: $limitAmount, spent: $spentAmount)';
  }

  // Comparación de objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.month == month &&
        other.year == year &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        categoryId.hashCode ^
        month.hashCode ^
        year.hashCode ^
        userId.hashCode;
  }
}
