import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/services/database_services.dart';
import '../../domain/entities/budget.dart';
import '../../domain/usecases/budget_usecases.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';
import 'category_provider.dart';

// Estado de presupuestos
class BudgetState {
  final List<Budget> budgets;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const BudgetState({
    this.budgets = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  BudgetState copyWith({
    List<Budget>? budgets,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasBudgets => budgets.isNotEmpty;
  int get budgetCount => budgets.length;
}

// StateNotifier para manejar presupuestos
class BudgetNotifier extends StateNotifier<BudgetState> {
  final DatabaseService _databaseService;
  final BudgetUsecases _budgetUsecases;
  final Ref _ref;

  BudgetNotifier(this._databaseService, this._budgetUsecases, this._ref)
    : super(const BudgetState());

  // Cargar presupuestos del usuario actual
  Future<void> loadBudgets() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final budgetModels = await _databaseService.getBudgetsByUser(user.id!);
      final budgets = budgetModels.map((model) => model.toEntity()).toList();

      // Actualizar montos gastados con los gastos actuales
      final expenses = _ref.read(expenseListProvider);
      final updatedBudgets = _budgetUsecases.updateBudgetsWithExpenses(
        budgets,
        expenses,
      );

      state = state.copyWith(
        budgets: updatedBudgets,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ ${updatedBudgets.length} presupuestos cargados');
    } catch (e) {
      print('❌ Error cargando presupuestos: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar presupuestos: $e',
      );
    }
  }

  // Agregar nuevo presupuesto
  Future<bool> addBudget({
    required int categoryId,
    required int month,
    required int year,
    required double limitAmount,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Verificar que no exista un presupuesto para la misma categoría y período
      final existingBudget = state.budgets
          .where(
            (budget) =>
                budget.categoryId == categoryId &&
                budget.month == month &&
                budget.year == year,
          )
          .firstOrNull;

      if (existingBudget != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Ya existe un presupuesto para esta categoría en este período',
        );
        return false;
      }

      // Crear presupuesto usando usecase
      final result = _budgetUsecases.createBudget(
        categoryId: categoryId,
        userId: user.id!,
        month: month,
        year: year,
        limitAmount: limitAmount,
        currency: user.currency,
      );

      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errors.first,
        );
        return false;
      }

      // Guardar en base de datos
      final budgetModel = BudgetModel.fromEntity(result.budget!);
      final budgetId = await _databaseService.insertBudget(budgetModel);

      // Calcular monto gastado actual
      final expenses = _ref.read(expenseListProvider);
      final spentAmount = _budgetUsecases.calculateSpentAmount(
        expenses,
        categoryId,
        month,
        year,
      );

      // Crear budget con ID y monto gastado actualizado
      final savedBudget = result.budget!
          .copyWith(id: budgetId)
          .updateSpentAmount(spentAmount);

      final updatedBudgets = [savedBudget, ...state.budgets];

      state = state.copyWith(
        budgets: updatedBudgets,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Presupuesto agregado');
      return true;
    } catch (e) {
      print('❌ Error agregando presupuesto: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar presupuesto: $e',
      );
      return false;
    }
  }

  // Actualizar presupuesto existente
  Future<bool> updateBudget({
    required int budgetId,
    double? limitAmount,
    bool? isActive,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Encontrar presupuesto actual
      final currentBudgetIndex = state.budgets.indexWhere(
        (b) => b.id == budgetId,
      );
      if (currentBudgetIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Presupuesto no encontrado',
        );
        return false;
      }

      final currentBudget = state.budgets[currentBudgetIndex];

      // Crear presupuesto actualizado
      final updatedBudget = currentBudget.copyWith(
        limitAmount: limitAmount ?? currentBudget.limitAmount,
        isActive: isActive ?? currentBudget.isActive,
        updatedAt: DateTime.now(),
      );

      // Validar presupuesto actualizado
      final user = _ref.read(currentUserProvider)!;
      final validation = _budgetUsecases.validateBudgetCreation(
        categoryId: updatedBudget.categoryId,
        month: updatedBudget.month,
        year: updatedBudget.year,
        limitAmount: updatedBudget.limitAmount,
        currency: user.currency,
      );

      if (!validation.isValid) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: validation.errors.first,
        );
        return false;
      }

      // Actualizar en base de datos
      final budgetModel = BudgetModel.fromEntity(updatedBudget);
      await _databaseService.updateBudget(budgetModel);

      // Actualizar lista local
      final updatedBudgets = List<Budget>.from(state.budgets);
      updatedBudgets[currentBudgetIndex] = updatedBudget;

