import '../../domain/entities/expense.dart';

class ExpenseModel {
  final int? id;
  final double amount;
  final String description;
  final int categoryId;
  final int userId;
  final DateTime expenseDate;
  final String? location;
  final String? establishment;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExpenseModel({
    this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.userId,
    required this.expenseDate,
    this.location,
    this.establishment,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // =============================================
  // CONVERSIÓN DESDE/HACIA ENTITY (DOMAIN)
  // =============================================

  // Convertir de Entity (Domain) a Model (Data)
  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      amount: entity.amount,
      description: entity.description,
      categoryId: entity.categoryId,
      userId: entity.userId,
      expenseDate: entity.expenseDate,
      location: entity.location,
      establishment: entity.establishment,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  // Convertir de Model (Data) a Entity (Domain)
  Expense toEntity() {
    return Expense(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      userId: userId,
      expenseDate: expenseDate,
      location: location,
      establishment: establishment,
      notes: notes,
      createdAt: createdAt,
    );
  }

  // =============================================
  // CONVERSIÓN DESDE/HACIA DATABASE (SQLITE)
  // =============================================

  // Convertir de Map (SQLite) a ExpenseModel
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id']?.toInt(),
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      categoryId: map['category_id']?.toInt() ?? 0,
      userId: map['user_id']?.toInt() ?? 0,
      expenseDate: DateTime.parse(map['expense_date']),
      location: map['location'],
      establishment: map['establishment'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  // Convertir de ExpenseModel a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description.trim(),
      'category_id': categoryId,
      'user_id': userId,
      'expense_date': expenseDate.toIso8601String().split(
        'T',
      )[0], // Solo fecha YYYY-MM-DD
      'location': location?.trim(),
      'establishment': establishment?.trim(),
      'notes': notes?.trim(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // =============================================
  // MÉTODOS DE UTILIDAD
  // =============================================

  // Crear una copia con campos modificados
  ExpenseModel copyWith({
    int? id,
    double? amount,
    String? description,
    int? categoryId,
    int? userId,
    DateTime? expenseDate,
    String? location,
    String? establishment,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      expenseDate: expenseDate ?? this.expenseDate,
      location: location ?? this.location,
      establishment: establishment ?? this.establishment,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validar antes de guardar en base de datos
  bool get isValidForDatabase {
    return amount > 0 && description.isNotEmpty && categoryId > 0 && userId > 0;
  }

  // Obtener map con datos esenciales para reportes
  Map<String, dynamic> toReportMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'location': location,
      'establishment': establishment,
    };
  }

  // Obtener datos para búsqueda/filtrado
  Map<String, dynamic> toSearchMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description.toLowerCase(),
      'location': location?.toLowerCase(),
      'establishment': establishment?.toLowerCase(),
      'notes': notes?.toLowerCase(),
      'expense_date': expenseDate.toIso8601String().split('T')[0],
    };
  }

  // Verificar si coincide con criterios de búsqueda
  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();

    return description.toLowerCase().contains(lowerQuery) ||
        amount.toString().contains(query) ||
        (location?.toLowerCase().contains(lowerQuery) ?? false) ||
        (establishment?.toLowerCase().contains(lowerQuery) ?? false) ||
        (notes?.toLowerCase().contains(lowerQuery) ?? false);
  }

  // Verificar si está en un rango de fechas
  bool isInDateRange(DateTime startDate, DateTime endDate) {
    final expenseDay = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return (expenseDay.isAtSameMomentAs(start) || expenseDay.isAfter(start)) &&
        (expenseDay.isAtSameMomentAs(end) || expenseDay.isBefore(end));
  }

  // Verificar si pertenece a una categoría específica
  bool belongsToCategory(int targetCategoryId) {
    return categoryId == targetCategoryId;
  }

  // Verificar si pertenece a un usuario específico
  bool belongsToUser(int targetUserId) {
    return userId == targetUserId;
  }

  // Obtener el año y mes del gasto (para agrupación)
  String get yearMonth {
    return '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';
  }

  // Obtener solo la fecha (sin hora)
  DateTime get dateOnly {
    return DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
  }

  // Para debugging y logs
  @override
  String toString() {
    return 'ExpenseModel(id: $id, amount: $amount, description: $description, date: ${expenseDate.toIso8601String().split('T')[0]})';
  }

  // Comparación de objetos
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseModel &&
        other.id == id &&
        other.amount == amount &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.userId == userId &&
        other.expenseDate == expenseDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        userId.hashCode ^
        expenseDate.hashCode;
  }
}
