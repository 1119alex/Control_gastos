import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: GestorGastosApp()));
}

class GestorGastosApp extends StatelessWidget {
  const GestorGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Gastos',
      debugShowCheckedModeBanner: false,

      // Tema - FORZAR SOLO TEMA CLARO
      theme: AppTheme.lightTheme,
      darkTheme:
          AppTheme.lightTheme, // ← Forzar tema claro también en modo oscuro
      themeMode: ThemeMode.light, // ← Forzar modo claro
      // Pantalla inicial
      home: const SplashScreen(),

      // Configuraciones adicionales
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                1.0, // Evitar que el usuario cambie el tamaño del texto
          ),
          child: child!,
        );
      },
    );
  }
}
