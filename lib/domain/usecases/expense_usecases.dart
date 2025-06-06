import '../entities/expense.dart';
import '../entities/category.dart';

class ExpenseUsecases {
  ExpenseValidationResult validateExpenseCreation({
    required double amount,
    required String description,
    required DateTime date,
    required int categoryId,
    required String currency,
  }) {
    List<String> errors = [];

    // Validar monto
    if (amount <= 0) {
      errors.add('El monto debe ser mayor a 0');
    } else {
      final maxLimit = _getMaxAmountLimit(currency);
      if (amount > maxLimit) {
        errors.add(
          'El monto no puede exceder ${_formatAmount(maxLimit, currency)}',
        );
      }
    }

    // Validar descripción
    if (description.trim().isEmpty) {
      errors.add('La descripción es obligatoria');
    } else if (description.trim().length < 3) {
      errors.add('La descripción debe tener al menos 3 caracteres');
    } else if (description.trim().length > 100) {
      errors.add('La descripción no puede tener más de 100 caracteres');
    }

    // Validar fecha
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(Duration(days: 1));
    final minDate = DateTime(2020, 1, 1);

    if (date.isBefore(minDate)) {
      errors.add('La fecha no puede ser anterior al año 2020');
    } else if (date.isAfter(maxDate)) {
      errors.add('No puedes registrar gastos del futuro');
    }

    // Validar categoría
    if (categoryId <= 0) {
      errors.add('Debes seleccionar una categoría válida');
    }

    return ExpenseValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // Usecase: Crear gasto válido
  ExpenseCreationResult createExpense({
    required double amount,
    required String description,
    required int categoryId,
    required int userId,
    required DateTime date,
    required String currency,
    String? location,
    String? establishment,
    String? notes,
  }) {
    // Validar datos
    final validation = validateExpenseCreation(
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      currency: currency,
    );

    if (!validation.isValid) {
      return ExpenseCreationResult(isSuccess: false, errors: validation.errors);
    }

    // Crear el gasto
    final expense = Expense(
      amount: amount,
      description: description.trim(),
      categoryId: categoryId,
      userId: userId,
      expenseDate: date,
      location: location?.trim(),
      establishment: establishment?.trim(),
      notes: notes?.trim(),
      createdAt: DateTime.now(),
    );

    return ExpenseCreationResult(isSuccess: true, expense: expense);
  }

  // Usecase: Calcular totales por período
  ExpenseTotals calculateTotals(List<Expense> expenses, String currency) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    double todayTotal = 0;
    double weekTotal = 0;
    double monthTotal = 0;
    double yearTotal = 0;
    double allTimeTotal = 0;

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    int yearCount = 0;

    for (final expense in expenses) {
      final expenseDay = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );

      // Total general
      allTimeTotal += expense.amount;

      // Hoy
      if (expenseDay.isAtSameMomentAs(today)) {
        todayTotal += expense.amount;
        todayCount++;
      }

      // Esta semana
      if (expenseDay.isAfter(weekStart.subtract(Duration(days: 1))) &&
          expenseDay.isBefore(today.add(Duration(days: 1)))) {
        weekTotal += expense.amount;
        weekCount++;
      }

      // Este mes
      if (expense.expenseDate.year == now.year &&
          expense.expenseDate.month == now.month) {
        monthTotal += expense.amount;
        monthCount++;
      }

      // Este año
      if (expense.expenseDate.year == now.year) {
        yearTotal += expense.amount;
        yearCount++;
      }
    }

