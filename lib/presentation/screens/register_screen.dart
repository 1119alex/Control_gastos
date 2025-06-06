import 'package:control_gastos/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custtom_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberSession = true;
  String _selectedCurrency = 'BOB';

  // Lista de monedas disponibles
  final List<Map<String, String>> _currencies = [
    {'code': 'BOB', 'name': 'Boliviano (Bs.)', 'symbol': 'Bs.'},
    {'code': 'USD', 'name': 'Dólar Americano (\$)', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro (€)', 'symbol': '€'},
    {'code': 'ARS', 'name': 'Peso Argentino (\$)', 'symbol': '\$'},
    {'code': 'BRL', 'name': 'Real Brasileño (R\$)', 'symbol': 'R\$'},
    {'code': 'CLP', 'name': 'Peso Chileno (\$)', 'symbol': '\$'},
  ];

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    ref.listenManual<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      if (next.isAuthenticated) {
        _navigateToHome();
      } else if (next.hasError) {
        _showErrorMessage(next.errorMessage!);
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          currency: _selectedCurrency,
          rememberSession: _rememberSession,
        );

    if (success) {
      _showSuccessMessage();
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Cuenta creada exitosamente! Bienvenido'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: AppSpacing.xl),

                // Formulario de registro
                _buildRegisterForm(),

                const SizedBox(height: AppSpacing.lg),

                // Selector de moneda
                _buildCurrencySelector(),

                const SizedBox(height: AppSpacing.lg),

                // Checkbox recordar sesión
                _buildRememberSession(),

                const SizedBox(height: AppSpacing.xl),

                // Botón de registro
                _buildRegisterButton(authState),

                const SizedBox(height: AppSpacing.lg),

                // Divisor
                _buildDivider(),

                const SizedBox(height: AppSpacing.lg),

                // Link para login
                _buildLoginLink(),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.person_add, size: 40, color: Colors.white),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Título
        const Text(
          'Crear Cuenta',
          style: AppTextStyles.h1,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Subtítulo
        Text(
          'Completa tus datos para comenzar',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Campo de nombre
        CustomTextField(
          controller: _nameController,
          label: 'Nombre completo',
          hintText: 'Ingresa tu nombre completo',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'El nombre es obligatorio';
            }
            if (value!.trim().length < 2) {
              return 'El nombre debe tener al menos 2 caracteres';
            }
            if (value.trim().length > 50) {
              return 'El nombre no puede tener más de 50 caracteres';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Campo de email
        EmailTextField(
          controller: _emailController,
          hintText: 'ejemplo@correo.com',
        ),

        const SizedBox(height: AppSpacing.md),

        // Campo de contraseña
        CustomTextField(
          controller: _passwordController,
          label: 'Contraseña',
          hintText: 'Crea una contraseña segura',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'La contraseña es obligatoria';
            }
            if (value!.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
              return 'La contraseña debe contener al menos una letra';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'La contraseña debe contener al menos un número';
            }
            return null;
          },
          helperText: 'Mínimo 6 caracteres, incluye letras y números',
        ),

        const SizedBox(height: AppSpacing.md),

        // Campo de confirmar contraseña
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirmar contraseña',
          hintText: 'Repite tu contraseña',
          obscureText: _obscureConfirmPassword,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Confirma tu contraseña';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moneda principal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCurrency = newValue;
                  });
                }
              },
              items: _currencies.map<DropdownMenuItem<String>>((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(
                        currency['symbol']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          currency['name']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Esta será la moneda por defecto para tus gastos',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRememberSession() {
    return Row(
      children: [
        Checkbox(
          value: _rememberSession,
          onChanged: (value) {
            setState(() {
              _rememberSession = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _rememberSession = !_rememberSession;
              });
            },
            child: Text(
              'Mantener sesión iniciada',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(AuthState authState) {
    return CustomButton(
      text: 'Crear Cuenta',
      onPressed: authState.isLoading ? null : _handleRegister,
      isLoading: authState.isLoading,
      icon: Icons.person_add,
      backgroundColor: AppTheme.secondaryColor,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'o',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: _navigateToLogin,
          child: const Text(
            'Inicia sesión',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
