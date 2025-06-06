import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../aplication/providers/auth_provider.dart';
import '../../../aplication/providers/budget_provider.dart';
import '../../../aplication/providers/category_provider.dart';
import '../../../domain/entities/budget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custtom_button.dart';

class EditBudgetScreen extends ConsumerStatefulWidget {
  final Budget budget;

  const EditBudgetScreen({super.key, required this.budget});

  @override
  ConsumerState<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends ConsumerState<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _limitController.text = widget.budget.limitAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final limitAmount = double.tryParse(_limitController.text);
    if (limitAmount == null || limitAmount <= 0) {
      _showErrorMessage('Ingresa un monto válido');
      return;
    }

    final success = await ref
        .read(budgetProvider.notifier)
        .updateBudget(budgetId: widget.budget.id!, limitAmount: limitAmount);

    if (success) {
      _showSuccessMessage('¡Presupuesto actualizado exitosamente!');
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDeleteBudget() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed == true) {
      final success = await ref
          .read(budgetProvider.notifier)
          .deleteBudget(widget.budget.id!);

      if (success) {
        _showSuccessMessage('Presupuesto eliminado exitosamente');
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: Text(
          '¿Estás seguro que quieres eliminar este presupuesto para ${widget.budget.period}?\n\nEsta acción no se puede deshacer.',
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final user = ref.watch(currentUserProvider);
    final category = ref
        .read(categoryProvider.notifier)
        .getCategoryById(widget.budget.categoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Presupuesto'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _handleDeleteBudget,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del presupuesto original
              _buildOriginalBudgetInfo(user, category),

              const SizedBox(height: 24),

              // Vista previa de cambios
              _buildBudgetPreview(user, category),

              const SizedBox(height: 24),

              // Información actual
              _buildCurrentInfoSection(category),

              const SizedBox(height: 24),

              // Editar límite
              _buildEditLimitSection(user),

              const SizedBox(height: 32),

              // Botones
              _buildActionButtons(budgetState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalBudgetInfo(user, category) {
    final statusColor = Color(
      int.parse(widget.budget.statusColor.replaceFirst('#', '0xFF')),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  'Presupuesto Actual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: category != null
                        ? Color(
                            int.parse(category.color.replaceFirst('#', '0xFF')),
                          ).withOpacity(0.1)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category != null
                          ? Color(
                              int.parse(
                                category.color.replaceFirst('#', '0xFF'),
                              ),
                            ).withOpacity(0.3)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Icon(
                    _getIconData(category?.icon ?? 'category'),
                    color: category != null
                        ? Color(
                            int.parse(category.color.replaceFirst('#', '0xFF')),
                          )
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.formattedName ?? 'Categoría desconocida',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.budget.period,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        'Estado: ${widget.budget.getStatusMessage(user?.currency ?? 'BOB')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progreso actual
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: widget.budget.spentPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastado: ${_formatAmount(widget.budget.spentAmount, user?.currency ?? 'BOB')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '${widget.budget.spentPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  'Límite: ${_formatAmount(widget.budget.limitAmount, user?.currency ?? 'BOB')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetPreview(user, category) {
    final newLimit =
        double.tryParse(_limitController.text) ?? widget.budget.limitAmount;
    final newRemaining = newLimit - widget.budget.spentAmount;
    final newPercentage = newLimit > 0
        ? (widget.budget.spentAmount / newLimit) * 100
        : 0.0;

    Color newStatusColor;
    if (newPercentage >= 100) {
      newStatusColor = const Color(0xFFE53935);
    } else if (newPercentage >= 90) {
      newStatusColor = const Color(0xFFFF5722);
    } else if (newPercentage >= 80) {
      newStatusColor = const Color(0xFFFF9800);
    } else {
      newStatusColor = const Color(0xFF4CAF50);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.preview, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Vista Previa de Cambios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nuevo progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: newPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(newStatusColor),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo Límite',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatAmount(newLimit, user?.currency ?? 'BOB'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${newPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: newStatusColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      newRemaining >= 0 ? 'Restante' : 'Excedido',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatAmount(
                        newRemaining.abs(),
                        user?.currency ?? 'BOB',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: newRemaining >= 0
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentInfoSection(category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Color(0xFFFF5722)),
                SizedBox(width: 8),
                Text(
                  'Información del Presupuesto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.category,
              'Categoría',
              category?.formattedName ?? 'Desconocida',
            ),
            _buildInfoRow(
              Icons.calendar_month,
              'Período',
              widget.budget.period,
            ),
            _buildInfoRow(
              Icons.schedule,
              'Creado',
              _formatDate(widget.budget.createdAt),
            ),
            if (widget.budget.updatedAt != null)
              _buildInfoRow(
                Icons.update,
                'Actualizado',
                _formatDate(widget.budget.updatedAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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

  Widget _buildEditLimitSection(user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit, color: Color(0xFFFF5722)),
                SizedBox(width: 8),
                Text(
                  'Editar Límite',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta el monto máximo para este presupuesto',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            MoneyTextField(
              controller: _limitController,
              currency: user?.currency ?? 'BOB',
              label: 'Nuevo límite',
              hintText: 'Ej: 1500.00',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'El monto límite es obligatorio';
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido mayor a 0';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Para actualizar la vista previa
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(budgetState) {
    return Column(
      children: [
        CustomButton(
          text: 'Actualizar Presupuesto',
          onPressed: budgetState.isLoading ? null : _handleUpdateBudget,
          isLoading: budgetState.isLoading,
          icon: Icons.save,
          backgroundColor: const Color(0xFFFF5722),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _handleDeleteBudget,
          icon: const Icon(Icons.delete),
          label: const Text('Eliminar Presupuesto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE53935),
            side: const BorderSide(color: Color(0xFFE53935)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            side: BorderSide(color: Colors.grey[400]!),
          ),
          child: const Text('Cancelar'),
        ),
      ],
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
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
