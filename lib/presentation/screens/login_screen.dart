import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custtom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberSession = true;

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberSession: _rememberSession,
        );

    if (success) {
      // La navegación se maneja en el listener
      _showSuccessMessage();
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Bienvenido!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),

                // Logo y título
                _buildHeader(),

                const SizedBox(height: AppSpacing.xxl),

                // Formulario de login
                _buildLoginForm(),

                const SizedBox(height: AppSpacing.lg),

                // Checkbox recordar sesión
                _buildRememberSession(),

                const SizedBox(height: AppSpacing.xl),

                // Botón de login
                _buildLoginButton(authState),

                const SizedBox(height: AppSpacing.lg),

                // Divisor
                _buildDivider(),

                const SizedBox(height: AppSpacing.lg),

                // Link para registro
                _buildRegisterLink(),

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
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Título
        const Text(
          'Iniciar Sesión',
          style: AppTextStyles.h1,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Subtítulo
        Text(
          'Ingresa a tu cuenta para continuar',
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

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Campo de email
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'ejemplo@correo.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'El email es obligatorio';
            }
            if (!RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            ).hasMatch(value!)) {
              return 'El formato del email no es válido';
            }
            return null;
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Campo de contraseña
        CustomTextField(
          controller: _passwordController,
          label: 'Contraseña',
          hintText: 'Ingresa tu contraseña',
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
            return null;
          },
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
              'Recordar mi sesión',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthState authState) {
    return CustomButton(
      text: 'Iniciar Sesión',
      onPressed: authState.isLoading ? null : _handleLogin,
      isLoading: authState.isLoading,
      icon: Icons.login,
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

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes una cuenta? ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: const Text(
            'Regístrate',
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
