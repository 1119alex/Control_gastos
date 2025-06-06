import 'package:control_gastos/presentation/screens/category_management/category_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../widgets/loading_widget.dart';
import 'login_screen.dart';
import 'add_expense_screen.dart';
import 'expense_list_screen.dart';
import '../../aplication/providers/budget_provider.dart';
import '../../domain/usecases/budget_usecases.dart';
import '../screens/budget_managet/budget_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_hasLoadedInitialData) return;

    try {
      print('📊 Dashboard: Iniciando carga de datos...');

      setState(() {
        _hasLoadedInitialData = true;
      });
      await ref.read(categoryProvider.notifier).loadCategories();
      await ref.read(expenseProvider.notifier).loadExpenses();
      await ref.read(budgetProvider.notifier).loadBudgets();
      print('📊 Dashboard: Datos cargados exitosamente');
    } catch (e) {
      print('❌ Dashboard: Error cargando datos iniciales: $e');
      setState(() {
        _hasLoadedInitialData = false;
      });
    }
  }

  Future<void> _refreshData() async {
    print('🔄 Dashboard: Refrescando datos...');

    try {
      await Future.wait([
        ref.read(categoryProvider.notifier).loadCategories(),
        ref.read(expenseProvider.notifier).loadExpenses(),
        ref.read(budgetProvider.notifier).loadBudgets(),
      ]);

      print('✅ Dashboard: Datos refrescados');
    } catch (e) {
      print('❌ Dashboard: Error refrescando datos: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutDialog();
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddExpense() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddExpenseScreen()))
        .then((_) {
          _refreshData();
        });
  }

  void _navigateToExpenseList() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const ExpenseListScreen()),
        )
        .then((_) {
          _refreshData();
        });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Cargando datos del usuario...'),
      );
    }

    if (!_hasLoadedInitialData) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: Text('Hola, ${user.displayName}'),
        ),
        body: const LoadingWidget(message: 'Cargando datos...'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Próximamente: Notificaciones'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mi Perfil'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuración'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Mi Perfil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Configuración'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialSummary(),

              const SizedBox(height: 24),

              _buildQuickActions(),

              const SizedBox(height: 24),

              _buildRecentExpenses(),

              const SizedBox(height: 24),
              _buildQuickStats(),

              const SizedBox(height: 24),
              _buildBudgetAlerts(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Widget _buildFinancialSummary() {
    return Consumer(
      builder: (context, ref, child) {
        final expenseState = ref.watch(expenseProvider);
        final budgetSummary = ref.watch(budgetSummaryProvider);
        final user = ref.watch(currentUserProvider)!;

        if (expenseState.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: LoadingWidget(message: 'Cargando resumen...'),
            ),
          );
        }

        final totals = ref.read(expenseProvider.notifier).calculateTotals();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del Mes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        title: 'Total Gastado',
                        amount: totals.monthTotal,
                        currency: user.currency,
                        color: Colors.red,
                        icon: Icons.trending_up,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade600,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        title: 'Gastos Hoy',
                        amount: totals.todayTotal,
                        currency: user.currency,
                        color: Colors.orange,
                        icon: Icons.today,
                      ),
                    ),
                  ],
                ),

                if (budgetSummary.totalBudgets > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          title: 'Presupuestado',
                          amount: budgetSummary.totalLimit,
                          currency: user.currency,
                          color: const Color(0xFF2196F3),
                          icon: Icons.account_balance_wallet,
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
                          title: 'Disponible',
                          amount: budgetSummary.totalRemaining,
                          currency: user.currency,
                          color: budgetSummary.totalRemaining >= 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE53935),
                          icon: budgetSummary.totalRemaining >= 0
                              ? Icons.savings
                              : Icons.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required String currency,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatAmount(amount, currency),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Agregar Gasto',
                icon: Icons.add_circle_outline,
                color: Colors.green,
                onTap: _navigateToAddExpense,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Lista Gastos',
                icon: Icons.list_alt,
                color: Colors.purple,
                onTap: _navigateToExpenseList,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Categorías',
                icon: Icons.category,
                color: Colors.indigo,
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoryManagementScreen(),
                        ),
                      )
                      .then((_) {
                        _refreshData();
                      });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Presupuestos',
                icon: Icons.account_balance_wallet,
                color: const Color(0xFFFF5722),
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const BudgetScreen(),
                        ),
                      )
                      .then((_) {
                        _refreshData();
                      });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExpenses() {
    return Consumer(
      builder: (context, ref, child) {
        final expenses = ref.watch(expenseListProvider);
        final isLoading = ref.watch(expenseLoadingProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gastos Recientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _navigateToExpenseList,
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: Color(0xFF2196F3)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingWidget(message: 'Cargando gastos...'),
                ),
              )
            else if (expenses.isEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay gastos registrados',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer gasto tocando el botón +',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...expenses
                  .take(3)
                  .map(
                    (expense) => Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF2196F3,
                          ).withOpacity(0.1),
                          child: const Icon(
                            Icons.receipt,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        title: Text(
                          expense.formattedDescription,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          expense.formattedDate,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          expense.formattedAmount(
                            ref.watch(currentUserProvider)!.currency,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE53935),
                          ),
                        ),
                        onTap: _navigateToExpenseList,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Consumer(
      builder: (context, ref, child) {
        final expenses = ref.watch(expenseListProvider);
        final user = ref.watch(currentUserProvider)!;

        if (expenses.isEmpty) return const SizedBox.shrink();

        final totalExpenses = expenses.length;
        final thisWeekExpenses = expenses.where((e) => e.isThisWeek).length;
        final avgExpense = expenses.isNotEmpty
            ? expenses.fold(0.0, (sum, e) => sum + e.amount) / expenses.length
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Rápidas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: 'Total Gastos',
                      value: totalExpenses.toString(),
                      icon: Icons.receipt_long,
                    ),
                    _buildStatItem(
                      label: 'Esta Semana',
                      value: thisWeekExpenses.toString(),
                      icon: Icons.calendar_month,
                    ),
                    _buildStatItem(
                      label: 'Promedio',
                      value: _formatAmount(avgExpense, user.currency),
                      icon: Icons.trending_up,
                      isAmount: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    bool isAmount = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF2196F3)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isAmount ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatAmount(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'BOB':
        return 'Bs. ${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'ARS':
        return '\$${amount.toStringAsFixed(2)} ARS';
      case 'BRL':
        return 'R\$${amount.toStringAsFixed(2)}';
      case 'CLP':
        return '\$${amount.toStringAsFixed(2)} CLP';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  Widget _buildBudgetAlerts() {
    return Consumer(
      builder: (context, ref, child) {
        final alerts = ref.watch(budgetAlertsProvider);

        if (alerts.isEmpty) return const SizedBox.shrink();

        final topAlerts = alerts.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alertas de Presupuesto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (alerts.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BudgetScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...topAlerts.map((alert) => _buildAlertCard(alert)),
          ],
        );
      },
    );
  }

  Widget _buildAlertCard(BudgetAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.type) {
      case BudgetAlertType.exceeded:
        alertColor = const Color(0xFFE53935);
        alertIcon = Icons.error;
        break;
      case BudgetAlertType.atRisk:
        alertColor = const Color(0xFFFF5722);
        alertIcon = Icons.warning;
        break;
      case BudgetAlertType.nearLimit:
        alertColor = const Color(0xFFFF9800);
        alertIcon = Icons.info;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alertColor,
          child: Icon(alertIcon, color: alertColor, size: 20),
        ),
        title: Text(
          alert.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          alert.message,
          style: TextStyle(color: alertColor, fontSize: 12),
        ),
        trailing: Text(
          '${alert.budget.spentPercentage.toStringAsFixed(0)}%',
          style: TextStyle(fontWeight: FontWeight.bold, color: alertColor),
        ),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const BudgetScreen()));
        },
      ),
    );
  }
}
