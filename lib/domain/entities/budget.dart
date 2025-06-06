class Budget {
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

  const Budget({
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

  // Regla de negocio: ¿Es un límite válido?
  bool get hasValidLimit {
    return limitAmount > 0 && limitAmount <= 1000000; // Máximo 1M
  }

  // Regla de negocio: ¿Es un presupuesto válido?
  bool get isValid {
    return hasValidLimit && month >= 1 && month <= 12 && year >= 2020;
  }

  // Regla de negocio: Porcentaje gastado
  double get spentPercentage {
    if (limitAmount <= 0) return 0.0;
    return (spentAmount / limitAmount) * 100;
  }

  // Regla de negocio: Monto restante
  double get remainingAmount {
    return limitAmount - spentAmount;
  }

  // Regla de negocio: ¿Se excedió el presupuesto?
  bool get isExceeded {
    return spentAmount > limitAmount;
  }

  // Regla de negocio: ¿Está cerca del límite? (80% o más)
  bool get isNearLimit {
    return spentPercentage >= 80;
  }

  // Regla de negocio: ¿Está en riesgo? (90% o más)
  bool get isAtRisk {
    return spentPercentage >= 90;
  }

  // Regla de negocio: Estado del presupuesto
  BudgetStatus get status {
    if (isExceeded) return BudgetStatus.exceeded;
    if (isAtRisk) return BudgetStatus.atRisk;
    if (isNearLimit) return BudgetStatus.nearLimit;
    return BudgetStatus.healthy;
  }

  // Regla de negocio: Color según el estado
  String get statusColor {
    switch (status) {
      case BudgetStatus.healthy:
        return '#4CAF50'; // Verde
      case BudgetStatus.nearLimit:
        return '#FF9800'; // Naranja
      case BudgetStatus.atRisk:
        return '#F44336'; // Rojo
      case BudgetStatus.exceeded:
        return '#D32F2F'; // Rojo oscuro
    }
  }

  // Regla de negocio: Nombre del mes
  String get monthName {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month];
  }

  // Regla de negocio: Período completo
  String get period {
    return '$monthName $year';
  }

  // Regla de negocio: ¿Es del mes actual?
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  // Regla de negocio: ¿Es del mes pasado?
  bool get isPreviousMonth {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    return month == previous.month && year == previous.year;
  }

  // Regla de negocio: Mensaje de estado
  String getStatusMessage(String currency) {
    switch (status) {
      case BudgetStatus.healthy:
        return 'Vas bien, te quedan ${_formatAmount(remainingAmount, currency)}';
      case BudgetStatus.nearLimit:
        return 'Cuidado, solo quedan ${_formatAmount(remainingAmount, currency)}';
      case BudgetStatus.atRisk:
        return '¡Atención! Quedan ${_formatAmount(remainingAmount, currency)}';
      case BudgetStatus.exceeded:
        return '¡Presupuesto excedido! ${_formatAmount(spentAmount - limitAmount, currency)} de más';
    }
  }

  // Crear copia con cambios
  Budget copyWith({
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
    return Budget(
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

  // Actualizar monto gastado
  Budget updateSpentAmount(double newSpentAmount) {
    return copyWith(spentAmount: newSpentAmount, updatedAt: DateTime.now());
  }

  String _formatAmount(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'BOB':
        return 'Bs. ${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  @override
  String toString() {
    return 'Budget(id: $id, period: $period, limit: $limitAmount, spent: $spentAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode {
    return id.hashCode ^ categoryId.hashCode ^ month.hashCode ^ year.hashCode;
  }
}

// Enum para estado del presupuesto
enum BudgetStatus {
  healthy, // 0-79%
  nearLimit, // 80-89%
  atRisk, // 90-99%
  exceeded, // 100%+
}