    return ExpenseTotals(
      todayTotal: todayTotal,
      weekTotal: weekTotal,
      monthTotal: monthTotal,
      yearTotal: yearTotal,
      allTimeTotal: allTimeTotal,
      todayCount: todayCount,
      weekCount: weekCount,
      monthCount: monthCount,
      yearCount: yearCount,
      totalCount: expenses.length,
      currency: currency,
    );
  }

  // Usecase: Calcular totales por categoría
  Map<int, CategoryTotal> calculateTotalsByCategory(
    List<Expense> expenses,
    List<Category> categories,
    String currency,
  ) {
    Map<int, CategoryTotal> categoryTotals = {};

    // Inicializar con todas las categorías
    for (final category in categories) {
      categoryTotals[category.id!] = CategoryTotal(
        categoryId: category.id!,
        categoryName: category.formattedName,
        total: 0,
        count: 0,
        currency: currency,
      );
    }

    // Calcular totales
    for (final expense in expenses) {
      if (categoryTotals.containsKey(expense.categoryId)) {
        final current = categoryTotals[expense.categoryId]!;
        categoryTotals[expense.categoryId] = current.copyWith(
          total: current.total + expense.amount,
          count: current.count + 1,
        );
      }
    }

    return categoryTotals;
  }

  // Usecase: Obtener gastos más grandes
  List<Expense> getLargestExpenses(
    List<Expense> expenses,
    String currency, {
    int limit = 5,
  }) {
    // Filtrar gastos grandes y ordenar por monto
    final List<Expense> largeExpenses = [];

    for (final expense in expenses) {
      if (expense.isLargeExpense) {
        largeExpenses.add(expense);
      }
    }

    // Ordenar de mayor a menor
    largeExpenses.sort((a, b) => b.amount.compareTo(a.amount));

    // Retornar solo los primeros 'limit' elementos
    if (largeExpenses.length <= limit) {
      return largeExpenses;
    } else {
      return largeExpenses.sublist(0, limit);
    }
  }

  // Usecase: Buscar gastos
  List<Expense> searchExpenses(List<Expense> expenses, String query) {
    if (query.trim().isEmpty) return expenses;

    final lowercaseQuery = query.toLowerCase().trim();

    return expenses.where((expense) {
      return expense.description.toLowerCase().contains(lowercaseQuery) ||
          expense.amount.toString().contains(query) ||
          (expense.establishment?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          (expense.location?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Usecase: Filtrar gastos por fecha
  List<Expense> filterExpensesByDate(
    List<Expense> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    return expenses.where((expense) {
      return expense.expenseDate.isAfter(
            startDate.subtract(Duration(days: 1)),
          ) &&
          expense.expenseDate.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  // Usecase: Filtrar gastos por categoría
  List<Expense> filterExpensesByCategory(
    List<Expense> expenses,
    List<int> categoryIds,
  ) {
    if (categoryIds.isEmpty) return expenses;

    return expenses.where((expense) {
      return categoryIds.contains(expense.categoryId);
    }).toList();
  }

  // Usecase: Verificar si se puede eliminar un gasto
  bool canDeleteExpense(Expense expense) {
    // No se pueden eliminar gastos de hace más de 30 días
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    return expense.expenseDate.isAfter(thirtyDaysAgo);
  }

  // Usecase: Obtener estadísticas mensuales
  MonthlyStats getMonthlyStats(
    List<Expense> expenses,
    int month,
    int year,
    String currency,
  ) {
    final monthlyExpenses = expenses.where((expense) {
      return expense.expenseDate.month == month &&
          expense.expenseDate.year == year;
    }).toList();

    if (monthlyExpenses.isEmpty) {
      return MonthlyStats.empty(month, year, currency);
    }

    // Calcular estadísticas
    final total = monthlyExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final average = total / monthlyExpenses.length;

    monthlyExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    final highest = monthlyExpenses.first.amount;
    final lowest = monthlyExpenses.last.amount;

    final largeExpensesCount = monthlyExpenses
        .where((expense) => expense.isLargeExpense)
        .length;

    return MonthlyStats(
      month: month,
      year: year,
      total: total,
      average: average,
      highest: highest,
      lowest: lowest,
      count: monthlyExpenses.length,
      largeExpensesCount: largeExpensesCount,
      currency: currency,
    );
  }

  // Métodos privados de ayuda
  double _getMaxAmountLimit(String currency) {
    const limits = {
      'BOB': 1000000.0,
      'USD': 100000.0,
      'EUR': 100000.0,
      'ARS': 50000000.0,
      'BRL': 500000.0,
      'CLP': 100000000.0,
    };
    return limits[currency.toUpperCase()] ?? 1000000.0;
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
}

// Clases de resultado y datos
class ExpenseValidationResult {
  final bool isValid;
  final List<String> errors;

  const ExpenseValidationResult({required this.isValid, required this.errors});
}

class ExpenseCreationResult {
  final bool isSuccess;
  final Expense? expense;
  final List<String> errors;

  const ExpenseCreationResult({
    required this.isSuccess,
    this.expense,
    this.errors = const [],
  });
}

class ExpenseTotals {
  final double todayTotal;
  final double weekTotal;
  final double monthTotal;
  final double yearTotal;
  final double allTimeTotal;
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final int yearCount;
  final int totalCount;
  final String currency;

  const ExpenseTotals({
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
    required this.yearTotal,
    required this.allTimeTotal,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    required this.yearCount,
    required this.totalCount,
    required this.currency,
  });
}

class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final double total;
  final int count;
  final String currency;

  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.count,
    required this.currency,
  });

  CategoryTotal copyWith({
    int? categoryId,
    String? categoryName,
    double? total,
    int? count,
    String? currency,
  }) {
    return CategoryTotal(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      total: total ?? this.total,
      count: count ?? this.count,
      currency: currency ?? this.currency,
    );
  }
}

class MonthlyStats {
  final int month;
  final int year;
  final double total;
  final double average;
  final double highest;
  final double lowest;
  final int count;
  final int largeExpensesCount;
  final String currency;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.total,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.count,
    required this.largeExpensesCount,
    required this.currency,
  });

  factory MonthlyStats.empty(int month, int year, String currency) {
    return MonthlyStats(
      month: month,
      year: year,
      total: 0,
      average: 0,
      highest: 0,
      lowest: 0,
      count: 0,
      largeExpensesCount: 0,
      currency: currency,
    );
  }
}
