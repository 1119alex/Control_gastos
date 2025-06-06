import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/database_services.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/expense_usecases.dart';
import 'auth_provider.dart';
import 'category_provider.dart';

// Estado de gastos
class ExpenseState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasExpenses => expenses.isNotEmpty;
  int get expenseCount => expenses.length;
}

// StateNotifier para manejar gastos
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final DatabaseService _databaseService;
  final ExpenseUsecases _expenseUsecases;
  final Ref _ref;

  ExpenseNotifier(this._databaseService, this._expenseUsecases, this._ref)
    : super(const ExpenseState());

  // Cargar gastos del usuario actual
  Future<void> loadExpenses() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final expenseModels = await _databaseService.getExpensesByUser(user.id!);
      final expenses = expenseModels.map((model) => model.toEntity()).toList();

      state = state.copyWith(
        expenses: expenses,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ ${expenses.length} gastos cargados');
    } catch (e) {
      print('❌ Error cargando gastos: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar gastos: $e',
      );
    }
  }

  // Agregar nuevo gasto
  Future<bool> addExpense({
    required double amount,
    required String description,
    required int categoryId,
    required DateTime date,
    String? location,
    String? establishment,
    String? notes,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Crear gasto usando usecase
      final result = _expenseUsecases.createExpense(
        amount: amount,
        description: description,
        categoryId: categoryId,
        userId: user.id!,
        date: date,
        currency: user.currency,
        location: location,
        establishment: establishment,
        notes: notes,
      );

      if (!result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errors.first,
        );
        return false;
      }

      // Guardar en base de datos
      final expenseModel = ExpenseModel.fromEntity(result.expense!);
      final expenseId = await _databaseService.insertExpense(expenseModel);

      // Crear expense con ID y agregarlo a la lista
      final savedExpense = result.expense!.copyWith(id: expenseId);
      final updatedExpenses = [savedExpense, ...state.expenses];

      state = state.copyWith(
        expenses: updatedExpenses,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Gasto agregado: $description');
      return true;
    } catch (e) {
      print('❌ Error agregando gasto: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar gasto: $e',
      );
      return false;
    }
  }

  // Actualizar gasto existente
  Future<bool> updateExpense({
    required int expenseId,
    double? amount,
    String? description,
    int? categoryId,
    DateTime? date,
    String? location,
    String? establishment,
    String? notes,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Encontrar gasto actual
      final currentExpenseIndex = state.expenses.indexWhere(
        (e) => e.id == expenseId,
      );
      if (currentExpenseIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gasto no encontrado',
        );
        return false;
      }

      final currentExpense = state.expenses[currentExpenseIndex];

      // Crear gasto actualizado
      final updatedExpense = currentExpense.copyWith(
        amount: amount ?? currentExpense.amount,
        description: description ?? currentExpense.description,
        categoryId: categoryId ?? currentExpense.categoryId,
        expenseDate: date ?? currentExpense.expenseDate,
        location: location ?? currentExpense.location,
        establishment: establishment ?? currentExpense.establishment,
        notes: notes ?? currentExpense.notes,
      );

      // Validar con usecase
      final validation = _expenseUsecases.validateExpenseCreation(
        amount: updatedExpense.amount,
        description: updatedExpense.description,
        date: updatedExpense.expenseDate,
        categoryId: updatedExpense.categoryId,
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
      final expenseModel = ExpenseModel.fromEntity(updatedExpense);
      await _databaseService.updateExpense(expenseModel);

      // Actualizar lista local
      final updatedExpenses = List<Expense>.from(state.expenses);
      updatedExpenses[currentExpenseIndex] = updatedExpense;

      state = state.copyWith(
        expenses: updatedExpenses,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Gasto actualizado: ${updatedExpense.description}');
      return true;
    } catch (e) {
      print('❌ Error actualizando gasto: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar gasto: $e',
      );
      return false;
    }
  }

  // Eliminar gasto
  Future<bool> deleteExpense(int expenseId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Encontrar gasto
      final expense = state.expenses.firstWhere(
        (e) => e.id == expenseId,
        orElse: () => throw Exception('Gasto no encontrado'),
      );

      // Verificar si se puede eliminar
      if (!_expenseUsecases.canDeleteExpense(expense)) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pueden eliminar gastos de más de 30 días',
        );
        return false;
      }

      // Eliminar de base de datos
      await _databaseService.deleteExpense(expenseId);

      // Actualizar lista local
      final updatedExpenses = state.expenses
          .where((e) => e.id != expenseId)
          .toList();

      state = state.copyWith(
        expenses: updatedExpenses,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Gasto eliminado: ${expense.description}');
      return true;
    } catch (e) {
      print('❌ Error eliminando gasto: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar gasto: $e',
      );
      return false;
    }
  }

  // Buscar gastos
  List<Expense> searchExpenses(String query) {
    return _expenseUsecases.searchExpenses(state.expenses, query);
  }

  // Filtrar gastos por categoría
  List<Expense> filterByCategory(List<int> categoryIds) {
    return _expenseUsecases.filterExpensesByCategory(
      state.expenses,
      categoryIds,
    );
  }

  // Filtrar gastos por fecha
  List<Expense> filterByDateRange(DateTime startDate, DateTime endDate) {
    return _expenseUsecases.filterExpensesByDate(
      state.expenses,
      startDate,
      endDate,
    );
  }

  // Obtener gastos más grandes
  List<Expense> getLargestExpenses({int limit = 5}) {
    final user = _ref.read(currentUserProvider);
    if (user == null) return [];

    return _expenseUsecases.getLargestExpenses(
      state.expenses,
      user.currency,
      limit: limit,
    );
  }

  // Calcular totales
  ExpenseTotals calculateTotals() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      return const ExpenseTotals(
        todayTotal: 0,
        weekTotal: 0,
        monthTotal: 0,
        yearTotal: 0,
        allTimeTotal: 0,
        todayCount: 0,
        weekCount: 0,
        monthCount: 0,
        yearCount: 0,
        totalCount: 0,
        currency: 'BOB',
      );
    }

    return _expenseUsecases.calculateTotals(state.expenses, user.currency);
  }

  // Calcular totales por categoría
  Map<int, CategoryTotal> calculateTotalsByCategory() {
    final user = _ref.read(currentUserProvider);
    final categories = _ref.read(categoryProvider).categories;

    if (user == null) return {};

    return _expenseUsecases.calculateTotalsByCategory(
      state.expenses,
      categories,
      user.currency,
    );
  }

  // Obtener estadísticas mensuales
  MonthlyStats getMonthlyStats(int month, int year) {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      return MonthlyStats.empty(month, year, 'BOB');
    }

    return _expenseUsecases.getMonthlyStats(
      state.expenses,
      month,
      year,
      user.currency,
    );
  }

  // Refrescar datos
  Future<void> refresh() async {
    await loadExpenses();
  }

  // Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider del ExpenseNotifier
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((
  ref,
) {
  return ExpenseNotifier(DatabaseService(), ExpenseUsecases(), ref);
});

