import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../aplication/providers/auth_provider.dart';
import '../../aplication/providers/expense_provider.dart';
import '../../aplication/providers/category_provider.dart';
import '../../aplication/providers/camera_provider.dart';
import '../../domain/entities/category.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custtom_button.dart';
import '../widgets/loading_widget.dart';
import '../widgets/receipt_image_widget.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _establishmentController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _capturedImagePath;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    // Cargar categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadCategories();
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

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agregar Comprobante',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  onTap: () {
                    Navigator.pop(context);
                    _captureFromCamera();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galería',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2196F3)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    setState(() {
      _isProcessingImage = true;
    });

    try {
      final imagePath = await ref
          .read(cameraProvider.notifier)
          .captureFromCamera();
      if (imagePath != null) {
        setState(() {
          _capturedImagePath = imagePath;
        });
        await _processImageWithOCR(imagePath);
      }
    } catch (e) {
      _showErrorMessage('Error al capturar imagen: $e');
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessingImage = true;
    });

    try {
      final imagePath = await ref
          .read(cameraProvider.notifier)
          .pickFromGallery();
      if (imagePath != null) {
        setState(() {
          _capturedImagePath = imagePath;
        });
        await _processImageWithOCR(imagePath);
      }
    } catch (e) {
      _showErrorMessage('Error al seleccionar imagen: $e');
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _processImageWithOCR(String imagePath) async {
    // TODO: Implementar OCR básico
    // Por ahora, mostraremos un mensaje simulando el procesamiento
    _showSuccessMessage('Imagen capturada. OCR en desarrollo...');

    // Simulación de datos extraídos (implementar OCR real después)
    // if (mounted) {
    //   setState(() {
    //     _amountController.text = '15.50';
    //     _establishmentController.text = 'Supermercado ABC';
    //   });
    // }
  }

  Future<void> _handleSaveExpense() async {
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
        .addExpense(
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
      _showSuccessMessage('¡Gasto guardado exitosamente!');
      // Limpiar formulario después de guardar
      _clearForm();
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _establishmentController.clear();
    _notesController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDate = DateTime.now();
      _capturedImagePath = null;
    });
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
        title: const Text('Agregar Gasto'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_capturedImagePath != null)
            IconButton(
              icon: const Icon(Icons.photo),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ReceiptImageViewer(imagePath: _capturedImagePath!),
                  ),
                );
              },
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
              // Comprobante
              _buildReceiptSection(),

              const SizedBox(height: 24),

              // Información básica
              _buildBasicInfoSection(user, categoryState),

              const SizedBox(height: 24),

              // Información adicional
              _buildAdditionalInfoSection(),

              const SizedBox(height: 32),

              // Botón guardar
              CustomButton(
                text: 'Guardar Gasto',
                onPressed: expenseState.isLoading ? null : _handleSaveExpense,
                isLoading: expenseState.isLoading,
                icon: Icons.save,
                backgroundColor: const Color(0xFF4CAF50),
              ),

              const SizedBox(height: 16),

              // Botón limpiar
              OutlinedButton(
                onPressed: _clearForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: const Text('Limpiar Formulario'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                const Text(
                  'Comprobante',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_isProcessingImage)
                  const SmallLoadingWidget()
                else
                  IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: _showImageSourceDialog,
                    color: const Color(0xFF2196F3),
                  ),
              ],
            ),

            if (_capturedImagePath != null) ...[
              const SizedBox(height: 12),
              ReceiptImageWidget(
                imagePath: _capturedImagePath!,
                height: 100,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ReceiptImageViewer(imagePath: _capturedImagePath!),
                    ),
                  );
                },
                onDelete: () {
                  setState(() {
                    _capturedImagePath = null;
                  });
                },
              ),
            ] else ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca para agregar comprobante',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
                Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Text(
                  'Información Básica',
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
