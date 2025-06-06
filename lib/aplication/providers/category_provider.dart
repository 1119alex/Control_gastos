import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../data/services/database_services.dart';
import '../../domain/entities/category.dart';
import 'auth_provider.dart';

// Estado de categorías
class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasCategories => categories.isNotEmpty;
  int get categoryCount => categories.length;
}

// StateNotifier para manejar categorías
class CategoryNotifier extends StateNotifier<CategoryState> {
  final DatabaseService _databaseService;
  final Ref _ref;

  CategoryNotifier(this._databaseService, this._ref)
    : super(const CategoryState());

  // Cargar categorías del usuario actual
  Future<void> loadCategories() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(isLoading: true, errorMessage: null);

      final categoryModels = await _databaseService.getCategoriesByUser(
        user.id!,
      );
      final categories = categoryModels
          .map((model) => model.toEntity())
          .toList();

      state = state.copyWith(
        categories: categories,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ ${categories.length} categorías cargadas');
    } catch (e) {
      print('❌ Error cargando categorías: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar categorías: $e',
      );
    }
  }

  // Agregar nueva categoría
  Future<bool> addCategory({
    required String name,
    required String color,
    required String icon,
    double defaultBudget = 0.0,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return false;

      state = state.copyWith(isLoading: true, errorMessage: null);

      // Validar que no exista una categoría con el mismo nombre
      final existingCategory = state.categories
          .where((cat) => cat.name.toLowerCase() == name.toLowerCase().trim())
          .firstOrNull; // Usar firstOrNull en lugar de firstWhere

      if (existingCategory != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ya existe una categoría con este nombre',
        );
        return false;
      }

      // Crear nueva categoría
      final category = Category(
        name: name.trim(),
        color: color,
        icon: icon,
        defaultBudget: defaultBudget,
        userId: user.id!,
        createdAt: DateTime.now(),
      );

      // Validar antes de guardar
      if (!category.isValid) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Datos de categoría inválidos',
        );
        return false;
      }

      // Guardar en base de datos
      final categoryModel = CategoryModel.fromEntity(category);
      final categoryId = await _databaseService.insertCategory(categoryModel);

      // Agregar a la lista local
      final savedCategory = category.copyWith(id: categoryId);
      final updatedCategories = [...state.categories, savedCategory];

      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Categoría agregada: $name');
      return true;
    } catch (e) {
      print('❌ Error agregando categoría: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar categoría: $e',
      );
      return false;
    }
  }

  // Actualizar categoría existente
  Future<bool> updateCategory({
    required int categoryId,
    String? name,
    String? color,
    String? icon,
    double? defaultBudget,
    bool? isActive,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Encontrar categoría actual
      final currentCategoryIndex = state.categories.indexWhere(
        (c) => c.id == categoryId,
      );
      if (currentCategoryIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Categoría no encontrada',
        );
        return false;
      }

      final currentCategory = state.categories[currentCategoryIndex];

      // Crear categoría actualizada
      final updatedCategory = currentCategory.copyWith(
        name: name ?? currentCategory.name,
        color: color ?? currentCategory.color,
        icon: icon ?? currentCategory.icon,
        defaultBudget: defaultBudget ?? currentCategory.defaultBudget,
        isActive: isActive ?? currentCategory.isActive,
      );

      // Validar antes de guardar
      if (!updatedCategory.isValid) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Datos de categoría inválidos',
        );
        return false;
      }

      // Actualizar en base de datos
      final categoryModel = CategoryModel.fromEntity(updatedCategory);
      await _databaseService.updateCategory(categoryModel);

      // Actualizar lista local
      final updatedCategories = List<Category>.from(state.categories);
      updatedCategories[currentCategoryIndex] = updatedCategory;

      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Categoría actualizada: ${updatedCategory.name}');
      return true;
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar categoría: $e',
      );
      return false;
    }
  }

  // Eliminar categoría (soft delete)
  Future<bool> deleteCategory(int categoryId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Encontrar categoría
      final category = state.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw Exception('Categoría no encontrada'),
      );

      // Eliminar de base de datos (soft delete)
      await _databaseService.deleteCategory(categoryId);

      // Remover de lista local
      final updatedCategories = state.categories
          .where((c) => c.id != categoryId)
          .toList();

      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      print('✅ Categoría eliminada: ${category.name}');
      return true;
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar categoría: $e',
      );
      return false;
    }
  }

  // Buscar categorías
  List<Category> searchCategories(String query) {
    if (query.trim().isEmpty) return state.categories;

    final lowerQuery = query.toLowerCase().trim();
    return state.categories.where((category) {
      return category.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Obtener categoría por ID
  Category? getCategoryById(int categoryId) {
    try {
      return state.categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Obtener categorías por tipo
  List<Category> getCategoriesByType(CategoryType type) {
    return state.categories.where((category) => category.type == type).toList();
  }

  // Obtener categorías con presupuesto
  List<Category> getCategoriesWithBudget() {
    return state.categories.where((category) => category.hasBudget).toList();
  }

  // Obtener categorías ordenadas por prioridad
  List<Category> getCategoriesByPriority() {
    final categoriesCopy = List<Category>.from(state.categories);
    categoriesCopy.sort((a, b) => b.priority.compareTo(a.priority));
    return categoriesCopy;
  }

  // Refrescar datos
  Future<void> refresh() async {
    await loadCategories();
  }

  // Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Verificar si se puede eliminar una categoría
  bool canDeleteCategory(int categoryId) {
    // En una implementación real, verificarías si hay gastos asociados
    return true;
  }
}

// Provider del CategoryNotifier
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) {
    return CategoryNotifier(DatabaseService(), ref);
  },
);

// Providers derivados
final categoryListProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryProvider).categories;
});

final categoryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoryProvider).isLoading;
});

final activeCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryListProvider).where((cat) => cat.isActive).toList();
});

final categoriesWithBudgetProvider = Provider<List<Category>>((ref) {
  return ref.read(categoryProvider.notifier).getCategoriesWithBudget();
});

final categoriesByPriorityProvider = Provider<List<Category>>((ref) {
  return ref.read(categoryProvider.notifier).getCategoriesByPriority();
});

// Provider para obtener categoría por ID
final categoryByIdProvider = Provider.family<Category?, int>((ref, categoryId) {
  return ref.read(categoryProvider.notifier).getCategoryById(categoryId);
});

// Provider para búsqueda de categorías
final searchedCategoriesProvider = Provider.family<List<Category>, String>((
  ref,
  query,
) {
  return ref.read(categoryProvider.notifier).searchCategories(query);
});

// Provider para categorías por tipo
final categoriesByTypeProvider = Provider.family<List<Category>, CategoryType>((
  ref,
  type,
) {
  return ref.read(categoryProvider.notifier).getCategoriesByType(type);
});

// Colores predefinidos para categorías
final defaultCategoryColorsProvider = Provider<List<String>>((ref) {
  return [
    '#4CAF50', // Verde
    '#2196F3', // Azul
    '#FF9800', // Naranja
    '#F44336', // Rojo
    '#9C27B0', // Púrpura
    '#795548', // Marrón
    '#607D8B', // Azul gris
    '#E91E63', // Rosa
    '#00BCD4', // Cian
    '#FFC107', // Ámbar
    '#3F51B5', // Índigo
    '#8BC34A', // Verde claro
  ];
});

// Íconos predefinidos para categorías
final defaultCategoryIconsProvider = Provider<List<String>>((ref) {
  return [
    'restaurant',
    'directions_car',
    'movie',
    'local_hospital',
    'school',
    'home',
    'shopping_cart',
    'sports_soccer',
    'work',
    'flight',
    'pets',
    'phone',
    'computer',
    'fitness_center',
    'local_gas_station',
    'category',
  ];
});
