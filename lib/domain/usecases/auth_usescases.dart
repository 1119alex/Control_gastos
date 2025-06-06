import '../entities/user.dart';

class AuthUsecases {
  AuthValidationResult validateRegistration({
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
    } else if (!_isValidEmail(email.trim())) {
      errors.add('El formato del email no es válido');
    }

    // Validar contraseña
    final passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      errors.addAll(passwordValidation.errors);
    }

    // Validar confirmación de contraseña
    if (password != confirmPassword) {
      errors.add('Las contraseñas no coinciden');
    }

    return AuthValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // Usecase: Validar datos de login
  AuthValidationResult validateLogin({
    required String email,
    required String password,
  }) {
    List<String> errors = [];

    // Validar email
    if (email.trim().isEmpty) {
      errors.add('El email es obligatorio');
    } else if (!_isValidEmail(email.trim())) {
      errors.add('El formato del email no es válido');
    }

    // Validar contraseña
    if (password.isEmpty) {
      errors.add('La contraseña es obligatoria');
    } else if (password.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres');
    }

    return AuthValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // Usecase: Validar fortaleza de contraseña
  PasswordValidationResult validatePassword(String password) {
    List<String> errors = [];
    int strength = 0;

    // Verificar longitud mínima
    if (password.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres');
    } else {
      strength += 1;
    }

    // Verificar si contiene letras
    if (RegExp(r'[A-Za-z]').hasMatch(password)) {
      strength += 1;
    } else {
      errors.add('La contraseña debe contener al menos una letra');
    }

    // Verificar si contiene números
    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength += 1;
    } else {
      errors.add('La contraseña debe contener al menos un número');
    }

    // Bonus: caracteres especiales (opcional)
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength += 1;
    }

    // Bonus: longitud mayor a 8
    if (password.length >= 8) {
      strength += 1;
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: _getPasswordStrength(strength),
    );
  }

  // Usecase: Crear usuario válido
  UserCreationResult createUser({
    required String name,
    required String email,
    required String hashedPassword,
    String currency = 'BOB',
  }) {
    // Validar datos básicos
    final user = User(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      currency: currency,
      createdAt: DateTime.now(),
    );

    // Verificar que el usuario sea válido
    if (!user.isValid) {
      return UserCreationResult(
        isSuccess: false,
        error: 'Los datos del usuario no son válidos',
      );
    }

    return UserCreationResult(isSuccess: true, user: user);
  }

  // Usecase: Verificar si puede cambiar contraseña
  bool canChangePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    // Verificar que la contraseña actual no esté vacía
    if (currentPassword.isEmpty) return false;

    // Verificar que la nueva contraseña sea válida
    final passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.isValid) return false;

    // Verificar que las contraseñas coincidan
    if (newPassword != confirmPassword) return false;

    // Verificar que la nueva contraseña sea diferente a la actual
    if (currentPassword == newPassword) return false;

    return true;
  }

  bool shouldShowTutorial(User user) {
    return user.isNewUser;
  }

  // Usecase: Obtener mensaje de bienvenida
  String getWelcomeMessage(User user) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return '$greeting, ${user.displayName}';
  }

  // Usecase: Verificar seguridad de la cuenta
  AccountSecurityStatus getAccountSecurityStatus(User user, String password) {
    final passwordValidation = validatePassword(password);

    if (passwordValidation.strength == PasswordStrength.weak) {
      return AccountSecurityStatus.weak;
    } else if (passwordValidation.strength == PasswordStrength.medium) {
      return AccountSecurityStatus.medium;
    } else {
      return AccountSecurityStatus.strong;
    }
  }

  // Métodos privados de ayuda
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  PasswordStrength _getPasswordStrength(int score) {
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

// Clases de resultado para los usecases
class AuthValidationResult {
  final bool isValid;
  final List<String> errors;

  const AuthValidationResult({required this.isValid, required this.errors});
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final PasswordStrength strength;

  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });
}

class UserCreationResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  const UserCreationResult({required this.isSuccess, this.user, this.error});
}

// Enums para estados
enum PasswordStrength { weak, medium, strong }

enum AccountSecurityStatus { weak, medium, strong }
