import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class AuthService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserCurrency = 'user_currency';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyRememberSession = 'remember_session';
  static const String _keyLoginTimestamp = 'login_timestamp';
  static const String _keySessionToken = 'session_token';

  // Hashear contraseña
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verificar si una contraseña coincide con su hash
  bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  // Generar token de sesión único
  String generateSessionToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final tokenLength = 32;

    return List.generate(
      tokenLength,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Generar salt para mayor seguridad (opcional para futuras mejoras)
  String generateSalt() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      16,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // GESTIÓN DE SESIONES
  // Guardar sesión del usuario en SharedPreferences
  Future<void> saveUserSession({
    required UserModel user,
    required bool rememberSession,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = generateSessionToken();

      if (rememberSession) {
        await prefs.setInt(_keyUserId, user.id!);
        await prefs.setString(_keyUserEmail, user.email);
        await prefs.setString(_keyUserName, user.name);
        await prefs.setString(_keyUserCurrency, user.currency);
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setBool(_keyRememberSession, true);
        await prefs.setString(
          _keyLoginTimestamp,
          DateTime.now().toIso8601String(),
        );
        await prefs.setString(_keySessionToken, sessionToken);

        print('✅ Sesión persistente guardada para: ${user.email}');
      } else {
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setBool(_keyRememberSession, false);
        await prefs.setString(_keySessionToken, sessionToken);

        print('✅ Sesión temporal para: ${user.email}');
      }
    } catch (e) {
      print('❌ Error guardando sesión: $e');
      throw Exception('Error al guardar la sesión del usuario');
    }
  }

  // Verificar si hay una sesión activa
  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      bool rememberSession = prefs.getBool(_keyRememberSession) ?? false;

      if (isLoggedIn && rememberSession) {
        String? loginTimestamp = prefs.getString(_keyLoginTimestamp);
        if (loginTimestamp != null) {
          DateTime loginTime = DateTime.parse(loginTimestamp);
          DateTime now = DateTime.now();

          if (now.difference(loginTime).inDays > 30) {
            await clearUserSession();
            return false;
          }
        }

        // Verificar que el token de sesión exista
        String? sessionToken = prefs.getString(_keySessionToken);
        if (sessionToken == null || sessionToken.isEmpty) {
          await clearUserSession();
          return false;
        }

        return true;
      }

      return isLoggedIn;
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      return false;
    }
  }

  // Obtener datos del usuario de la sesión actual
  Future<Map<String, dynamic>?> getCurrentUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (await isUserLoggedIn()) {
        int? userId = prefs.getInt(_keyUserId);
        String? userEmail = prefs.getString(_keyUserEmail);
        String? userName = prefs.getString(_keyUserName);
        String? userCurrency = prefs.getString(_keyUserCurrency);
        String? sessionToken = prefs.getString(_keySessionToken);

        if (userId != null) {
          return {
            'id': userId,
            'email': userEmail,
            'name': userName,
            'currency': userCurrency ?? 'BOB',
            'session_token': sessionToken,
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo sesión actual: $e');
      return null;
    }
  }

  // Obtener ID del usuario actual
  Future<int?> getCurrentUserId() async {
    try {
      final sessionData = await getCurrentUserSession();
      return sessionData?['id'];
    } catch (e) {
      print('❌ Error obteniendo user ID: $e');
      return null;
    }
  }

  // Actualizar información de la sesión
  Future<void> updateUserSession({String? name, String? currency}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (await isUserLoggedIn()) {
        if (name != null) {
          await prefs.setString(_keyUserName, name);
        }
        if (currency != null) {
          await prefs.setString(_keyUserCurrency, currency);
        }

        // Actualizar timestamp de última actividad
        await prefs.setString(
          _keyLoginTimestamp,
          DateTime.now().toIso8601String(),
        );

        print('✅ Sesión actualizada');
      }
    } catch (e) {
      print('❌ Error actualizando sesión: $e');
    }
  }

  // Limpiar la sesión del usuario (logout)
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limpiar todas las claves relacionadas con la sesión
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserCurrency);
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyRememberSession);
      await prefs.remove(_keyLoginTimestamp);
      await prefs.remove(_keySessionToken);

      print('✅ Sesión limpiada correctamente');
    } catch (e) {
      print('❌ Error limpiando sesión: $e');
      throw Exception('Error al cerrar la sesión');
    }
  }

  // VALIDACIONES
  // Validar formato de email
  bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Validar fortaleza de contraseña
  Map<String, dynamic> validatePassword(String password) {
    bool isValid = true;
    List<String> errors = [];
    int strength = 0;

    // Verificar longitud mínima
    if (password.length < 6) {
      isValid = false;
      errors.add('La contraseña debe tener al menos 6 caracteres');
    } else {
      strength += 1;
    }

    // Verificar si contiene letras
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      isValid = false;
      errors.add('La contraseña debe contener al menos una letra');
    } else {
      strength += 1;
    }

    // Verificar si contiene números
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      isValid = false;
      errors.add('La contraseña debe contener al menos un número');
    } else {
      strength += 1;
    }

    // caracteres especiales
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength += 1;
    }

    //  longitud mayor a 8
    if (password.length >= 8) {
      strength += 1;
    }

    return {
      'isValid': isValid,
      'errors': errors,
      'strength': _getPasswordStrength(strength),
      'score': strength,
    };
  }

  // Obtener nivel de fortaleza de contraseña
  String _getPasswordStrength(int score) {
    if (score <= 2) return 'Débil';
    if (score <= 4) return 'Media';
    return 'Fuerte';
  }

  // Validar datos de registro
  Map<String, dynamic> validateRegistration({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    List<String> errors = [];

    // Validar nombre
    if (name.trim().isEmpty) {
      errors.add('El nombre es obligatorio');
    } else if (name.trim().length < 2) {
      errors.add('El nombre debe tener al menos 2 caracteres');
    } else if (name.trim().length > 50) {
      errors.add('El nombre no puede tener más de 50 caracteres');
    }

    // Validar email
    if (email.trim().isEmpty) {
      errors.add('El email es obligatorio');
    } else if (!isValidEmail(email.trim())) {
      errors.add('El formato del email no es válido');
    }

    // Validar contraseña
    if (password.isEmpty) {
      errors.add('La contraseña es obligatoria');
    } else {
      final passwordValidation = validatePassword(password);
      if (!passwordValidation['isValid']) {
        errors.addAll(passwordValidation['errors']);
      }
    }

    // Validar confirmación de contraseña
    if (password != confirmPassword) {
      errors.add('Las contraseñas no coinciden');
    }

    return {'isValid': errors.isEmpty, 'errors': errors};
  }

  // Validar datos de login
  Map<String, dynamic> validateLogin({
    required String email,
    required String password,
  }) {
    List<String> errors = [];

    // Validar email
    if (email.trim().isEmpty) {
      errors.add('El email es obligatorio');
    } else if (!isValidEmail(email.trim())) {
      errors.add('El formato del email no es válido');
    }

    // Validar contraseña
    if (password.isEmpty) {
      errors.add('La contraseña es obligatoria');
    } else if (password.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres');
    }

    return {'isValid': errors.isEmpty, 'errors': errors};
  }

  // UTILIDADES DE SESIÓN

  Future<void> updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await isUserLoggedIn()) {
        await prefs.setString(
          _keyLoginTimestamp,
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('❌ Error actualizando última actividad: $e');
    }
  }

  // Verificar si la sesión está cerca de expirar (25 días)
  Future<bool> isSessionNearExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? loginTimestamp = prefs.getString(_keyLoginTimestamp);

      if (loginTimestamp != null) {
        DateTime loginTime = DateTime.parse(loginTimestamp);
        DateTime now = DateTime.now();

        return now.difference(loginTime).inDays >= 25;
      }

      return false;
    } catch (e) {
      print('❌ Error verificando expiración de sesión: $e');
      return false;
    }
  }

  // Extender sesión (renovar timestamp)
  Future<void> extendSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await isUserLoggedIn()) {
        await prefs.setString(
          _keyLoginTimestamp,
          DateTime.now().toIso8601String(),
        );
        print('✅ Sesión extendida');
      }
    } catch (e) {
      print('❌ Error extendiendo sesión: $e');
    }
  }

  // Obtener información de la sesión para debugging
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'is_logged_in': prefs.getBool(_keyIsLoggedIn) ?? false,
        'remember_session': prefs.getBool(_keyRememberSession) ?? false,
        'user_id': prefs.getInt(_keyUserId),
        'user_email': prefs.getString(_keyUserEmail),
        'user_name': prefs.getString(_keyUserName),
        'user_currency': prefs.getString(_keyUserCurrency),
        'login_timestamp': prefs.getString(_keyLoginTimestamp),
        'session_token':
            '${prefs.getString(_keySessionToken)?.substring(0, 8)}...',
        'session_age_days': _getSessionAgeDays(),
      };
    } catch (e) {
      print('❌ Error obteniendo info de sesión: $e');
      return {};
    }
  }

  // Obtener edad de la sesión en días
  Future<int> _getSessionAgeDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? loginTimestamp = prefs.getString(_keyLoginTimestamp);

      if (loginTimestamp != null) {
        DateTime loginTime = DateTime.parse(loginTimestamp);
        DateTime now = DateTime.now();
        return now.difference(loginTime).inDays;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  // SEGURIDAD ADICIONAL
  Future<bool> verifySessionIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      int? userId = prefs.getInt(_keyUserId);
      String? sessionToken = prefs.getString(_keySessionToken);

      if (isLoggedIn) {
        return userId != null &&
            sessionToken != null &&
            sessionToken.isNotEmpty;
      }

      return true;
    } catch (e) {
      print('❌ Error verificando integridad de sesión: $e');
      return false;
    }
  }

  // Limpiar sesión si está corrupta
  Future<void> cleanupCorruptedSession() async {
    try {
      if (!await verifySessionIntegrity()) {
        print('⚠️ Sesión corrupta detectada, limpiando...');
        await clearUserSession();
      }
    } catch (e) {
      print('❌ Error limpiando sesión corrupta: $e');
    }
  }
}
