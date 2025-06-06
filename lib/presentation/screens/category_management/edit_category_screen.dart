import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../aplication/providers/auth_provider.dart';
import '../../../aplication/providers/category_provider.dart';
import '../../../domain/entities/category.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custtom_button.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  final Category category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  late String _selectedColor;
  late String _selectedIcon;
  late bool _hasBudget;

  // Colores predefinidos
  final List<String> _availableColors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#F44336',
    '#9C27B0',
    '#795548',
    '#607D8B',
    '#E91E63',
    '#00BCD4',
    '#FFC107',
    '#3F51B5',
    '#8BC34A',
    '#FF5722',
    '#673AB7',
    '#009688',
    '#CDDC39',
  ];

  // Íconos predefinidos
  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': 'category', 'data': Icons.category, 'label': 'General'},
    {'icon': 'restaurant', 'data': Icons.restaurant, 'label': 'Comida'},
    {
      'icon': 'directions_car',
      'data': Icons.directions_car,
      'label': 'Transporte',
    },
    {'icon': 'movie', 'data': Icons.movie, 'label': 'Entretenimiento'},
    {'icon': 'local_hospital', 'data': Icons.local_hospital, 'label': 'Salud'},
    {'icon': 'school', 'data': Icons.school, 'label': 'Educación'},
    {'icon': 'home', 'data': Icons.home, 'label': 'Hogar'},
    {'icon': 'shopping_cart', 'data': Icons.shopping_cart, 'label': 'Compras'},
    {'icon': 'sports_soccer', 'data': Icons.sports_soccer, 'label': 'Deportes'},
    {'icon': 'work', 'data': Icons.work, 'label': 'Trabajo'},
    {'icon': 'flight', 'data': Icons.flight, 'label': 'Viajes'},
    {'icon': 'pets', 'data': Icons.pets, 'label': 'Mascotas'},
    {'icon': 'phone', 'data': Icons.phone, 'label': 'Teléfono'},
    {'icon': 'computer', 'data': Icons.computer, 'label': 'Tecnología'},
    {
      'icon': 'fitness_center',
      'data': Icons.fitness_center,
      'label': 'Fitness',
    },
    {
      'icon': 'local_gas_station',
      'data': Icons.local_gas_station,
      'label': 'Combustible',
    },
    {'icon': 'local_cafe', 'data': Icons.local_cafe, 'label': 'Café'},
    {
      'icon': 'local_pharmacy',
      'data': Icons.local_pharmacy,
      'label': 'Farmacia',
    },
    {
      'icon': 'local_grocery_store',
      'data': Icons.local_grocery_store,
      'label': 'Supermercado',
    },
    {'icon': 'attach_money', 'data': Icons.attach_money, 'label': 'Dinero'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.category.name;
    _selectedColor = widget.category.color;
    _selectedIcon = widget.category.icon;
    _hasBudget = widget.category.hasBudget;

    if (_hasBudget) {
      _budgetController.text = widget.category.defaultBudget.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final budget = _hasBudget
        ? double.tryParse(_budgetController.text) ?? 0.0
        : 0.0;

    final success = await ref
        .read(categoryProvider.notifier)
        .updateCategory(
          categoryId: widget.category.id!,
          name: _nameController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
          defaultBudget: budget,
        );

    if (success) {
      _showSuccessMessage('¡Categoría actualizada exitosamente!');
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDeleteCategory() async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed == true) {
      final success = await ref
          .read(categoryProvider.notifier)
          .deleteCategory(widget.category.id!);

      if (success) {
        _showSuccessMessage('Categoría eliminada exitosamente');
        Navigator.of(context).pop();
      } else {
        _showErrorMessage(
          'No se puede eliminar una categoría que tiene gastos asociados',
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro que quieres eliminar la categoría "${widget.category.formattedName}"?\n\nEsta acción no se puede deshacer y eliminará todos los datos asociados.',
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
    final categoryState = ref.watch(categoryProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Categoría'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _handleDeleteCategory,
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
              // Información de la categoría original
              _buildOriginalCategoryInfo(user),

              const SizedBox(height: 24),

              // Preview de los cambios
              _buildCategoryPreview(user),

              const SizedBox(height: 24),

              // Información básica
              _buildBasicInfoSection(),

              const SizedBox(height: 24),

              // Selector de color
              _buildColorSelector(),

              const SizedBox(height: 24),

              // Selector de ícono
              _buildIconSelector(),

              const SizedBox(height: 24),

              // Presupuesto
              _buildBudgetSection(user),

              const SizedBox(height: 32),

              // Botones
              _buildActionButtons(categoryState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalCategoryInfo(user) {
    final originalColor = Color(
      int.parse(widget.category.color.replaceFirst('#', '0xFF')),
    );
    final originalIconData =
        _availableIcons.firstWhere(
              (icon) => icon['icon'] == widget.category.icon,
              orElse: () => _availableIcons.first,
            )['data']
            as IconData;

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
                  'Categoría Original',
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
                    color: originalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: originalColor.withOpacity(0.3)),
                  ),
                  child: Icon(originalIconData, color: originalColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.formattedName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Color: ${widget.category.color.toUpperCase()}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (widget.category.hasBudget)
                        Text(
                          'Presupuesto: ${_formatAmount(widget.category.defaultBudget, user?.currency ?? 'BOB')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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

  Widget _buildCategoryPreview(user) {
    final categoryColor = Color(
      int.parse(_selectedColor.replaceFirst('#', '0xFF')),
    );
    final selectedIconData =
        _availableIcons.firstWhere(
              (icon) => icon['icon'] == _selectedIcon,
              orElse: () => _availableIcons.first,
            )['data']
            as IconData;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: categoryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(selectedIconData, color: categoryColor, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text.isEmpty
                  ? widget.category.name
                  : _nameController.text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (_hasBudget && _budgetController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Presupuesto: ${_formatAmount(double.tryParse(_budgetController.text) ?? 0.0, user?.currency ?? 'BOB')}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
                Icon(Icons.edit, color: Color(0xFF9C27B0)),
                SizedBox(width: 8),
                Text(
                  'Editar Información',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              label: 'Nombre de la categoría',
              hintText: 'Ej: Supermercado, Gasolina, Gym',
              prefixIcon: Icons.label,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'El nombre es obligatorio';
                }
                if (value!.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                if (value.trim().length > 30) {
                  return 'El nombre no puede tener más de 30 caracteres';
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

  Widget _buildColorSelector() {
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
                Icon(Icons.palette, color: Color(0xFF9C27B0)),
                SizedBox(width: 8),
                Text(
                  'Color de la Categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                final colorValue = Color(
                  int.parse(color.replaceFirst('#', '0xFF')),
                );

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorValue.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
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
                Icon(Icons.apps, color: Color(0xFF9C27B0)),
                SizedBox(width: 8),
                Text(
                  'Ícono de la Categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _availableIcons.length,
              itemBuilder: (context, index) {
                final iconData = _availableIcons[index];
                final isSelected = iconData['icon'] == _selectedIcon;
                final categoryColor = Color(
                  int.parse(_selectedColor.replaceFirst('#', '0xFF')),
                );

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconData['icon'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? categoryColor.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? categoryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      iconData['data'],
                      color: isSelected ? categoryColor : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(user) {
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
                Icon(Icons.account_balance_wallet, color: Color(0xFF9C27B0)),
                SizedBox(width: 8),
                Text(
                  'Presupuesto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Establece un límite de gasto mensual para esta categoría',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              value: _hasBudget,
              onChanged: (value) {
                setState(() {
                  _hasBudget = value ?? false;
                  if (!_hasBudget) {
                    _budgetController.clear();
                  }
                });
              },
              title: const Text('Establecer presupuesto mensual'),
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF9C27B0),
            ),

            if (_hasBudget) ...[
              const SizedBox(height: 16),
              MoneyTextField(
                controller: _budgetController,
                currency: user?.currency ?? 'BOB',
                label: 'Presupuesto mensual',
                hintText: 'Ej: 500.00',
                validator: (value) {
                  if (_hasBudget && (value?.isEmpty ?? true)) {
                    return 'Ingresa el monto del presupuesto';
                  }
                  if (_hasBudget) {
                    final amount = double.tryParse(value!);
                    if (amount == null || amount <= 0) {
                      return 'Ingresa un monto válido mayor a 0';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Para actualizar la vista previa
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(categoryState) {
    return Column(
      children: [
        CustomButton(
          text: 'Actualizar Categoría',
          onPressed: categoryState.isLoading ? null : _handleUpdateCategory,
          isLoading: categoryState.isLoading,
          icon: Icons.save,
          backgroundColor: const Color(0xFF9C27B0),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _handleDeleteCategory,
          icon: const Icon(Icons.delete),
          label: const Text('Eliminar Categoría'),
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
