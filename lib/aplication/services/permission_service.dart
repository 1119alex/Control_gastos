import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Verificar permisos de cámara
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Solicitar permisos de cámara
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Verificar permisos de almacenamiento
  static Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      // Para Android 13+ (API 33+)
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.status;
        return status.isGranted;
      } else {
        // Para Android 12 y anteriores
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted;
    }
    return true;
  }

  // Solicitar permisos de almacenamiento
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  // Verificar todos los permisos necesarios
  static Future<bool> checkAllPermissions() async {
    final cameraPermission = await checkCameraPermission();
    final storagePermission = await checkStoragePermission();

    return cameraPermission && storagePermission;
  }

  // Solicitar todos los permisos necesarios
  static Future<PermissionResult> requestAllPermissions() async {
    final cameraGranted = await requestCameraPermission();
    final storageGranted = await requestStoragePermission();

    if (cameraGranted && storageGranted) {
      return PermissionResult.granted();
    } else if (!cameraGranted && !storageGranted) {
      return PermissionResult.denied(
        'Se necesitan permisos de cámara y almacenamiento',
      );
    } else if (!cameraGranted) {
      return PermissionResult.denied('Se necesita permiso de cámara');
    } else {
      return PermissionResult.denied('Se necesita permiso de almacenamiento');
    }
  }

  // Verificar si los permisos fueron denegados permanentemente
  static Future<bool> isPermissionPermanentlyDenied(
    Permission permission,
  ) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  // Mostrar diálogo para ir a configuraciones
  static Future<void> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text(
                'Configuraciones',
                style: TextStyle(color: Color(0xFF2196F3)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Manejar permisos denegados permanentemente
  static Future<void> handlePermanentlyDeniedPermissions(
    BuildContext context,
  ) async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;

    if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
      await showPermissionDialog(
        context,
        title: 'Permisos Requeridos',
        message:
            'Para usar la cámara y guardar fotos, necesitas habilitar los permisos en la configuración de la aplicación.',
      );
    }
  }

  // Verificar versión de Android
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      // Verificar si es Android 13+ (API 33+)
      // Esta es una aproximación, en producción deberías usar device_info_plus
      return false;
    }
    return false;
  }

  // Solicitar permisos específicos paso a paso
  static Future<PermissionStepResult> requestPermissionsStepByStep() async {
    // Paso 1: Solicitar permiso de cámara
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isDenied) {
      return PermissionStepResult(
        success: false,
        step: 'camera',
        message: 'Permiso de cámara denegado',
      );
    }

    if (cameraStatus.isPermanentlyDenied) {
      return PermissionStepResult(
        success: false,
        step: 'camera',
        message: 'Permiso de cámara denegado permanentemente',
        isPermanentlyDenied: true,
      );
    }

    // Paso 2: Solicitar permiso de fotos/almacenamiento
    Permission storagePermission = Platform.isIOS
        ? Permission.photos
        : Permission.storage;

    final storageStatus = await storagePermission.request();

    if (storageStatus.isDenied) {
      return PermissionStepResult(
        success: false,
        step: 'storage',
        message: 'Permiso de almacenamiento denegado',
      );
    }

    if (storageStatus.isPermanentlyDenied) {
      return PermissionStepResult(
        success: false,
        step: 'storage',
        message: 'Permiso de almacenamiento denegado permanentemente',
        isPermanentlyDenied: true,
      );
    }

    return PermissionStepResult(
      success: true,
      step: 'complete',
      message: 'Todos los permisos concedidos',
    );
  }
}

// Clase para el resultado de permisos
class PermissionResult {
  final bool isGranted;
  final String? message;

  const PermissionResult({required this.isGranted, this.message});

  factory PermissionResult.granted() {
    return const PermissionResult(isGranted: true);
  }

  factory PermissionResult.denied(String message) {
    return PermissionResult(isGranted: false, message: message);
  }
}

// Clase para el resultado paso a paso
class PermissionStepResult {
  final bool success;
  final String step;
  final String message;
  final bool isPermanentlyDenied;

  const PermissionStepResult({
    required this.success,
    required this.step,
    required this.message,
    this.isPermanentlyDenied = false,
  });
}

// Widget helper para solicitar permisos
class PermissionRequestWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const PermissionRequestWidget({
    super.key,
    required this.child,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
  });

  @override
  State<PermissionRequestWidget> createState() =>
      _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState extends State<PermissionRequestWidget> {
  bool _permissionsChecked = false;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await PermissionService.checkAllPermissions();

    setState(() {
      _hasPermissions = hasPermissions;
      _permissionsChecked = true;
    });

    if (hasPermissions) {
      widget.onPermissionsGranted?.call();
    } else {
      widget.onPermissionsDenied?.call();
    }
  }

  Future<void> _requestPermissions() async {
    final result = await PermissionService.requestPermissionsStepByStep();

    if (result.success) {
      setState(() {
        _hasPermissions = true;
      });
      widget.onPermissionsGranted?.call();
    } else {
      if (result.isPermanentlyDenied && mounted) {
        await PermissionService.handlePermanentlyDeniedPermissions(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      widget.onPermissionsDenied?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_hasPermissions) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Permisos Necesarios',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para usar la función de captura de recibos, necesitamos acceso a la cámara y almacenamiento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Conceder Permisos'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
