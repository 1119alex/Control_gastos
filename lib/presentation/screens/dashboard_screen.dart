import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../../domain/usecases/expense_usecases.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'login_screen.dart';

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
      // Cargar datos iniciales de forma segura
      await Future.wait([
        ref.read(categoryProvider.notifier).loadCategories(),
        ref.read(expenseProvider.notifier).loadExpenses(),
      ]);
    } catch (e) {
      print('❌ Error cargando datos iniciales: $e');
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
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
                  leading: Icon(Icons.logout, color: AppTheme.errorColor),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen financiero
              _buildFinancialSummary(),

              const SizedBox(height: AppSpacing.lg),

              // Acciones rápidas
              _buildQuickActions(),

              const SizedBox(height: AppSpacing.lg),

              // Gastos recientes
              _buildRecentExpenses(),

              const SizedBox(height: AppSpacing.lg),

              // Estadísticas rápidas
              _buildQuickStats(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a agregar gasto
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Próximamente: Agregar gasto'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
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
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LoadingWidget(message: 'Cargando resumen...'),
            ),
          );
        }

        final totals = ref.read(expenseProvider.notifier).calculateTotals();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen del Mes', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        title: 'Total Gastado',
                        amount: totals.monthTotal,
                        currency: user.currency,
                        color: AppTheme.errorColor,
                        icon: Icons.trending_up,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        title: 'Gastos Hoy',
                        amount: totals.todayTotal,
                        currency: user.currency,
                        color: AppTheme.warningColor,
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
            const SizedBox(width: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.xs),
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
        const Text('Acciones Rápidas', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Agregar Gasto',
                icon: Icons.add_circle_outline,
                color: AppTheme.primaryColor,
                onTap: () {
                  // TODO: Implementar
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildActionCard(
                title: 'Ver Reportes',
                icon: Icons.bar_chart,
                color: AppTheme.secondaryColor,
                onTap: () {
                  // TODO: Implementar
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: AppSpacing.sm),
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
                const Text('Gastos Recientes', style: AppTextStyles.h3),
                TextButton(
                  onPressed: () {
                    // TODO: Ver todos los gastos
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (isLoading)
              const LoadingWidget(message: 'Cargando gastos...')
            else if (expenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No hay gastos registrados',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          child: const Icon(
                            Icons.receipt,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(expense.formattedDescription),
                        subtitle: Text(expense.formattedDate),
                        trailing: Text(
                          expense.formattedAmount(
                            ref.watch(currentUserProvider)!.currency,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
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
            const Text('Estadísticas Rápidas', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
        Icon(icon, size: 24, color: AppTheme.primaryColor),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: isAmount ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
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
}
