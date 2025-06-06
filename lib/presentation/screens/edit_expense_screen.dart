import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custtom_button.dart';
import '../widgets/loading_widget.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _establishmentController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // Cargar categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
    });
  }

  void _initializeForm() {
    // Llenar formulario con datos del gasto actual
    _amountController.text = widget.expense.amount.toStringAsFixed(2);
    _descriptionController.text = widget.expense.description;
    _locationController.text = widget.expense.location ?? '';
    _establishmentController.text = widget.expense.establishment ?? '';
    _notesController.text = widget.expense.notes ?? '';
    _selectedDate = widget.expense.expenseDate;

    // La categoría se establecerá cuando se carguen las categorías
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoryListProvider);
      _selectedCategory = categories.firstWhere(
        (category) => category.id == widget.expense.categoryId,
        orElse: () =>
            categories.isNotEmpty ? categories.first : null as Category,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _establishmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleUpdateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showErrorMessage('Por favor selecciona una categoría');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorMessage('Ingresa un monto válido');
      return;
    }

    final success = await ref
        .read(expenseProvider.notifier)
        .updateExpense(
          expenseId: widget.expense.id!,
          amount: amount,
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategory!.id!,
          date: _selectedDate,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          establishment: _establishmentController.text.trim().isEmpty
              ? null
              : _establishmentController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (success) {
      _showSuccessMessage('¡Gasto actualizado exitosamente!');
      Navigator.of(context).pop();
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro que quieres eliminar "${widget.expense.formattedDescription}"?',
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

    if (confirmed == true) {
      final success = await ref
          .read(expenseProvider.notifier)
          .deleteExpense(widget.expense.id!);
      if (success) {
        _showSuccessMessage('Gasto eliminado exitosamente');
        Navigator.of(context).pop();
      }
    }
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
    final expenseState = ref.watch(expenseProvider);
    final categoryState = ref.watch(categoryProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Gasto'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
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
              // Información del gasto original
              _buildOriginalExpenseInfo(),

              const SizedBox(height: 24),

              // Información básica
              _buildBasicInfoSection(user, categoryState),

              const SizedBox(height: 24),

              // Información adicional
              _buildAdditionalInfoSection(),

              const SizedBox(height: 32),

              // Botón actualizar
              CustomButton(
                text: 'Actualizar Gasto',
                onPressed: expenseState.isLoading ? null : _handleUpdateExpense,
                isLoading: expenseState.isLoading,
                icon: Icons.save,
                backgroundColor: const Color(0xFF2196F3),
              ),

              const SizedBox(height: 16),

              // Botón cancelar
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalExpenseInfo() {
    final originalCategory = ref
        .read(categoryProvider.notifier)
        .getCategoryById(widget.expense.categoryId);
    final user = ref.watch(currentUserProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  'Gasto Original',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.expense.formattedDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        originalCategory?.formattedName ?? 'Sin categoría',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        widget.expense.formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.expense.formattedAmount(user?.currency ?? 'BOB'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(user, CategoryState categoryState) {
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
                Icon(Icons.edit, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  'Editar Información',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Monto
            MoneyTextField(
              controller: _amountController,
              currency: user?.currency ?? 'BOB',
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El monto es obligatorio';
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido mayor a 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Descripción
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hintText: 'Ej: Almuerzo en restaurante',
              prefixIcon: Icons.description,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'La descripción es obligatoria';
                if (value!.trim().length < 3) {
                  return 'La descripción debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Categoría
            _buildCategorySelector(categoryState),

            const SizedBox(height: 16),

            // Fecha
            _buildDateSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(CategoryState categoryState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

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
                onChanged: (Category? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items: categoryState.categories.map<DropdownMenuItem<Category>>(
                  (category) {
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
                                  category.color.replaceFirst('#', '0xFF'),
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
                  },
                ).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
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
                Icon(Icons.more_horiz, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  'Información Adicional (Opcional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Establecimiento
            CustomTextField(
              controller: _establishmentController,
              label: 'Establecimiento',
              hintText: 'Ej: Restaurante La Plaza',
              prefixIcon: Icons.store,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Ubicación
            CustomTextField(
              controller: _locationController,
              label: 'Ubicación',
              hintText: 'Ej: Zona Sur, La Paz',
              prefixIcon: Icons.location_on,
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Notas
            CustomTextField(
              controller: _notesController,
              label: 'Notas',
              hintText: 'Comentarios adicionales...',
              prefixIcon: Icons.note,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
