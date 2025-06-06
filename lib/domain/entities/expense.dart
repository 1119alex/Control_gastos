class Expense {
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

  const Expense({
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
  });

  // Regla de negocio: ¿Es un monto válido?
  bool get hasValidAmount {
    return amount > 0 && amount < 1000000; // Límite razonable: 1M BOB
  }

  // Regla de negocio: ¿Es una descripción válida?
  bool get hasValidDescription {
    return description.trim().length >= 3;
  }

  // Regla de negocio: ¿Es una fecha válida?
  bool get hasValidDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(Duration(days: 1)); // Máximo: mañana
    final minDate = DateTime(2020, 1, 1); // Mínimo: 2020

    return expenseDate.isAfter(minDate) && expenseDate.isBefore(maxDate);
  }

  // Regla de negocio: ¿Es un gasto válido?
  bool get isValid {
    return hasValidAmount && hasValidDescription && hasValidDate;
  }

  // Regla de negocio: ¿Es un gasto grande?
  bool get isLargeExpense {
    return amount >= 500; // Más de 500 BOB es "grande"
  }

  // Regla de negocio: ¿Es un gasto de hoy?
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDay = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );
    return expenseDay.isAtSameMomentAs(today);
  }

  // Regla de negocio: ¿Es un gasto de esta semana?
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));
    return expenseDate.isAfter(weekStart) &&
        expenseDate.isBefore(weekEnd.add(Duration(days: 1)));
  }

  // Regla de negocio: ¿Es un gasto de este mes?
  bool get isThisMonth {
    final now = DateTime.now();
    return expenseDate.month == now.month && expenseDate.year == now.year;
  }

  // Regla de negocio: Descripción formateada
  String get formattedDescription {
    return description
        .trim()
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  // Regla de negocio: Monto formateado (necesita la moneda del usuario)
  String formattedAmount(String currency) {
    switch (currency.toUpperCase()) {
      case 'BOB':
        return 'Bs. ${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'ARS':
        return '\${amount.toStringAsFixed(2)} ARS';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  // Regla de negocio: Monto formateado simple (sin símbolo)
  String get simpleAmount {
    return amount.toStringAsFixed(2);
  }

  // Regla de negocio: Fecha formateada
  String get formattedDate {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${expenseDate.day} ${months[expenseDate.month]} ${expenseDate.year}';
  }

  // Regla de negocio: Obtener el mes y año
  String get monthYear {
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

    return '${months[expenseDate.month]} ${expenseDate.year}';
  }

  // Regla de negocio: Prioridad del gasto (para ordenamiento)
  int get priority {
    if (isToday) return 3;
    if (isThisWeek) return 2;
    if (isThisMonth) return 1;
    return 0;
  }

  // Crear copia con cambios
  Expense copyWith({
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
  }) {
    return Expense(
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
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $formattedAmount, description: $formattedDescription)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.amount == amount &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        userId.hashCode;
  }
}
