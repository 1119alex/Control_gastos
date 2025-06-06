import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Claves para SharedPreferences
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserCurrency = 'user_currency';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyRememberSession = 'remember_session';
  static const String _keyLoginTimestamp = 'login_timestamp';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';

  // =============================================
  // MÉTODOS DE SESIÓN DE USUARIO
  // =============================================

  // Guardar sesión del usuario
  Future<void> saveUserSession({
    required int userId,
    required String email,
    required String name,
    required String currency,
    required bool rememberSession,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserName, name);
      await prefs.setString(_keyUserCurrency, currency);
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setBool(_keyRememberSession, rememberSession);
      await prefs.setString(
        _keyLoginTimestamp,
        DateTime.now().toIso8601String(),
      );

      print('✅ Sesión guardada para: $email');
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
        // Verificar si la sesión no es muy antigua (30 días)
        String? loginTimestamp = prefs.getString(_keyLoginTimestamp);
        if (loginTimestamp != null) {
          DateTime loginTime = DateTime.parse(loginTimestamp);
          DateTime now = DateTime.now();

          if (now.difference(loginTime).inDays > 30) {
            await clearUserSession();
            return false;
          }
        }

        return true;
      }

      return isLoggedIn;
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      return false;
    }
  }

  // Obtener datos de la sesión actual
  Future<UserSessionData?> getCurrentUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (await isUserLoggedIn()) {
        int? userId = prefs.getInt(_keyUserId);
        String? userEmail = prefs.getString(_keyUserEmail);
        String? userName = prefs.getString(_keyUserName);
        String? userCurrency = prefs.getString(_keyUserCurrency);

        if (userId != null && userEmail != null && userName != null) {
          return UserSessionData(
            userId: userId,
            email: userEmail,
            name: userName,
            currency: userCurrency ?? 'BOB',
          );
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
      return sessionData?.userId;
    } catch (e) {
      print('❌ Error obteniendo user ID: $e');
      return null;
    }
  }

  // Actualizar información del usuario en sesión
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

        print('✅ Sesión de usuario actualizada');
      }
    } catch (e) {
      print('❌ Error actualizando sesión: $e');
    }
  }

  // Limpiar la sesión del usuario (logout)
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserCurrency);
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyRememberSession);
      await prefs.remove(_keyLoginTimestamp);

      print('✅ Sesión limpiada correctamente');
    } catch (e) {
      print('❌ Error limpiando sesión: $e');
      throw Exception('Error al cerrar la sesión');
    }
  }

  // Actualizar timestamp de última actividad
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

  // =============================================
  // CONFIGURACIONES DE LA APP
  // =============================================

  // Verificar si es la primera vez que se abre la app
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyFirstLaunch) ?? true;
    } catch (e) {
      print('❌ Error verificando primer lanzamiento: $e');
      return true;
    }
  }

  // Marcar que ya no es el primer lanzamiento
  Future<void> setFirstLaunchCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstLaunch, false);
      print('✅ Primer lanzamiento marcado como completado');
    } catch (e) {
      print('❌ Error marcando primer lanzamiento: $e');
    }
  }

  // Guardar modo de tema (claro/oscuro)
  Future<void> saveThemeMode(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, themeMode);
      print('✅ Modo de tema guardado: $themeMode');
    } catch (e) {
      print('❌ Error guardando tema: $e');
    }
  }

  // Obtener modo de tema
  Future<String> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyThemeMode) ?? 'system';
    } catch (e) {
      print('❌ Error obteniendo tema: $e');
      return 'system';
    }
  }

  // Guardar idioma preferido
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, language);
      print('✅ Idioma guardado: $language');
    } catch (e) {
      print('❌ Error guardando idioma: $e');
    }
  }

  // Obtener idioma preferido
  Future<String> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLanguage) ?? 'es';
    } catch (e) {
      print('❌ Error obteniendo idioma: $e');
      return 'es';
    }
  }

  // =============================================
  // MÉTODOS DE UTILIDAD
  // =============================================

  // Obtener todas las preferencias (para debugging)
  Future<Map<String, dynamic>> getAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      Map<String, dynamic> allPrefs = {};

      for (String key in keys) {
        allPrefs[key] = prefs.get(key);
      }

      return allPrefs;
    } catch (e) {
      print('❌ Error obteniendo preferencias: $e');
      return {};
    }
  }

  // Limpiar todas las preferencias (factory reset)
  Future<void> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ Todas las preferencias limpiadas');
    } catch (e) {
      print('❌ Error limpiando preferencias: $e');
      throw Exception('Error al limpiar las preferencias');
    }
  }

  // Exportar preferencias (para backup)
  Future<Map<String, dynamic>> exportPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exportData = <String, dynamic>{};

      // Solo exportar datos no sensibles
      exportData['theme_mode'] = prefs.getString(_keyThemeMode);
      exportData['language'] = prefs.getString(_keyLanguage);
      exportData['first_launch'] = prefs.getBool(_keyFirstLaunch);

      return exportData;
    } catch (e) {
      print('❌ Error exportando preferencias: $e');
      return {};
    }
  }

  // Importar preferencias (restaurar backup)
  Future<void> importPreferences(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (data.containsKey('theme_mode')) {
        await prefs.setString(_keyThemeMode, data['theme_mode']);
      }
      if (data.containsKey('language')) {
        await prefs.setString(_keyLanguage, data['language']);
      }
      if (data.containsKey('first_launch')) {
        await prefs.setBool(_keyFirstLaunch, data['first_launch']);
      }

      print('✅ Preferencias importadas correctamente');
    } catch (e) {
      print('❌ Error importando preferencias: $e');
      throw Exception('Error al importar las preferencias');
    }
  }
}

// Clase para datos de sesión de usuario
class UserSessionData {
  final int userId;
  final String email;
  final String name;
  final String currency;

  const UserSessionData({
    required this.userId,
    required this.email,
    required this.name,
    required this.currency,
  });

  @override
  String toString() {
    return 'UserSessionData(userId: $userId, email: $email, name: $name, currency: $currency)';
  }
}
