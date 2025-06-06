import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';
import '../widgets/receipt_image_widget.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();

  // Filtros
  List<Category> _selectedCategories = [];
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;
  ExpenseSortType _sortType = ExpenseSortType.dateDesc;

  // Estado
  List<Expense> _filteredExpenses = [];
  bool _showFilters = false;
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    print('📋 ExpenseListScreen: initState called');

    // Cargar datos inmediatamente después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_hasLoadedInitialData) return;

    print('📋 ExpenseListScreen: Iniciando carga inicial de datos...');

    try {
      // Mostrar que estamos cargando
      setState(() {
        _hasLoadedInitialData = true;
      });

      // Cargar datos de forma secuencial para evitar conflictos
      await ref.read(categoryProvider.notifier).loadCategories();
      await ref.read(expenseProvider.notifier).loadExpenses();

      print('📋 ExpenseListScreen: Datos cargados, aplicando filtros...');

      // Aplicar filtros después de cargar
      if (mounted) {
        _applyFilters();
      }

      print('📋 ExpenseListScreen: Carga inicial completada');
    } catch (e) {
      print('❌ ExpenseListScreen: Error cargando datos iniciales: $e');

      // En caso de error, permitir reintento
      if (mounted) {
        setState(() {
          _hasLoadedInitialData = false;
        });
      }
    }
  }

  void _applyFilters() {
    final allExpenses = ref.read(expenseListProvider);
    final searchQuery = _searchController.text.toLowerCase().trim();

    print('📋 Aplicando filtros. Total gastos: ${allExpenses.length}');

    List<Expense> filtered = List.from(allExpenses);

    // Filtro de búsqueda
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.description.toLowerCase().contains(searchQuery) ||
            expense.establishment?.toLowerCase().contains(searchQuery) ==
                true ||
            expense.location?.toLowerCase().contains(searchQuery) == true ||
            expense.notes?.toLowerCase().contains(searchQuery) == true ||
            expense.amount.toString().contains(searchQuery);
      }).toList();
    }

    // Filtro por categorías
    if (_selectedCategories.isNotEmpty) {
      final categoryIds = _selectedCategories.map((c) => c.id!).toSet();
      filtered = filtered.where((expense) {
        return categoryIds.contains(expense.categoryId);
      }).toList();
    }

    // Filtro por rango de fechas
    if (_selectedDateRange != null) {
      filtered = filtered.where((expense) {
        final expenseDate = expense.expenseDate;
        return expenseDate.isAfter(
              _selectedDateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            expenseDate.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    // Filtro por monto
    if (_minAmount != null) {
      filtered = filtered
          .where((expense) => expense.amount >= _minAmount!)
          .toList();
    }
    if (_maxAmount != null) {
      filtered = filtered
          .where((expense) => expense.amount <= _maxAmount!)
          .toList();
    }

    // Ordenamiento
    switch (_sortType) {
      case ExpenseSortType.dateDesc:
        filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
        break;
      case ExpenseSortType.dateAsc:
        filtered.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        break;
      case ExpenseSortType.amountDesc:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSortType.amountAsc:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case ExpenseSortType.categoryName:
        filtered.sort((a, b) {
          final categoryA = ref
              .read(categoryProvider.notifier)
              .getCategoryById(a.categoryId);
          final categoryB = ref
              .read(categoryProvider.notifier)
              .getCategoryById(b.categoryId);
          return (categoryA?.name ?? '').compareTo(categoryB?.name ?? '');
        });
        break;
    }

    print('📋 Filtros aplicados. Gastos filtrados: ${filtered.length}');

    if (mounted) {
      setState(() {
        _filteredExpenses = filtered;
      });
    }
  }

  Future<void> _reloadData() async {
    print('🔄 ExpenseListScreen: Recargando datos...');

    setState(() {
      _hasLoadedInitialData = false;
    });

    await _loadInitialData();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    _applyFilters();
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CategoryFilterBottomSheet(
        selectedCategories: _selectedCategories,
        onSelectionChanged: (categories) {
          setState(() {
            _selectedCategories = categories;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _showAmountFilter() {
    showDialog(
      context: context,
      builder: (context) => _AmountFilterDialog(
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        onAmountChanged: (min, max) {
          setState(() {
            _minAmount = min;
            _maxAmount = max;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedDateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await _showDeleteConfirmation(expense);
    if (confirmed == true) {
      final success = await ref
          .read(expenseProvider.notifier)
          .deleteExpense(expense.id!);
      if (success) {
        _showSuccessMessage('Gasto eliminado exitosamente');
        // Recargar datos después de eliminar
        await _reloadData();
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(Expense expense) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro que quieres eliminar "${expense.formattedDescription}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditExpense(Expense expense) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditExpenseScreen(expense: expense),
          ),
        )
        .then((_) {
          // Recargar después de editar
          _reloadData();
        });
  }

  void _navigateToAddExpense() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddExpenseScreen()))
        .then((_) {
          // Recargar después de agregar
          _reloadData();
        });
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ExpenseDetailsBottomSheet(
        expense: expense,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEditExpense(expense);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteExpense(expense);
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final expenseState = ref.watch(expenseProvider);
    final isLoadingData = expenseState.isLoading || !_hasLoadedInitialData;

    // Escuchar cambios en los gastos y aplicar filtros automáticamente
    ref.listen<List<Expense>>(expenseListProvider, (previous, next) {
      if (_hasLoadedInitialData && mounted) {
        print('📋 Gastos actualizados, reaplicando filtros...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyFilters();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          PopupMenuButton<ExpenseSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (sortType) {
              setState(() {
                _sortType = sortType;
              });
              _applyFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ExpenseSortType.dateDesc,
                child: Text('Fecha (más reciente)'),
              ),
              const PopupMenuItem(
                value: ExpenseSortType.dateAsc,
                child: Text('Fecha (más antigua)'),
              ),
              const PopupMenuItem(
                value: ExpenseSortType.amountDesc,
                child: Text('Monto (mayor)'),
              ),
              const PopupMenuItem(
                value: ExpenseSortType.amountAsc,
                child: Text('Monto (menor)'),
              ),
              const PopupMenuItem(
                value: ExpenseSortType.categoryName,
                child: Text('Categoría'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SearchTextField(
              controller: _searchController,
              hintText: 'Buscar gastos...',
              onChanged: (_) => _applyFilters(),
              onClear: () => _applyFilters(),
            ),
          ),

          // Filtros expandibles
          if (_showFilters) _buildFiltersSection(),

          // Resumen de filtros activos
          if (_hasActiveFilters()) _buildActiveFiltersChips(),

          // Lista de gastos
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadData,
              child: _buildExpensesList(user, isLoadingData),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCategoryFilter,
                  icon: const Icon(Icons.category, size: 16),
                  label: Text(
                    _selectedCategories.isEmpty
                        ? 'Categorías'
                        : '${_selectedCategories.length} seleccionadas',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCategories.isEmpty
                        ? Colors.grey[100]
                        : const Color(0xFF2196F3),
                    foregroundColor: _selectedCategories.isEmpty
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Fechas'
                        : 'Rango seleccionado',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedDateRange == null
                        ? Colors.grey[100]
                        : const Color(0xFF2196F3),
                    foregroundColor: _selectedDateRange == null
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAmountFilter,
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: Text(
                    (_minAmount != null || _maxAmount != null)
                        ? 'Monto filtrado'
                        : 'Monto',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_minAmount != null || _maxAmount != null)
                        ? const Color(0xFF2196F3)
                        : Colors.grey[100],
                    foregroundColor: (_minAmount != null || _maxAmount != null)
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Limpiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategories.isNotEmpty ||
        _selectedDateRange != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _searchController.text.isNotEmpty;
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_searchController.text.isNotEmpty)
            Chip(
              label: Text('Búsqueda: "${_searchController.text}"'),
              onDeleted: () {
                _searchController.clear();
                _applyFilters();
              },
            ),
          if (_selectedCategories.isNotEmpty)
            Chip(
              label: Text('${_selectedCategories.length} categorías'),
              onDeleted: () {
                setState(() {
                  _selectedCategories.clear();
                });
                _applyFilters();
              },
            ),
          if (_selectedDateRange != null)
            Chip(
              label: Text(
                '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - '
                '${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
              ),
              onDeleted: _clearDateRange,
            ),
          if (_minAmount != null || _maxAmount != null)
            Chip(
              label: Text(
                'Monto: ${_minAmount != null ? 'min ${_minAmount!.toStringAsFixed(0)}' : ''}'
                '${_minAmount != null && _maxAmount != null ? ' - ' : ''}'
                '${_maxAmount != null ? 'max ${_maxAmount!.toStringAsFixed(0)}' : ''}',
              ),
              onDeleted: () {
                setState(() {
                  _minAmount = null;
                  _maxAmount = null;
                });
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(user, bool isLoadingData) {
    // Mostrar loading durante la carga inicial
    if (isLoadingData) {
      return const LoadingWidget(message: 'Cargando gastos...');
    }

    // Mostrar mensaje si no hay gastos
    if (_filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'No se encontraron gastos con los filtros aplicados'
                  : 'No hay gastos registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Intenta cambiar los filtros o agregar nuevos gastos'
                  : 'Comienza agregando tu primer gasto',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_hasActiveFilters())
              ElevatedButton(
                onPressed: _clearAllFilters,
                child: const Text('Limpiar filtros'),
              )
            else
              ElevatedButton(
                onPressed: _navigateToAddExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar primer gasto'),
              ),
          ],
        ),
      );
    }

    // Mostrar lista de gastos
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = _filteredExpenses[index];
        final category = ref
            .read(categoryProvider.notifier)
            .getCategoryById(expense.categoryId);

        return _buildExpenseCard(expense, category, user);
      },
    );
  }

  Widget _buildExpenseCard(Expense expense, Category? category, user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Indicador de categoría
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category != null
                          ? Color(
                              int.parse(
                                category.color.replaceFirst('#', '0xFF'),
                              ),
                            )
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.formattedDescription,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category?.formattedName ?? 'Sin categoría',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expense.formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Monto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        expense.formattedAmount(user?.currency ?? 'BOB'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      if (expense.establishment?.isNotEmpty == true)
                        Text(
                          expense.establishment!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Información adicional
              if (expense.location?.isNotEmpty == true ||
                  expense.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                if (expense.location?.isNotEmpty == true)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          expense.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (expense.notes?.isNotEmpty == true)
                  Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          expense.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Enum para tipos de ordenamiento
enum ExpenseSortType { dateDesc, dateAsc, amountDesc, amountAsc, categoryName }

// Widget para filtro de categorías
class _CategoryFilterBottomSheet extends ConsumerWidget {
  final List<Category> selectedCategories;
  final Function(List<Category>) onSelectionChanged;

  const _CategoryFilterBottomSheet({
    required this.selectedCategories,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtrar por Categorías',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategories.any(
                  (c) => c.id == category.id,
                );

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    List<Category> newSelection = List.from(selectedCategories);
                    if (selected == true) {
                      newSelection.add(category);
                    } else {
                      newSelection.removeWhere((c) => c.id == category.id);
                    }
                    onSelectionChanged(newSelection);
                  },
                  title: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(category.color.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(category.formattedName),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    onSelectionChanged([]);
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget para filtro de montos
class _AmountFilterDialog extends StatefulWidget {
  final double? minAmount;
  final double? maxAmount;
  final Function(double?, double?) onAmountChanged;

  const _AmountFilterDialog({
    required this.minAmount,
    required this.maxAmount,
    required this.onAmountChanged,
  });

  @override
  State<_AmountFilterDialog> createState() => _AmountFilterDialogState();
}

class _AmountFilterDialogState extends State<_AmountFilterDialog> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.minAmount != null) {
      _minController.text = widget.minAmount!.toStringAsFixed(0);
    }
    if (widget.maxAmount != null) {
      _maxController.text = widget.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar por Monto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _minController,
            label: 'Monto mínimo',
            hintText: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.arrow_upward,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _maxController,
            label: 'Monto máximo',
            hintText: 'Sin límite',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.arrow_downward,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onAmountChanged(null, null);
            Navigator.pop(context);
          },
          child: const Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final min = _minController.text.isEmpty
                ? null
                : double.tryParse(_minController.text);
            final max = _maxController.text.isEmpty
                ? null
                : double.tryParse(_maxController.text);

            widget.onAmountChanged(min, max);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
          ),
          child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Widget para detalles del gasto
class _ExpenseDetailsBottomSheet extends ConsumerWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseDetailsBottomSheet({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref
        .read(categoryProvider.notifier)
        .getCategoryById(expense.categoryId);
    final user = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  expense.formattedDescription,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                expense.formattedAmount(user?.currency ?? 'BOB'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Detalles
          _buildDetailRow(
            Icons.category,
            'Categoría',
            category?.formattedName ?? 'Sin categoría',
          ),
          _buildDetailRow(Icons.calendar_today, 'Fecha', expense.formattedDate),

          if (expense.establishment?.isNotEmpty == true)
            _buildDetailRow(
              Icons.store,
              'Establecimiento',
              expense.establishment!,
            ),

          if (expense.location?.isNotEmpty == true)
            _buildDetailRow(Icons.location_on, 'Ubicación', expense.location!),

          if (expense.notes?.isNotEmpty == true)
            _buildDetailRow(Icons.note, 'Notas', expense.notes!),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
