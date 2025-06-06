import 'dart:async';
import 'package:control_gastos/data/models/budget_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Versión de la base de datos
  static const int _databaseVersion = 4;
  static const String _databaseName = 'gestor_gastos.db';

  // Nombres de las tablas
  static const String _usersTable = 'users';
  static const String _categoriesTable = 'categories';
  static const String _expensesTable = 'expenses';
  static const String _receiptsTable = 'receipts';
  static const String _budgetsTable = 'budgets';
  // Obtener la instancia de la base de datos
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  // Crear las tablas cuando se crea la base de datos por primera vez
  Future<void> _onCreate(Database db, int version) async {
    print('📂 Creando base de datos versión $version');

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE $_usersTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'BOB',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Tabla de categorías
    await db.execute('''
      CREATE TABLE $_categoriesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#2196F3',
        icon TEXT NOT NULL DEFAULT 'category',
        default_budget REAL NOT NULL DEFAULT 0.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de gastos
    await db.execute('''
      CREATE TABLE $_expensesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        expense_date TEXT NOT NULL,
        location TEXT,
        establishment TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES $_categoriesTable (id),
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de comprobantes/recibos
    await db.execute('''
      CREATE TABLE $_receiptsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        original_filename TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES $_expensesTable (id) ON DELETE CASCADE
      )
    ''');
    // Tabla de presupuestos
    await db.execute('''
      CREATE TABLE $_budgetsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        limit_amount REAL NOT NULL,
        spent_amount REAL NOT NULL DEFAULT 0.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES $_categoriesTable (id),
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE,
        UNIQUE(category_id, month, year, user_id)
      )
    ''');

    // Crear índices para mejorar el rendimiento
    await _createIndexes(db);

    print('✅ Base de datos creada exitosamente');
  }

  // Crear índices para optimizar consultas
  Future<void> _createIndexes(Database db) async {
    print('📊 Creando índices...');

    await db.execute(
      'CREATE INDEX idx_expenses_user_id ON $_expensesTable(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_date ON $_expensesTable(expense_date)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON $_expensesTable(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_categories_user_id ON $_categoriesTable(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_receipts_expense_id ON $_receiptsTable(expense_id)',
    );
    await db.execute(
      'CREATE INDEX idx_budgets_user_id ON $_budgetsTable(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_budgets_period ON $_budgetsTable(month, year)',
    );
    await db.execute(
      'CREATE INDEX idx_budgets_category ON $_budgetsTable(category_id)',
    );
    print('✅ Índices creados');
  }

  // Manejar actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de v$oldVersion a v$newVersion');
    // Aquí manejaremos las migraciones en futuras versiones
  }

  // Configuración al abrir la base de datos
  Future<void> _onOpen(Database db) async {
    // Habilitar foreign keys en SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Crear usuario
  Future<int> insertUser(UserModel user) async {
    try {
      final db = await database;
      final id = await db.insert(_usersTable, user.toMap());
      print('✅ Usuario creado con ID: $id');
      return id;
    } catch (e) {
      print('❌ Error creando usuario: $e');
      throw Exception('Error al crear usuario: $e');
    }
  }

  // Obtener usuario por email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _usersTable,
        where: 'email = ? AND is_active = ?',
        whereArgs: [email.toLowerCase(), 1],
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  // Obtener usuario por ID
  Future<UserModel?> getUserById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _usersTable,
        where: 'id = ? AND is_active = ?',
        whereArgs: [id, 1],
      );

      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario por ID: $e');
      return null;
    }
  }

  // Actualizar usuario
  Future<void> updateUser(UserModel user) async {
    try {
      final db = await database;
      await db.update(
        _usersTable,
        user.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      print('✅ Usuario actualizado: ${user.email}');
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // MÉTODOS PARA CATEGORÍAS
  // Crear categoría
  Future<int> insertCategory(CategoryModel category) async {
    try {
      final db = await database;
      final id = await db.insert(_categoriesTable, category.toMap());
      print('✅ Categoría creada: ${category.name}');
      return id;
    } catch (e) {
      print('❌ Error creando categoría: $e');
      throw Exception('Error al crear categoría: $e');
    }
  }

  // Obtener categorías de un usuario
  Future<List<CategoryModel>> getCategoriesByUser(int userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _categoriesTable,
        where: 'user_id = ? AND is_active = ?',
        whereArgs: [userId, 1],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return CategoryModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  // Actualizar categoría
  Future<void> updateCategory(CategoryModel category) async {
    try {
      final db = await database;
      await db.update(
        _categoriesTable,
        category.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      print('✅ Categoría actualizada: ${category.name}');
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  // Eliminar categoría (soft delete)
  Future<void> deleteCategory(int categoryId) async {
    try {
      final db = await database;
      await db.update(
        _categoriesTable,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      print('✅ Categoría eliminada (soft delete): $categoryId');
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  // MÉTODOS PARA GASTOS
  // Crear gasto
  Future<int> insertExpense(ExpenseModel expense) async {
    try {
      final db = await database;
      final id = await db.insert(_expensesTable, expense.toMap());
      print('✅ Gasto creado: ${expense.description}');
      return id;
    } catch (e) {
      print('❌ Error creando gasto: $e');
      throw Exception('Error al crear gasto: $e');
    }
  }

  // Obtener gastos de un usuario
  Future<List<ExpenseModel>> getExpensesByUser(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _expensesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'expense_date DESC, created_at DESC',
        limit: limit,
        offset: offset,
      );

      return List.generate(maps.length, (i) {
        return ExpenseModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo gastos: $e');
      return [];
    }
  }

  // Obtener gastos por categoría
  Future<List<ExpenseModel>> getExpensesByCategory(
    int userId,
    int categoryId,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _expensesTable,
        where: 'user_id = ? AND category_id = ?',
        whereArgs: [userId, categoryId],
        orderBy: 'expense_date DESC',
      );

      return List.generate(maps.length, (i) {
        return ExpenseModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo gastos por categoría: $e');
      return [];
    }
  }

  // Obtener gastos por rango de fechas
  Future<List<ExpenseModel>> getExpensesByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _expensesTable,
        where: 'user_id = ? AND expense_date BETWEEN ? AND ?',
        whereArgs: [
          userId,
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0],
        ],
        orderBy: 'expense_date DESC',
      );

      return List.generate(maps.length, (i) {
        return ExpenseModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo gastos por fecha: $e');
      return [];
    }
  }

  // Actualizar gasto
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final db = await database;
      await db.update(
        _expensesTable,
        expense.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      print('✅ Gasto actualizado: ${expense.description}');
    } catch (e) {
      print('❌ Error actualizando gasto: $e');
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> deleteExpense(int expenseId) async {
    try {
      final db = await database;
      await db.delete(_expensesTable, where: 'id = ?', whereArgs: [expenseId]);
      print('✅ Gasto eliminado: $expenseId');
    } catch (e) {
      print('❌ Error eliminando gasto: $e');
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // MÉTODOS DE UTILIDAD
  // Obtener estadísticas de la base de datos
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await database;

      final userCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $_usersTable WHERE is_active = 1',
            ),
          ) ??
          0;

      final categoryCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $_categoriesTable WHERE is_active = 1',
            ),
          ) ??
          0;

      final expenseCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_expensesTable'),
          ) ??
          0;

      return {
        'users': userCount,
        'categories': categoryCount,
        'expenses': expenseCount,
        'version': await db.getVersion(),
        'path': db.path,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  // Cerrar la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Base de datos cerrada');
  }

  // Eliminar la base de datos (útil para desarrollo/testing)
  Future<void> deleteDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      await databaseFactory.deleteDatabase(path);
      _database = null;
      print('🗑️ Base de datos eliminada');
    } catch (e) {
      print('❌ Error eliminando base de datos: $e');
    }
  }

  // MÉTODOS PARA PRESUPUESTOS
  // Crear presupuesto
  Future<int> insertBudget(BudgetModel budget) async {
    try {
      final db = await database;
      final id = await db.insert(_budgetsTable, budget.toMap());
      print('✅ Presupuesto creado con ID: $id');
      return id;
    } catch (e) {
      print('❌ Error creando presupuesto: $e');
      throw Exception('Error al crear presupuesto: $e');
    }
  }

  // Obtener presupuestos de un usuario
  Future<List<BudgetModel>> getBudgetsByUser(int userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _budgetsTable,
        where: 'user_id = ? AND is_active = ?',
        whereArgs: [userId, 1],
        orderBy: 'year DESC, month DESC',
      );

      return List.generate(maps.length, (i) {
        return BudgetModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo presupuestos: $e');
      return [];
    }
  }

  // Obtener presupuestos por período
  Future<List<BudgetModel>> getBudgetsByPeriod(
    int userId,
    int month,
    int year,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _budgetsTable,
        where: 'user_id = ? AND month = ? AND year = ? AND is_active = ?',
        whereArgs: [userId, month, year, 1],
        orderBy: 'category_id ASC',
      );

      return List.generate(maps.length, (i) {
        return BudgetModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo presupuestos por período: $e');
      return [];
    }
  }

  // Obtener presupuestos por categoría
  Future<List<BudgetModel>> getBudgetsByCategory(
    int userId,
    int categoryId,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _budgetsTable,
        where: 'user_id = ? AND category_id = ? AND is_active = ?',
        whereArgs: [userId, categoryId, 1],
        orderBy: 'year DESC, month DESC',
      );

      return List.generate(maps.length, (i) {
        return BudgetModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error obteniendo presupuestos por categoría: $e');
      return [];
    }
  }

  // Obtener presupuesto específico
  Future<BudgetModel?> getBudget(
    int userId,
    int categoryId,
    int month,
    int year,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _budgetsTable,
        where:
            'user_id = ? AND category_id = ? AND month = ? AND year = ? AND is_active = ?',
        whereArgs: [userId, categoryId, month, year, 1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return BudgetModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo presupuesto específico: $e');
      return null;
    }
  }

  // Actualizar presupuesto
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      final db = await database;
      await db.update(
        _budgetsTable,
        budget.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
      print('✅ Presupuesto actualizado: ${budget.id}');
    } catch (e) {
      print('❌ Error actualizando presupuesto: $e');
      throw Exception('Error al actualizar presupuesto: $e');
    }
  }

  // Actualizar solo el monto gastado
  Future<void> updateBudgetSpentAmount(int budgetId, double spentAmount) async {
    try {
      final db = await database;
      await db.update(
        _budgetsTable,
        {
          'spent_amount': spentAmount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [budgetId],
      );
      print('✅ Monto gastado actualizado para presupuesto $budgetId');
    } catch (e) {
      print('❌ Error actualizando monto gastado: $e');
      throw Exception('Error al actualizar monto gastado: $e');
    }
  }

  // Eliminar presupuesto (soft delete)
  Future<void> deleteBudget(int budgetId) async {
    try {
      final db = await database;
      await db.update(
        _budgetsTable,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [budgetId],
      );
      print('✅ Presupuesto eliminado (soft delete): $budgetId');
    } catch (e) {
      print('❌ Error eliminando presupuesto: $e');
      throw Exception('Error al eliminar presupuesto: $e');
    }
  }

  // Obtener estadísticas de presupuestos
  Future<Map<String, dynamic>> getBudgetStats(int userId) async {
    try {
      final db = await database;

      // Total de presupuestos activos
      final totalBudgets =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $_budgetsTable WHERE user_id = ? AND is_active = 1',
              [userId],
            ),
          ) ??
          0;

      // Total límite establecido
      final totalLimit = await db.rawQuery(
        'SELECT SUM(limit_amount) as total FROM $_budgetsTable WHERE user_id = ? AND is_active = 1',
        [userId],
      );
      final limitAmount =
          (totalLimit.first['total'] as num?)?.toDouble() ?? 0.0;

      // Total gastado
      final totalSpent = await db.rawQuery(
        'SELECT SUM(spent_amount) as total FROM $_budgetsTable WHERE user_id = ? AND is_active = 1',
        [userId],
      );
      final spentAmount =
          (totalSpent.first['total'] as num?)?.toDouble() ?? 0.0;

      // Presupuestos excedidos
      final exceededBudgets =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $_budgetsTable WHERE user_id = ? AND is_active = 1 AND spent_amount > limit_amount',
              [userId],
            ),
          ) ??
          0;

      return {
        'total_budgets': totalBudgets,
        'total_limit': limitAmount,
        'total_spent': spentAmount,
        'total_remaining': limitAmount - spentAmount,
        'exceeded_budgets': exceededBudgets,
        'healthy_budgets': totalBudgets - exceededBudgets,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de presupuestos: $e');
      return {};
    }
  }

  // Actualizar montos gastados basado en gastos
  Future<void> recalculateBudgetSpentAmounts(int userId) async {
    try {
      final db = await database;

      // Obtener todos los presupuestos activos del usuario
      final budgets = await getBudgetsByUser(userId);

      for (final budget in budgets) {
        // Calcular el gasto real para este presupuesto
        final spentResult = await db.rawQuery(
          '''
          SELECT SUM(amount) as total 
          FROM $_expensesTable 
          WHERE user_id = ? 
            AND category_id = ? 
            AND strftime('%m', expense_date) = ? 
            AND strftime('%Y', expense_date) = ?
        ''',
          [
            userId,
            budget.categoryId,
            budget.month.toString().padLeft(2, '0'),
            budget.year.toString(),
          ],
        );

        final actualSpent =
            (spentResult.first['total'] as num?)?.toDouble() ?? 0.0;

        // Actualizar el presupuesto con el monto real
        await updateBudgetSpentAmount(budget.id!, actualSpent);
      }

      print('✅ Montos gastados recalculados para usuario $userId');
    } catch (e) {
      print('❌ Error recalculando montos gastados: $e');
      throw Exception('Error al recalcular montos gastados: $e');
    }
  }

  // Obtener resumen de presupuesto por categoría
  Future<List<Map<String, dynamic>>> getBudgetSummaryByCategory(
    int userId,
    int month,
    int year,
  ) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        '''
        SELECT 
          b.category_id,
          c.name as category_name,
          c.color as category_color,
          b.limit_amount,
          b.spent_amount,
          (b.limit_amount - b.spent_amount) as remaining_amount,
          CASE 
            WHEN b.spent_amount > b.limit_amount THEN 'exceeded'
            WHEN (b.spent_amount / b.limit_amount * 100) >= 90 THEN 'at_risk'
            WHEN (b.spent_amount / b.limit_amount * 100) >= 80 THEN 'near_limit'
            ELSE 'healthy'
          END as status
        FROM $_budgetsTable b
        INNER JOIN $_categoriesTable c ON b.category_id = c.id
        WHERE b.user_id = ? AND b.month = ? AND b.year = ? AND b.is_active = 1
        ORDER BY b.spent_amount DESC
      ''',
        [userId, month, year],
      );

      return result;
    } catch (e) {
      print('❌ Error obteniendo resumen por categoría: $e');
      return [];
    }
  }

  // Verificar si existe presupuesto duplicado
  Future<bool> budgetExists(
    int userId,
    int categoryId,
    int month,
    int year,
  ) async {
    try {
      final db = await database;
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $_budgetsTable WHERE user_id = ? AND category_id = ? AND month = ? AND year = ? AND is_active = 1',
              [userId, categoryId, month, year],
            ),
          ) ??
          0;

      return count > 0;
    } catch (e) {
      print('❌ Error verificando existencia de presupuesto: $e');
      return false;
    }
  }
}