      state = state.copyWith(
        budgets: updatedBudgets,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Presupuesto actualizado');
      return true;
    } catch (e) {
      print('❌ Error actualizando presupuesto: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar presupuesto: $e',
      );
      return false;
    }
  }

  // Eliminar presupuesto
  Future<bool> deleteBudget(int budgetId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Encontrar presupuesto
      final budget = state.budgets.firstWhere(
        (b) => b.id == budgetId,
        orElse: () => throw Exception('Presupuesto no encontrado'),
      );

      // Verificar si se puede eliminar
      if (!_budgetUsecases.canDeleteBudget(budget)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No se puede eliminar un presupuesto con gastos registrados',
        );
        return false;
      }

      // Eliminar de base de datos
      await _databaseService.deleteBudget(budgetId);

      // Actualizar lista local
      final updatedBudgets = state.budgets
          .where((b) => b.id != budgetId)
          .toList();

      state = state.copyWith(
        budgets: updatedBudgets,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Presupuesto eliminado');
      return true;
    } catch (e) {
      print('❌ Error eliminando presupuesto: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar presupuesto: $e',
      );
      return false;
    }
  }

  // Actualizar montos gastados desde gastos
  Future<void> updateSpentAmountsFromExpenses() async {
    try {
      final expenses = _ref.read(expenseListProvider);
      final updatedBudgets = _budgetUsecases.updateBudgetsWithExpenses(
        state.budgets,
        expenses,
      );

      // Actualizar en base de datos los montos gastados
      for (final budget in updatedBudgets) {
        if (budget.id != null) {
          final budgetModel = BudgetModel.fromEntity(budget);
          await _databaseService.updateBudgetSpentAmount(
            budget.id!,
            budget.spentAmount,
          );
        }
      }

      state = state.copyWith(
        budgets: updatedBudgets,
        lastUpdated: DateTime.now(),
      );

      print('✅ Montos gastados actualizados');
    } catch (e) {
      print('❌ Error actualizando montos gastados: $e');
    }
  }

  // Obtener presupuestos por período
  List<Budget> getBudgetsByPeriod(int month, int year) {
    return state.budgets
        .where((budget) => budget.month == month && budget.year == year)
        .toList();
  }

  // Obtener presupuestos por categoría
  List<Budget> getBudgetsByCategory(int categoryId) {
    return state.budgets
        .where((budget) => budget.categoryId == categoryId)
        .toList();
  }

  // Obtener presupuestos que necesitan atención
  List<Budget> getBudgetsNeedingAttention() {
    return _budgetUsecases.getBudgetsNeedingAttention(state.budgets);
  }

  // Calcular resumen de presupuestos
  BudgetSummary calculateBudgetSummary() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      return BudgetSummary.empty('BOB');
    }

    return _budgetUsecases.calculateBudgetSummary(state.budgets, user.currency);
  }

  // Obtener alertas de presupuesto
  List<BudgetAlert> getBudgetAlerts() {
    final categories = _ref.read(categoryListProvider);
    return _budgetUsecases.getBudgetAlerts(state.budgets, categories);
  }

  // Sugerir presupuesto basado en historial
  BudgetSuggestion suggestBudgetFromHistory(
    int categoryId,
    int month,
    int year,
  ) {
    final expenses = _ref.read(expenseListProvider);
    return _budgetUsecases.suggestBudgetFromHistory(
      expenses,
      categoryId,
      month,
      year,
    );
  }

  // Obtener progreso mensual
  BudgetProgress getMonthlyProgress(int month, int year) {
    return _budgetUsecases.getMonthlyProgress(state.budgets, month, year);
  }

  // Refrescar datos
  Future<void> refresh() async {
    await loadBudgets();
  }

  // Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider del BudgetNotifier
final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((
  ref,
) {
  return BudgetNotifier(DatabaseService(), BudgetUsecases(), ref);
});

// Providers derivados
final budgetListProvider = Provider<List<Budget>>((ref) {
  return ref.watch(budgetProvider).budgets;
});

final budgetLoadingProvider = Provider<bool>((ref) {
  return ref.watch(budgetProvider).isLoading;
});

final currentMonthBudgetsProvider = Provider<List<Budget>>((ref) {
  final now = DateTime.now();
  return ref
      .read(budgetProvider.notifier)
      .getBudgetsByPeriod(now.month, now.year);
});

final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  return ref.read(budgetProvider.notifier).calculateBudgetSummary();
});

final budgetAlertsProvider = Provider<List<BudgetAlert>>((ref) {
  return ref.read(budgetProvider.notifier).getBudgetAlerts();
});

final budgetsNeedingAttentionProvider = Provider<List<Budget>>((ref) {
  return ref.read(budgetProvider.notifier).getBudgetsNeedingAttention();
});

// Provider para presupuestos por período específico
final budgetsByPeriodProvider =
    Provider.family<List<Budget>, ({int month, int year})>((ref, params) {
      return ref
          .read(budgetProvider.notifier)
          .getBudgetsByPeriod(params.month, params.year);
    });

// Provider para progreso mensual
final monthlyProgressProvider =
    Provider.family<BudgetProgress, ({int month, int year})>((ref, params) {
      return ref
          .read(budgetProvider.notifier)
          .getMonthlyProgress(params.month, params.year);
    });

// Provider para sugerencia de presupuesto
final budgetSuggestionProvider =
    Provider.family<BudgetSuggestion, ({int categoryId, int month, int year})>((
      ref,
      params,
    ) {
      return ref
          .read(budgetProvider.notifier)
          .suggestBudgetFromHistory(
            params.categoryId,
            params.month,
            params.year,
          );
    });
