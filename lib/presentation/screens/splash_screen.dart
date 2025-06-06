import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../aplication/providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  // Colores directos - PUEDES CAMBIAR ESTOS
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashTimer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && !_hasNavigated) {
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    final authState = ref.read(authProvider);

    switch (authState.status) {
      case AuthStatus.authenticated:
        _navigateToHome();
        break;
      case AuthStatus.unauthenticated:
        _navigateToLogin();
        break;
      case AuthStatus.error:
        _showErrorAndNavigateToLogin(authState.errorMessage);
        break;
      default:
        _navigateToLogin();
        break;
    }
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showErrorAndNavigateToLogin(String? errorMessage) {
    if (!mounted || _hasNavigated) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? 'Error al verificar la sesión'),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasNavigated) _navigateToLogin();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted || _hasNavigated) return;

      if (_animationController.isCompleted) {
        switch (next.status) {
          case AuthStatus.authenticated:
            _navigateToHome();
            break;
          case AuthStatus.unauthenticated:
            _navigateToLogin();
            break;
          case AuthStatus.error:
            _showErrorAndNavigateToLogin(next.errorMessage);
            break;
          default:
            break;
        }
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: primaryBlue, // ← CAMBIA ESTE COLOR
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo/Icono de la app
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 60,
                                color: primaryBlue, // ← PUEDES CAMBIAR ESTE
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Nombre de la app
                            const Text(
                              'Gestor de Gastos',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Subtítulo
                            Text(
                              'Controla tus finanzas personales',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Indicador de estado en la parte inferior
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (authState.isChecking) ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Verificando sesión...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ] else if (authState.hasError) ...[
                    Icon(
                      Icons.error_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error al verificar sesión',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Iniciando aplicación...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
