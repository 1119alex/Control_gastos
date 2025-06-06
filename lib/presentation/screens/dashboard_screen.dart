import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../../domain/usecases/expense_usecases.dart';
import '../widgets/loading_widget.dart';
import 'login_screen.dart';
import 'add_expense_screen.dart';
import 'expense_list_screen.dart';
import 'test_camera_screen.dart';
import 'test_camera_screen.dart'; // Agregar esta importaciónd/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../../domain/usecases/expense_usecases.dart';
import '../widgets/loading_widget.dart';
import 'login_screen.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      print('📊 Dashboard: Iniciando carga de datos...');

      // Cargar datos iniciales de forma segura
      await Future.wait([
        ref.read(categoryProvider.notifier).loadCategories(),
        ref.read(expenseProvider.notifier).loadExpenses(),
      ]);

      print('📊 Dashboard: Datos cargados exitosamente');
    } catch (e) {
      print('❌ Dashboard: Error cargando datos iniciales: $e');
      // No lanzar el error para evitar crash
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddExpense() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
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
              // TODO: Implementar notificaciones
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navegar a perfil
                  break;
                case 'settings':
                  // TODO: Navegar a configuraciones
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
                  leading: Icon(Icons.logout, color: Color(0xFFE53935)),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Color(0xFFE53935)),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF4CAF50),
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
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen financiero
              _buildFinancialSummary(),

              const SizedBox(height: 24),

              // Acciones rápidas
              _buildQuickActions(),

              const SizedBox(height: 24),

              // Gastos recientes
              _buildRecentExpenses(),

              const SizedBox(height: 24),

              // Estadísticas rápidas
              _buildQuickStats(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: const Color(0xFF4CAF50),
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
                        color: const Color(0xFFE53935),
                        icon: Icons.trending_up,
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
                        title: 'Gastos Hoy',
                        amount: totals.todayTotal,
                        currency: user.currency,
                        color: const Color(0xFFFF9800),
                        icon: Icons.today,
                      ),
                    ),
                  ],
                ),
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
                color: Colors.grey[600],
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
                color: const Color(0xFF4CAF50),
                onTap: _navigateToAddExpense,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Lista Gastos',
                icon: Icons.list_alt,
                color: const Color(0xFF9C27B0),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ExpenseListScreen(),
                    ),
                  );
                },
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
                color: const Color(0xFF9C27B0),
                onTap: () {
                  // TODO: Implementar gestión de categorías
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Próximamente: Gestión de categorías'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                  // TODO: Implementar presupuestos
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Próximamente: Presupuestos'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                  onPressed: () {
                    // TODO: Ver todos los gastos
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: Lista completa de gastos'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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
        return '\${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'ARS':
        return '\${amount.toStringAsFixed(2)} ARS';
      case 'BRL':
        return 'R\${amount.toStringAsFixed(2)}';
      case 'CLP':
        return '\${amount.toStringAsFixed(2)} CLP';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}
