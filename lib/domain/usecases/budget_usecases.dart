import '../entities/budget.dart';
import '../entities/expense.dart';
import '../entities/category.dart';

class BudgetUsecases {
  BudgetValidationResult validateBudgetCreation({
    required int categoryId,
    required int month,
    required int year,
    required double limitAmount,
    required String currency,
  }) {
    List<String> errors = [];

    // Validar categoría
    if (categoryId <= 0) {
      errors.add('Debes seleccionar una categoría válida');
    }

    // Validar mes
    if (month < 1 || month > 12) {
      errors.add('El mes debe estar entre 1 y 12');
    }

    // Validar año
    final currentYear = DateTime.now().year;
    if (year < 2020 || year > currentYear + 5) {
      errors.add('El año debe estar entre 2020 y ${currentYear + 5}');
    }

    // Validar monto límite
    if (limitAmount <= 0) {
      errors.add('El límite debe ser mayor a 0');
    } else {
      final maxLimit = _getMaxBudgetLimit(currency);
      if (limitAmount > maxLimit) {
        errors.add(
          'El límite no puede exceder ${_formatAmount(maxLimit, currency)}',
        );
      }
    }

    return BudgetValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // Usecase: Crear presupuesto válido
  BudgetCreationResult createBudget({
    required int categoryId,
    required int userId,
    required int month,
    required int year,
    required double limitAmount,
    required String currency,
  }) {
    // Validar datos
    final validation = validateBudgetCreation(
      categoryId: categoryId,
      month: month,
      year: year,
      limitAmount: limitAmount,
      currency: currency,
    );

    if (!validation.isValid) {
      return BudgetCreationResult(isSuccess: false, errors: validation.errors);
    }

    // Crear el presupuesto
    final budget = Budget(
      categoryId: categoryId,
      userId: userId,
      month: month,
      year: year,
      limitAmount: limitAmount,
      createdAt: DateTime.now(),
    );

    return BudgetCreationResult(isSuccess: true, budget: budget);
  }

  // Usecase: Calcular monto gastado para un presupuesto
  double calculateSpentAmount(
    List<Expense> expenses,
    int categoryId,
    int month,
    int year,
  ) {
    return expenses
        .where(
          (expense) =>
              expense.categoryId == categoryId &&
              expense.expenseDate.month == month &&
              expense.expenseDate.year == year,
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Usecase: Actualizar presupuestos con gastos
  List<Budget> updateBudgetsWithExpenses(
    List<Budget> budgets,
    List<Expense> expenses,
  ) {
    return budgets.map((budget) {
      final spentAmount = calculateSpentAmount(
        expenses,
        budget.categoryId,
        budget.month,
        budget.year,
      );
      return budget.updateSpentAmount(spentAmount);
    }).toList();
  }

  // Usecase: Obtener presupuestos por estado
  Map<BudgetStatus, List<Budget>> groupBudgetsByStatus(List<Budget> budgets) {
    final Map<BudgetStatus, List<Budget>> grouped = {
      BudgetStatus.healthy: [],
      BudgetStatus.nearLimit: [],
      BudgetStatus.atRisk: [],
      BudgetStatus.exceeded: [],
    };

    for (final budget in budgets) {
      grouped[budget.status]!.add(budget);
    }

    return grouped;
  }

  // Usecase: Obtener presupuestos que necesitan atención
  List<Budget> getBudgetsNeedingAttention(List<Budget> budgets) {
    return budgets
        .where(
          (budget) =>
              budget.status == BudgetStatus.atRisk ||
              budget.status == BudgetStatus.exceeded,
        )
        .toList();
  }

  // Usecase: Calcular total de presupuestos
  BudgetSummary calculateBudgetSummary(List<Budget> budgets, String currency) {
    if (budgets.isEmpty) {
      return BudgetSummary.empty(currency);
    }

    double totalLimit = 0;
    double totalSpent = 0;
    int exceededCount = 0;
    int atRiskCount = 0;
    int healthyCount = 0;

    for (final budget in budgets) {
      totalLimit += budget.limitAmount;
      totalSpent += budget.spentAmount;

      switch (budget.status) {
        case BudgetStatus.exceeded:
          exceededCount++;
          break;
        case BudgetStatus.atRisk:
          atRiskCount++;
          break;
        case BudgetStatus.nearLimit:
          atRiskCount++; // Consideramos nearLimit como atRisk también
          break;
        case BudgetStatus.healthy:
          healthyCount++;
          break;
      }
    }

    return BudgetSummary(
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      totalRemaining: totalLimit - totalSpent,
      totalBudgets: budgets.length,
      exceededCount: exceededCount,
      atRiskCount: atRiskCount,
      healthyCount: healthyCount,
      currency: currency,
    );
  }

  // Usecase: Sugerir presupuesto basado en gastos anteriores
  BudgetSuggestion suggestBudgetFromHistory(
    List<Expense> historicalExpenses,
    int categoryId,
    int targetMonth,
    int targetYear,
  ) {
    // Obtener gastos de los últimos 3 meses de la misma categoría
    final now = DateTime.now();
    final List<double> monthlySpending = [];

    for (int i = 1; i <= 3; i++) {
      final checkDate = DateTime(now.year, now.month - i);
      final monthSpent = historicalExpenses
          .where(
            (expense) =>
                expense.categoryId == categoryId &&
                expense.expenseDate.month == checkDate.month &&
                expense.expenseDate.year == checkDate.year,
          )
          .fold(0.0, (sum, expense) => sum + expense.amount);

      if (monthSpent > 0) {
        monthlySpending.add(monthSpent);
      }
    }

    if (monthlySpending.isEmpty) {
      return BudgetSuggestion(
        suggestedAmount: 0,
        confidence: BudgetConfidence.noData,
        reasoning: 'No hay datos históricos para esta categoría',
      );
    }

    // Calcular promedio y sugerir 20% más
    final average =
        monthlySpending.reduce((a, b) => a + b) / monthlySpending.length;
    final suggested = average * 1.2; // 20% más que el promedio

    BudgetConfidence confidence;
    if (monthlySpending.length >= 3) {
      confidence = BudgetConfidence.high;
    } else if (monthlySpending.length >= 2) {
      confidence = BudgetConfidence.medium;
    } else {
      confidence = BudgetConfidence.low;
    }

    return BudgetSuggestion(
      suggestedAmount: suggested,
      confidence: confidence,
      reasoning:
          'Basado en promedio de ${monthlySpending.length} mes(es) anterior(es) + 20%',
      historicalData: monthlySpending,
    );
  }

  // Usecase: Obtener alertas de presupuesto
  List<BudgetAlert> getBudgetAlerts(
    List<Budget> budgets,
    List<Category> categories,
  ) {
    List<BudgetAlert> alerts = [];

    for (final budget in budgets) {
      final category = categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => Category(
          name: 'Categoría desconocida',
          userId: budget.userId,
          createdAt: DateTime.now(),
        ),
      );

      switch (budget.status) {
        case BudgetStatus.exceeded:
          alerts.add(
            BudgetAlert(
              type: BudgetAlertType.exceeded,
              budget: budget,
              categoryName: category.formattedName,
              message:
                  'Has excedido el presupuesto de ${category.formattedName}',
              priority: BudgetAlertPriority.high,
            ),
          );
          break;
        case BudgetStatus.atRisk:
          alerts.add(
            BudgetAlert(
              type: BudgetAlertType.atRisk,
              budget: budget,
              categoryName: category.formattedName,
              message: 'Estás cerca del límite en ${category.formattedName}',
              priority: BudgetAlertPriority.medium,
            ),
          );
          break;
        case BudgetStatus.nearLimit:
          alerts.add(
            BudgetAlert(
              type: BudgetAlertType.nearLimit,
              budget: budget,
              categoryName: category.formattedName,
              message: 'Cuidado con el gasto en ${category.formattedName}',
              priority: BudgetAlertPriority.low,
            ),
          );
          break;
        case BudgetStatus.healthy:
          // No genera alertas
          break;
      }
    }

    // Ordenar por prioridad
    alerts.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return alerts;
  }

  // Usecase: Verificar si se puede eliminar un presupuesto
  bool canDeleteBudget(Budget budget) {
    // No se pueden eliminar presupuestos con gastos registrados
    return budget.spentAmount == 0;
  }

  // Usecase: Obtener progreso mensual
  BudgetProgress getMonthlyProgress(List<Budget> budgets, int month, int year) {
    final monthlyBudgets = budgets
        .where((b) => b.month == month && b.year == year)
        .toList();

    if (monthlyBudgets.isEmpty) {
      return BudgetProgress.empty(month, year);
    }

    final totalLimit = monthlyBudgets.fold(
      0.0,
      (sum, budget) => sum + budget.limitAmount,
    );
    final totalSpent = monthlyBudgets.fold(
      0.0,
      (sum, budget) => sum + budget.spentAmount,
    );

    return BudgetProgress(
      month: month,
      year: year,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      budgetCount: monthlyBudgets.length,
      exceededBudgets: monthlyBudgets.where((b) => b.isExceeded).length,
    );
  }

  // Métodos privados de ayuda
  double _getMaxBudgetLimit(String currency) {
    const limits = {
      'BOB': 100000.0, // 100k BOB
      'USD': 10000.0, // 10k USD
      'EUR': 10000.0, // 10k EUR
      'ARS': 5000000.0, // 5M ARS
      'BRL': 50000.0, // 50k BRL
      'CLP': 10000000.0, // 10M CLP
    };
    return limits[currency.toUpperCase()] ?? 100000.0;
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
class BudgetValidationResult {
  final bool isValid;
  final List<String> errors;

  const BudgetValidationResult({required this.isValid, required this.errors});
}

class BudgetCreationResult {
  final bool isSuccess;
  final Budget? budget;
  final List<String> errors;

  const BudgetCreationResult({
    required this.isSuccess,
    this.budget,
    this.errors = const [],
  });
}

class BudgetSummary {
  final double totalLimit;
  final double totalSpent;
  final double totalRemaining;
  final int totalBudgets;
  final int exceededCount;
  final int atRiskCount;
  final int healthyCount;
  final String currency;

  const BudgetSummary({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.totalBudgets,
    required this.exceededCount,
    required this.atRiskCount,
    required this.healthyCount,
    required this.currency,
  });

  factory BudgetSummary.empty(String currency) {
    return BudgetSummary(
      totalLimit: 0,
      totalSpent: 0,
      totalRemaining: 0,
      totalBudgets: 0,
      exceededCount: 0,
      atRiskCount: 0,
      healthyCount: 0,
      currency: currency,
    );
  }

  double get spentPercentage {
    if (totalLimit <= 0) return 0.0;
    return (totalSpent / totalLimit) * 100;
  }
}

class BudgetSuggestion {
  final double suggestedAmount;
  final BudgetConfidence confidence;
  final String reasoning;
  final List<double> historicalData;

  const BudgetSuggestion({
    required this.suggestedAmount,
    required this.confidence,
    required this.reasoning,
    this.historicalData = const [],
  });
}

class BudgetAlert {
  final BudgetAlertType type;
  final Budget budget;
  final String categoryName;
  final String message;
  final BudgetAlertPriority priority;

  const BudgetAlert({
    required this.type,
    required this.budget,
    required this.categoryName,
    required this.message,
    required this.priority,
  });
}

class BudgetProgress {
  final int month;
  final int year;
  final double totalLimit;
  final double totalSpent;
  final int budgetCount;
  final int exceededBudgets;

  const BudgetProgress({
    required this.month,
    required this.year,
    required this.totalLimit,
    required this.totalSpent,
    required this.budgetCount,
    required this.exceededBudgets,
  });

  factory BudgetProgress.empty(int month, int year) {
    return BudgetProgress(
      month: month,
      year: year,
      totalLimit: 0,
      totalSpent: 0,
      budgetCount: 0,
      exceededBudgets: 0,
    );
  }

  double get spentPercentage {
    if (totalLimit <= 0) return 0.0;
    return (totalSpent / totalLimit) * 100;
  }

  double get remainingAmount => totalLimit - totalSpent;
}

// Enums
enum BudgetConfidence { noData, low, medium, high }

enum BudgetAlertType { nearLimit, atRisk, exceeded }

enum BudgetAlertPriority { low, medium, high }
