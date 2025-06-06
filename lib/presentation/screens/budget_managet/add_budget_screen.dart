import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../aplication/providers/auth_provider.dart';
import '../../../aplication/providers/budget_provider.dart';
import '../../../aplication/providers/category_provider.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/usecases/budget_usecases.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custtom_button.dart';
import '../../widgets/loading_widget.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final int? initialMonth;
  final int? initialYear;

  const AddBudgetScreen({super.key, this.initialMonth, this.initialYear});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  Category? _selectedCategory;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  BudgetSuggestion? _suggestion;
  bool _showSuggestion = false;

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
    if (widget.initialMonth != null) _selectedMonth = widget.initialMonth!;
    if (widget.initialYear != null) _selectedYear = widget.initialYear!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(Category? category) {
    setState(() {
      _selectedCategory = category;
      _showSuggestion = false;
      _suggestion = null;
    });

    if (category != null) {
      _loadSuggestion();
    }
  }

  void _loadSuggestion() {
    if (_selectedCategory == null) return;

    final suggestion = ref.read(
      budgetSuggestionProvider((
        categoryId: _selectedCategory!.id!,
        month: _selectedMonth,
        year: _selectedYear,
      )),
    );

    setState(() {
      _suggestion = suggestion;
      _showSuggestion = suggestion.suggestedAmount > 0;
    });
  }

  void _applySuggestion() {
    if (_suggestion != null) {
      _limitController.text = _suggestion!.suggestedAmount.toStringAsFixed(2);
    }
  }

  Future<void> _handleSaveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showErrorMessage('Por favor selecciona una categoría');
      return;
    }

    final limitAmount = double.tryParse(_limitController.text);
    if (limitAmount == null || limitAmount <= 0) {
      _showErrorMessage('Ingresa un monto válido');
      return;
    }

    final success = await ref
        .read(budgetProvider.notifier)
        .addBudget(
          categoryId: _selectedCategory!.id!,
          month: _selectedMonth,
          year: _selectedYear,
          limitAmount: limitAmount,
        );

    if (success) {
      _showSuccessMessage('¡Presupuesto creado exitosamente!');
      Navigator.of(context).pop();
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
    final categoryState = ref.watch(categoryProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Presupuesto'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview del presupuesto
              if (_selectedCategory != null) _buildBudgetPreview(),

              const SizedBox(height: 24),

              // Información básica
              _buildBasicInfoSection(categoryState),

              const SizedBox(height: 24),

              // Período
              _buildPeriodSection(),

              const SizedBox(height: 24),

              // Monto límite
              _buildLimitSection(user),

              // Sugerencia
              if (_showSuggestion && _suggestion != null) ...[
                const SizedBox(height: 16),
                _buildSuggestionCard(),
              ],

              const SizedBox(height: 32),

              // Botones
              _buildActionButtons(budgetState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetPreview() {
    final categoryColor = Color(
      int.parse(_selectedCategory!.color.replaceFirst('#', '0xFF')),
    );

    final limitAmount = double.tryParse(_limitController.text) ?? 0.0;
    final user = ref.watch(currentUserProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Vista Previa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: categoryColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getIconData(_selectedCategory!.icon),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCategory!.formattedName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (limitAmount > 0)
                        Text(
                          'Límite: ${_formatAmount(limitAmount, user?.currency ?? 'BOB')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(CategoryState categoryState) {
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
                Icon(Icons.category, color: Color(0xFFFF5722)),
                SizedBox(width: 8),
                Text(
                  'Categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (categoryState.isLoading)
              const LoadingWidget(message: 'Cargando categorías...')
            else if (categoryState.categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text('No hay categorías disponibles'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Category>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Selecciona una categoría'),
                    onChanged: _onCategoryChanged,
                    items: categoryState.categories
                        .map<DropdownMenuItem<Category>>((category) {
                          return DropdownMenuItem<Category>(
                            value: category,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        category.color.replaceFirst(
                                          '#',
                                          '0xFF',
                                        ),
                                      ),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(category.formattedName),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection() {
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (index) => currentYear - 2 + index);

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
                Icon(Icons.calendar_month, color: Color(0xFFFF5722)),
                SizedBox(width: 8),
                Text(
                  'Período',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
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
                      _loadSuggestion();
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: DropdownButtonFormField<int>(
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
                      _loadSuggestion();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitSection(user) {
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
                Icon(Icons.account_balance_wallet, color: Color(0xFFFF5722)),
                SizedBox(width: 8),
                Text(
                  'Límite de Gasto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Establece el monto máximo que planeas gastar en esta categoría',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            MoneyTextField(
              controller: _limitController,
              currency: user?.currency ?? 'BOB',
              label: 'Monto límite',
              hintText: 'Ej: 1000.00',
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

  Widget _buildSuggestionCard() {
    final user = ref.watch(currentUserProvider);

    Color confidenceColor;
    IconData confidenceIcon;

    switch (_suggestion!.confidence) {
      case BudgetConfidence.high:
        confidenceColor = const Color(0xFF4CAF50);
        confidenceIcon = Icons.thumb_up;
        break;
      case BudgetConfidence.medium:
        confidenceColor = const Color(0xFFFF9800);
        confidenceIcon = Icons.info;
        break;
      case BudgetConfidence.low:
        confidenceColor = const Color(0xFFFF5722);
        confidenceIcon = Icons.warning;
        break;
      case BudgetConfidence.noData:
        confidenceColor = Colors.grey;
        confidenceIcon = Icons.help;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: confidenceColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(confidenceIcon, color: confidenceColor),
                const SizedBox(width: 8),
                const Text(
                  'Sugerencia Inteligente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_suggestion!.suggestedAmount > 0) ...[
              Text(
                'Monto sugerido: ${_formatAmount(_suggestion!.suggestedAmount, user?.currency ?? 'BOB')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: confidenceColor,
                ),
              ),
              const SizedBox(height: 8),
            ],

            Text(
              _suggestion!.reasoning,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),

            if (_suggestion!.suggestedAmount > 0) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _applySuggestion,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Usar Sugerencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confidenceColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(budgetState) {
    return Column(
      children: [
        CustomButton(
          text: 'Crear Presupuesto',
          onPressed: budgetState.isLoading ? null : _handleSaveBudget,
          isLoading: budgetState.isLoading,
          icon: Icons.save,
          backgroundColor: const Color(0xFFFF5722),
        ),
        const SizedBox(height: 16),
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
        return '\${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}
