import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../aplication/providers/auth_provider.dart';
import '../../../aplication/providers/category_provider.dart';
import '../../../domain/entities/category.dart';
import '../../widgets/loading_widget.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final _searchController = TextEditingController();
  List<Category> _filteredCategories = [];
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_hasLoadedData) return;

    try {
      print('🏷️ CategoryManagement: Cargando categorías...');
      setState(() {
        _hasLoadedData = true;
      });

      await ref.read(categoryProvider.notifier).loadCategories();
      _applyFilters();

      print('🏷️ CategoryManagement: Categorías cargadas');
    } catch (e) {
      print('❌ CategoryManagement: Error cargando categorías: $e');
      setState(() {
        _hasLoadedData = false;
      });
    }
  }

  Future<void> _reloadData() async {
    print('🔄 CategoryManagement: Recargando datos...');
    setState(() {
      _hasLoadedData = false;
    });
    await _loadData();
  }

  void _applyFilters() {
    final allCategories = ref.read(categoryListProvider);
    final searchQuery = _searchController.text.toLowerCase().trim();

    List<Category> filtered = List.from(allCategories);

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((category) {
        return category.name.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Ordenar por nombre
    filtered.sort((a, b) => a.name.compareTo(b.name));

    if (mounted) {
      setState(() {
        _filteredCategories = filtered;
      });
    }
  }

  void _navigateToAddCategory() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const AddCategoryScreen()),
        )
        .then((_) {
          _reloadData();
        });
  }

  void _navigateToEditCategory(Category category) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditCategoryScreen(category: category),
          ),
        )
        .then((_) {
          _reloadData();
        });
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await _showDeleteConfirmation(category);
    if (confirmed == true) {
      final success = await ref
          .read(categoryProvider.notifier)
          .deleteCategory(category.id!);

      if (success) {
        _showSuccessMessage('Categoría eliminada exitosamente');
        await _reloadData();
      } else {
        _showErrorMessage(
          'No se puede eliminar una categoría que tiene gastos asociados',
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(Category category) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro que quieres eliminar la categoría "${category.formattedName}"?\n\nEsta acción no se puede deshacer.',
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

  void _showCategoryDetails(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CategoryDetailsBottomSheet(
        category: category,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEditCategory(category);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteCategory(category);
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
    final isLoadingData = categoryState.isLoading || !_hasLoadedData;

    // Escuchar cambios en las categorías
    ref.listen<List<Category>>(categoryListProvider, (previous, next) {
      if (_hasLoadedData && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyFilters();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        backgroundColor: const Color(0xFF9C27B0),
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
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar categorías...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF9C27B0),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Lista de categorías
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadData,
              child: _buildCategoriesList(isLoadingData),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCategory,
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriesList(bool isLoadingData) {
    if (isLoadingData) {
      return const LoadingWidget(message: 'Cargando categorías...');
    }

    if (_filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron categorías con ese nombre'
                  : 'No hay categorías creadas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Intenta buscar con otro término'
                  : 'Agrega tu primera categoría personalizada',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_searchController.text.isEmpty)
              ElevatedButton.icon(
                onPressed: _navigateToAddCategory,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Categoría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    final user = ref.watch(currentUserProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _buildCategoryCard(category, user);
      },
    );
  }

  Widget _buildCategoryCard(Category category, user) {
    final categoryColor = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCategoryDetails(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador de color e ícono
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: categoryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Información de la categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.formattedName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.palette, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          category.color.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.label, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _getCategoryTypeName(category.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (category.hasBudget) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Presupuesto: ${_formatAmount(category.defaultBudget, user?.currency ?? 'BOB')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de acción
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      _navigateToEditCategory(category);
                      break;
                    case 'delete':
                      _deleteCategory(category);
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
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
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
        title: const Text('Gestión de Categorías'),
        content: const Text(
          'Aquí puedes:\n\n'
          '• Ver todas tus categorías\n'
          '• Crear nuevas categorías personalizadas\n'
          '• Editar nombre, color e ícono\n'
          '• Establecer presupuestos por categoría\n'
          '• Eliminar categorías no utilizadas\n\n'
          'Las categorías te ayudan a organizar mejor tus gastos.',
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

  String _getCategoryTypeName(CategoryType type) {
    switch (type) {
      case CategoryType.food:
        return 'Alimentación';
      case CategoryType.transport:
        return 'Transporte';
      case CategoryType.entertainment:
        return 'Entretenimiento';
      case CategoryType.health:
        return 'Salud';
      case CategoryType.education:
        return 'Educación';
      case CategoryType.home:
        return 'Hogar';
      case CategoryType.other:
        return 'Otros';
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
}

// Widget para detalles de la categoría
class _CategoryDetailsBottomSheet extends ConsumerWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryDetailsBottomSheet({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final categoryColor = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ícono y nombre
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: categoryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.formattedName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getCategoryTypeName(category.type),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Detalles
          _buildDetailRow(Icons.palette, 'Color', category.color.toUpperCase()),
          _buildDetailRow(
            Icons.label,
            'Tipo',
            _getCategoryTypeName(category.type),
          ),

          if (category.hasBudget)
            _buildDetailRow(
              Icons.account_balance_wallet,
              'Presupuesto',
              _formatAmount(category.defaultBudget, user?.currency ?? 'BOB'),
            )
          else
            _buildDetailRow(
              Icons.account_balance_wallet,
              'Presupuesto',
              'Sin presupuesto definido',
            ),

          _buildDetailRow(
            Icons.calendar_today,
            'Creada',
            _formatDate(category.createdAt),
          ),

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

  String _getCategoryTypeName(CategoryType type) {
    switch (type) {
      case CategoryType.food:
        return 'Alimentación';
      case CategoryType.transport:
        return 'Transporte';
      case CategoryType.entertainment:
        return 'Entretenimiento';
      case CategoryType.health:
        return 'Salud';
      case CategoryType.education:
        return 'Educación';
      case CategoryType.home:
        return 'Hogar';
      case CategoryType.other:
        return 'Otros';
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
    return '${date.day}/${date.month}/${date.year}';
  }
}
