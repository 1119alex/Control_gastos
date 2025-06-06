import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../aplication/providers/auth_provider.dart';
import '../../../aplication/providers/budget_provider.dart';
import '../../../aplication/providers/category_provider.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/usecases/budget_usecases.dart';
import '../../widgets/loading_widget.dart';
import 'add_budget_screen.dart';
import 'edit_budget_screen.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_hasLoadedData) return;

    try {
      print('💰 BudgetScreen: Cargando presupuestos...');
      setState(() {
        _hasLoadedData = true;
      });

      await ref.read(categoryProvider.notifier).loadCategories();
      await ref.read(budgetProvider.notifier).loadBudgets();

      print('💰 BudgetScreen: Datos cargados');
    } catch (e) {
      print('❌ BudgetScreen: Error cargando datos: $e');
      setState(() {
        _hasLoadedData = false;
      });
    }
  }

  Future<void> _reloadData() async {
    print('🔄 BudgetScreen: Recargando datos...');
    setState(() {
      _hasLoadedData = false;
    });
    await _loadData();
  }

  void _navigateToAddBudget() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddBudgetScreen(
              initialMonth: _selectedMonth,
              initialYear: _selectedYear,
            ),
          ),
        )
        .then((_) {
          _reloadData();
        });
  }

  void _navigateToEditBudget(Budget budget) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditBudgetScreen(budget: budget),
          ),
        )
        .then((_) {
          _reloadData();
        });
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirmed = await _showDeleteConfirmation(budget);
    if (confirmed == true) {
      final success = await ref
          .read(budgetProvider.notifier)
          .deleteBudget(budget.id!);

      if (success) {
        _showSuccessMessage('Presupuesto eliminado exitosamente');
        await _reloadData();
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(Budget budget) {
    final category = ref
        .read(categoryProvider.notifier)
        .getCategoryById(budget.categoryId);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: Text(
          '¿Estás seguro que quieres eliminar el presupuesto de ${category?.formattedName ?? 'esta categoría'} para ${budget.period}?',
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

  Future<void> _selectPeriod() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _PeriodPickerDialog(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result['month']!;
        _selectedYear = result['year']!;
      });
    }
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
    final budgetState = ref.watch(budgetProvider);
    final isLoadingData = budgetState.isLoading || !_hasLoadedData;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Presupuestos'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de período
          _buildPeriodSelector(),

          // Resumen del período
          if (!isLoadingData) _buildPeriodSummary(),

          // Lista de presupuestos
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadData,
              child: _buildBudgetsList(isLoadingData),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBudget,
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final monthNames = [
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

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: GestureDetector(
        onTap: _selectPeriod,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5722).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Color(0xFFFF5722),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${monthNames[_selectedMonth]} $_selectedYear',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5722),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF5722)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSummary() {
    final budgets = ref
        .read(budgetProvider.notifier)
        .getBudgetsByPeriod(_selectedMonth, _selectedYear);

    if (budgets.isEmpty) return const SizedBox.shrink();

    final user = ref.watch(currentUserProvider)!;
    final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final totalRemaining = totalLimit - totalSpent;
    final spentPercentage = totalLimit > 0
        ? (totalSpent / totalLimit) * 100
        : 0.0;

    Color progressColor;
    if (spentPercentage >= 100) {
      progressColor = const Color(0xFFE53935);
    } else if (spentPercentage >= 90) {
      progressColor = const Color(0xFFFF5722);
    } else if (spentPercentage >= 80) {
      progressColor = const Color(0xFFFF9800);
    } else {
      progressColor = const Color(0xFF4CAF50);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart, color: Color(0xFFFF5722)),
                  const SizedBox(width: 8),
                  const Text(
                    'Resumen del Período',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: spentPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Presupuestado',
                      _formatAmount(totalLimit, user.currency),
                      const Color(0xFF2196F3),
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Gastado',
                      _formatAmount(totalSpent, user.currency),
                      progressColor,
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    totalRemaining >= 0 ? 'Restante: ' : 'Excedido: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    _formatAmount(totalRemaining.abs(), user.currency),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: totalRemaining >= 0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetsList(bool isLoadingData) {
    if (isLoadingData) {
      return const LoadingWidget(message: 'Cargando presupuestos...');
    }

    final budgets = ref
        .read(budgetProvider.notifier)
        .getBudgetsByPeriod(_selectedMonth, _selectedYear);

    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay presupuestos para este período',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer presupuesto para controlar mejor tus gastos',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddBudget,
              icon: const Icon(Icons.add),
              label: const Text('Crear Presupuesto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return _buildBudgetCard(budget);
      },
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final category = ref
        .read(categoryProvider.notifier)
        .getCategoryById(budget.categoryId);
    final user = ref.watch(currentUserProvider)!;

    final categoryColor = category != null
        ? Color(int.parse(category.color.replaceFirst('#', '0xFF')))
        : Colors.grey;

    final statusColor = Color(
      int.parse(budget.statusColor.replaceFirst('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEditBudget(budget),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: categoryColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      _getIconData(category?.icon ?? 'category'),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.formattedName ?? 'Categoría desconocida',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          budget.getStatusMessage(user.currency),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _navigateToEditBudget(budget);
                          break;
                        case 'delete':
                          _deleteBudget(budget);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Color(0xFF2196F3)),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Color(0xFFE53935)),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: budget.spentPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 12),

              // Montos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gastado',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatAmount(budget.spentAmount, user.currency),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${budget.spentPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Límite',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatAmount(budget.limitAmount, user.currency),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Presupuestos'),
        content: const Text(
          'Los presupuestos te ayudan a controlar tus gastos:\n\n'
          '🟢 Verde: Vas bien (0-79%)\n'
          '🟡 Amarillo: Cuidado (80-89%)\n'
          '🟠 Naranja: Atención (90-99%)\n'
          '🔴 Rojo: Excedido (100%+)\n\n'
          'Tip: Establece presupuestos realistas basados en tus gastos anteriores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'work':
        return Icons.work;
      case 'flight':
        return Icons.flight;
      case 'pets':
        return Icons.pets;
      case 'phone':
        return Icons.phone;
      case 'computer':
        return Icons.computer;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.category;
    }
  }

  String _formatAmount(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'BOB':
        return 'Bs. ${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}

// Widget para seleccionar período
class _PeriodPickerDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;

  const _PeriodPickerDialog({
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  State<_PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends State<_PeriodPickerDialog> {
  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (index) => currentYear - 2 + index);

    return AlertDialog(
      title: const Text('Seleccionar Período'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de mes
          DropdownButtonFormField<int>(
            value: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (index) {
              final month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(_monthNames[index]),
              );
            }),
            onChanged: (value) {
              setState(() {
                _selectedMonth = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          // Selector de año
          DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
            ),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedYear = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'month': _selectedMonth,
              'year': _selectedYear,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
          ),
          child: const Text(
            'Seleccionar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
