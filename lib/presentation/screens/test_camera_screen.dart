import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/receipt_image_widget.dart';
import '../../aplication/services/camera_service.dart';

class TestCameraScreen extends ConsumerStatefulWidget {
  const TestCameraScreen({super.key});

  @override
  ConsumerState<TestCameraScreen> createState() => _TestCameraScreenState();
}

class _TestCameraScreenState extends ConsumerState<TestCameraScreen> {
  final CameraService _cameraService = CameraService();
  String? _capturedImagePath;
  bool _isProcessing = false;
  String _statusMessage = 'Listo para probar cámara';

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
    print('📱 Status: $message');
  }

  Future<void> _testCameraCapture() async {
    _updateStatus('Iniciando captura desde cámara...');
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _cameraService.captureFromCamera();

      if (result.isSuccess && result.imagePath != null) {
        setState(() {
          _capturedImagePath = result.imagePath;
        });
        _updateStatus('✅ Imagen capturada exitosamente');
        _showSuccessMessage('Imagen capturada: ${result.originalFilename}');
      } else {
        _updateStatus('❌ Error: ${result.errorMessage}');
        _showErrorMessage(result.errorMessage ?? 'Error desconocido');
      }
    } catch (e) {
      _updateStatus('❌ Excepción: $e');
      _showErrorMessage('Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _testGalleryPick() async {
    _updateStatus('Iniciando selección desde galería...');
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _cameraService.pickFromGallery();

      if (result.isSuccess && result.imagePath != null) {
        setState(() {
          _capturedImagePath = result.imagePath;
        });
        _updateStatus('✅ Imagen seleccionada exitosamente');
        _showSuccessMessage('Imagen seleccionada: ${result.originalFilename}');
      } else {
        _updateStatus('❌ Error: ${result.errorMessage}');
        _showErrorMessage(result.errorMessage ?? 'Error desconocido');
      }
    } catch (e) {
      _updateStatus('❌ Excepción: $e');
      _showErrorMessage('Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    _updateStatus('Verificando permisos...');

    try {
      final hasPermissions = await _cameraService.checkAllPermissions();
      if (hasPermissions) {
        _updateStatus('✅ Todos los permisos concedidos');
        _showSuccessMessage('Permisos OK');
      } else {
        _updateStatus('⚠️ Faltan permisos');
        final granted = await _cameraService.requestAllPermissions();
        if (granted) {
          _updateStatus('✅ Permisos concedidos');
          _showSuccessMessage('Permisos concedidos');
        } else {
          _updateStatus('❌ Permisos denegados');
          _showErrorMessage('Permisos denegados');
        }
      }
    } catch (e) {
      _updateStatus('❌ Error verificando permisos: $e');
      _showErrorMessage('Error: $e');
    }
  }

  void _clearImage() {
    setState(() {
      _capturedImagePath = null;
    });
    _updateStatus('Imagen eliminada');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Test Cámara'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Estado:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de prueba
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _checkPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Verificar Permisos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testCameraCapture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Probar Cámara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testGalleryPick,
              icon: const Icon(Icons.photo_library),
              label: const Text('Probar Galería'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Imagen capturada
            if (_capturedImagePath != null) ...[
              const Text(
                'Imagen Capturada:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ReceiptImageWidget(
                imagePath: _capturedImagePath!,
                height: 200,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ReceiptImageViewer(imagePath: _capturedImagePath!),
                    ),
                  );
                },
                onDelete: _clearImage,
              ),
              const SizedBox(height: 12),
              Text(
                'Ruta: $_capturedImagePath',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No hay imagen capturada'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
