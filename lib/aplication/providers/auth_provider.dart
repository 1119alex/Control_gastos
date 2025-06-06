import 'package:control_gastos/data/models/category_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/database_services.dart';
import '../../data/services/storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_usescases.dart';
import '../services/auth_service.dart';

// Estado de autenticación
enum AuthStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error && errorMessage != null;
  bool get isChecking => status == AuthStatus.checking;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final DatabaseService _databaseService;
  final StorageService _storageService;
  final AuthService _authService;
  final AuthUsecases _authUsecases;

  AuthNotifier(
    this._databaseService,
    this._storageService,
    this._authService,
    this._authUsecases,
  ) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(status: AuthStatus.checking);

      final isLoggedIn = await _storageService.isUserLoggedIn();

      if (isLoggedIn) {
        final sessionData = await _storageService.getCurrentUserSession();
        if (sessionData != null) {
          final userModel = await _databaseService.getUserById(
            sessionData.userId,
          );
          if (userModel != null) {
            state = state.copyWith(
              status: AuthStatus.authenticated,
              user: userModel.toEntity(),
            );
            return;
          }
        }
      }

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      print('❌ Error verificando estado de auth: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al verificar la sesión',
      );
    }
  }

  // Registro de usuario
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String currency = 'BOB',
    bool rememberSession = true,
  }) async {
    try {
      state = state.copyWith(
        status: AuthStatus.loading,
        isLoading: true,
        errorMessage: null,
      );

      // Validar datos de registro
      final validation = _authUsecases.validateRegistration(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (!validation.isValid) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: validation.errors.first,
          isLoading: false,
        );
        return false;
      }

      // Verificar que el email no exista
      final existingUser = await _databaseService.getUserByEmail(email);
      if (existingUser != null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Ya existe una cuenta con este email',
          isLoading: false,
        );
        return false;
      }

      // Crear usuario
      final hashedPassword = _authService.hashPassword(password);
      final userCreation = _authUsecases.createUser(
        name: name,
        email: email,
        hashedPassword: hashedPassword,
        currency: currency,
      );

      if (!userCreation.isSuccess) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: userCreation.error ?? 'Error al crear usuario',
          isLoading: false,
        );
        return false;
      }

      // Guardar en base de datos
      final userModel = UserModel.fromEntity(
        userCreation.user!,
        hashedPassword,
      );
      final userId = await _databaseService.insertUser(userModel);

      // Crear categorías predefinidas
      await _createDefaultCategories(userId);

      // Guardar sesión
      await _storageService.saveUserSession(
        userId: userId,
        email: email,
        name: name,
        currency: currency,
        rememberSession: rememberSession,
      );

      // Actualizar estado
      final finalUser = userModel.copyWith(id: userId);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: finalUser.toEntity(),
        isLoading: false,
      );

      print('✅ Usuario registrado exitosamente: $email');
      return true;
    } catch (e) {
      print('❌ Error en registro: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al registrar usuario: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  // Login de usuario
  Future<bool> login({
    required String email,
    required String password,
    bool rememberSession = true,
  }) async {
    try {
      state = state.copyWith(
        status: AuthStatus.loading,
        isLoading: true,
        errorMessage: null,
      );

      // Validar datos de login
      final validation = _authUsecases.validateLogin(
        email: email,
        password: password,
      );

      if (!validation.isValid) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: validation.errors.first,
          isLoading: false,
        );
        return false;
      }

      // Buscar usuario
      final userModel = await _databaseService.getUserByEmail(email);
      if (userModel == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Email o contraseña incorrectos',
          isLoading: false,
        );
        return false;
      }

      // Verificar contraseña
      if (!_authService.verifyPassword(password, userModel.passwordHash)) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Email o contraseña incorrectos',
          isLoading: false,
        );
        return false;
      }

      // Guardar sesión
      await _storageService.saveUserSession(
        userId: userModel.id!,
        email: userModel.email,
        name: userModel.name,
        currency: userModel.currency,
        rememberSession: rememberSession,
      );

      // Actualizar estado
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userModel.toEntity(),
        isLoading: false,
      );

      print('✅ Login exitoso: $email');
      return true;
    } catch (e) {
      print('❌ Error en login: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al iniciar sesión: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _storageService.clearUserSession();

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
        isLoading: false,
      );

      print('✅ Logout exitoso');
    } catch (e) {
      print('❌ Error en logout: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al cerrar sesión',
        isLoading: false,
      );
    }
  }

  // Actualizar información del usuario
  Future<bool> updateUser({String? name, String? currency}) async {
    try {
      if (state.user == null) return false;

      state = state.copyWith(isLoading: true);

      final currentUser = state.user!;
      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        currency: currency ?? currentUser.currency,
      );

      // Actualizar en base de datos
      final userModel = UserModel.fromEntity(updatedUser, '');
      await _databaseService.updateUser(userModel);

      // Actualizar sesión
      await _storageService.updateUserSession(name: name, currency: currency);

      // Actualizar estado
      state = state.copyWith(user: updatedUser, isLoading: false);

      print('✅ Usuario actualizado');
      return true;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      state = state.copyWith(
        errorMessage: 'Error al actualizar usuario',
        isLoading: false,
      );
      return false;
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (state.user == null) return false;

      state = state.copyWith(isLoading: true);

      // Validar que puede cambiar contraseña
      if (!_authUsecases.canChangePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      )) {
        state = state.copyWith(
          errorMessage: 'Datos de contraseña inválidos',
          isLoading: false,
        );
        return false;
      }

      // Obtener usuario actual de la base de datos
      final userModel = await _databaseService.getUserById(state.user!.id!);
      if (userModel == null ||
          !_authService.verifyPassword(
            currentPassword,
            userModel.passwordHash,
          )) {
        state = state.copyWith(
          errorMessage: 'La contraseña actual es incorrecta',
          isLoading: false,
        );
        return false;
      }

      // Actualizar contraseña
      final newHashedPassword = _authService.hashPassword(newPassword);
      final updatedUserModel = userModel.copyWith(
        passwordHash: newHashedPassword,
      );
      await _databaseService.updateUser(updatedUserModel);

      state = state.copyWith(isLoading: false);
      print('✅ Contraseña actualizada');
      return true;
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      state = state.copyWith(
        errorMessage: 'Error al cambiar contraseña',
        isLoading: false,
      );
      return false;
    }
  }

  // Crear categorías predefinidas para nuevo usuario
  Future<void> _createDefaultCategories(int userId) async {
    try {
      final defaultCategories = CategoryModel.getDefaultCategories(userId);

      for (final category in defaultCategories) {
        await _databaseService.insertCategory(category);
      }

      print('✅ Categorías predefinidas creadas para usuario $userId');
    } catch (e) {
      print('❌ Error creando categorías predefinidas: $e');
    }
  }

  // Limpiar error
  void clearError() {
    state = state.copyWith(
      errorMessage: null,
      status: state.user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
    );
  }

  // Obtener mensaje de bienvenida
  String getWelcomeMessage() {
    if (state.user != null) {
      return _authUsecases.getWelcomeMessage(state.user!);
    }
    return 'Bienvenido';
  }

  bool shouldShowTutorial() {
    if (state.user != null) {
      return _authUsecases.shouldShowTutorial(state.user!);
    }
    return false;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    DatabaseService(),
    StorageService(),
    AuthService(),
    AuthUsecases(),
  );
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