// Providers derivados
final expenseListProvider = Provider<List<Expense>>((ref) {
  return ref.watch(expenseProvider).expenses;
});

final expenseLoadingProvider = Provider<bool>((ref) {
  return ref.watch(expenseProvider).isLoading;
});

final expenseTotalsProvider = Provider<ExpenseTotals>((ref) {
  return ref.read(expenseProvider.notifier).calculateTotals();
});

final monthlyStatsProvider =
    Provider.family<MonthlyStats, ({int month, int year})>((ref, params) {
      return ref
          .read(expenseProvider.notifier)
          .getMonthlyStats(params.month, params.year);
    });

final largestExpensesProvider = Provider.family<List<Expense>, int>((
  ref,
  limit,
) {
  return ref.read(expenseProvider.notifier).getLargestExpenses(limit: limit);
});

// Provider para gastos filtrados por búsqueda
final searchedExpensesProvider = Provider.family<List<Expense>, String>((
  ref,
  query,
) {
  return ref.read(expenseProvider.notifier).searchExpenses(query);
});

// Provider para gastos del mes actual
final currentMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseListProvider);
  final now = DateTime.now();

  return expenses.where((expense) {
    return expense.expenseDate.month == now.month &&
        expense.expenseDate.year == now.year;
  }).toList();
});

// Provider para gastos de hoy
final todayExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expenseListProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return expenses.where((expense) {
    final expenseDay = DateTime(
      expense.expenseDate.year,
      expense.expenseDate.month,
      expense.expenseDate.day,
    );
    return expenseDay.isAtSameMomentAs(today);
  }).toList();
});
