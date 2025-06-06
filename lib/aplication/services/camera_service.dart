import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // =============================================
  // GESTIÓN DE PERMISOS
  // =============================================

  // Verificar permisos de cámara
  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Error verificando permisos de cámara: $e');
      return false;
    }
  }

  // Solicitar permisos de cámara
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (status.isGranted) {
        print('✅ Permiso de cámara concedido');
        return true;
      } else if (status.isDenied) {
        print('⚠️ Permiso de cámara denegado');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('❌ Permiso de cámara denegado permanentemente');
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error solicitando permisos de cámara: $e');
      return false;
    }
  }

  // Verificar permisos de almacenamiento
  Future<bool> checkStoragePermission() async {
    try {
      // En Android 10+ (API 29+) no se necesita permiso para app-specific storage
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        return status.isGranted || status.isLimited;
      } else if (Platform.isIOS) {
        // iOS maneja los permisos automáticamente para app-specific storage
        return true;
      }

      return true;
    } catch (e) {
      print('❌ Error verificando permisos de almacenamiento: $e');
      return false;
    }
  }

  // Solicitar permisos de almacenamiento
  Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        return status.isGranted || status.isLimited;
      }

      return true; // iOS no necesita solicitud explícita
    } catch (e) {
      print('❌ Error solicitando permisos de almacenamiento: $e');
      return false;
    }
  }

  // Verificar todos los permisos necesarios
  Future<bool> checkAllPermissions() async {
    final cameraPermission = await checkCameraPermission();
    final storagePermission = await checkStoragePermission();

    return cameraPermission && storagePermission;
  }

  // Solicitar todos los permisos necesarios
  Future<bool> requestAllPermissions() async {
    final cameraPermission = await requestCameraPermission();
    final storagePermission = await requestStoragePermission();

    return cameraPermission && storagePermission;
  }

  // =============================================
  // CAPTURA DE IMÁGENES
  // =============================================

  // Capturar foto desde la cámara
  Future<CameraResult> captureFromCamera({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // Verificar permisos
      if (!await checkAllPermissions()) {
        final granted = await requestAllPermissions();
        if (!granted) {
          return CameraResult.error('Permisos de cámara no concedidos');
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        // Guardar imagen en directorio de la app
        final savedPath = await _saveImageToAppDirectory(photo);
        if (savedPath != null) {
          // Obtener información del archivo
          final file = File(savedPath);
          final fileSize = await file.length();

          return CameraResult.success(
            imagePath: savedPath,
            originalFilename: path.basename(photo.path),
            fileSize: fileSize,
          );
        } else {
          return CameraResult.error('Error al guardar la imagen');
        }
      } else {
        return CameraResult.cancelled('Captura cancelada por el usuario');
      }
    } catch (e) {
      print('❌ Error capturando desde cámara: $e');
      return CameraResult.error('Error al capturar imagen: $e');
    }
  }

  // Seleccionar imagen desde galería
  Future<CameraResult> pickFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (photo != null) {
        // Guardar imagen en directorio de la app
        final savedPath = await _saveImageToAppDirectory(photo);
        if (savedPath != null) {
          // Obtener información del archivo
          final file = File(savedPath);
          final fileSize = await file.length();

          return CameraResult.success(
            imagePath: savedPath,
            originalFilename: path.basename(photo.path),
            fileSize: fileSize,
          );
        } else {
          return CameraResult.error('Error al guardar la imagen');
        }
      } else {
        return CameraResult.cancelled('Selección cancelada por el usuario');
      }
    } catch (e) {
      print('❌ Error seleccionando desde galería: $e');
      return CameraResult.error('Error al seleccionar imagen: $e');
    }
  }

  // =============================================
  // GESTIÓN DE ARCHIVOS
  // =============================================

  // Guardar imagen en directorio de la aplicación
  Future<String?> _saveImageToAppDirectory(XFile photo) async {
    try {
      // Obtener directorio de documentos de la app
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');

      // Crear directorio si no existe
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(photo.path).toLowerCase();
      final fileName = 'receipt_$timestamp$extension';
      final savedImagePath = '${receiptsDir.path}/$fileName';

      // Copiar archivo al directorio de la app
      final File originalFile = File(photo.path);
      final File savedFile = await originalFile.copy(savedImagePath);

      print('✅ Imagen guardada en: $savedImagePath');
      return savedFile.path;
    } catch (e) {
      print('❌ Error guardando imagen: $e');
      return null;
    }
  }

  // Obtener directorio de recibos
  Future<Directory?> getReceiptsDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      return receiptsDir;
    } catch (e) {
      print('❌ Error obteniendo directorio de recibos: $e');
      return null;
    }
  }

  // Eliminar imagen del dispositivo
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('✅ Imagen eliminada: $imagePath');
        return true;
      } else {
        print('⚠️ Archivo no encontrado: $imagePath');
        return false;
      }
    } catch (e) {
      print('❌ Error eliminando imagen: $e');
      return false;
    }
  }

  // Verificar si una imagen existe
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      print('❌ Error verificando existencia de imagen: $e');
      return false;
    }
  }

  // Obtener tamaño de archivo
  Future<int> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('❌ Error obteniendo tamaño de imagen: $e');
      return 0;
    }
  }

  // Obtener información de una imagen
  Future<ImageInfo?> getImageInfo(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return ImageInfo(
          path: imagePath,
          filename: path.basename(imagePath),
          size: stat.size,
          createdAt: stat.changed,
          modifiedAt: stat.modified,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo información de imagen: $e');
      return null;
    }
  }

  // =============================================
  // UTILIDADES
  // =============================================

  // Limpiar imágenes antiguas (más de 30 días)
  Future<void> cleanupOldImages() async {
    try {
      final receiptsDir = await getReceiptsDirectory();
      if (receiptsDir != null) {
        final files = receiptsDir.listSync();
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

        int deletedCount = 0;
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            if (stat.modified.isBefore(thirtyDaysAgo)) {
              await file.delete();
              deletedCount++;
            }
          }
        }

        print('✅ Limpieza completada: $deletedCount archivos eliminados');
      }
    } catch (e) {
      print('❌ Error en limpieza de imágenes: $e');
    }
  }

  // Obtener espacio usado por las imágenes
  Future<int> getStorageUsed() async {
    try {
      final receiptsDir = await getReceiptsDirectory();
      if (receiptsDir != null) {
        final files = receiptsDir.listSync();
        int totalSize = 0;

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }

        return totalSize;
      }
      return 0;
    } catch (e) {
      print('❌ Error calculando espacio usado: $e');
      return 0;
    }
  }

  // Formatear tamaño de archivo en formato legible
  String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  // Mostrar opciones de fuente de imagen (cámara o galería)
  Future<CameraResult> showImageSourceOptions() async {
    // Esta función sería llamada desde la UI con un dialog
    // Por ahora retorna un resultado que indica que debe mostrar opciones
    return CameraResult.showOptions('Mostrar opciones de fuente');
  }
}

// =============================================
// CLASES DE RESULTADO Y DATOS
// =============================================

// Resultado de operaciones de cámara
class CameraResult {
  final bool isSuccess;
  final String? imagePath;
  final String? originalFilename;
  final int? fileSize;
  final String? errorMessage;
  final CameraResultType type;

  const CameraResult._({
    required this.isSuccess,
    this.imagePath,
    this.originalFilename,
    this.fileSize,
    this.errorMessage,
    required this.type,
  });

  // Constructor para éxito
  factory CameraResult.success({
    required String imagePath,
    required String originalFilename,
    required int fileSize,
  }) {
    return CameraResult._(
      isSuccess: true,
      imagePath: imagePath,
      originalFilename: originalFilename,
      fileSize: fileSize,
      type: CameraResultType.success,
    );
  }

  // Constructor para error
  factory CameraResult.error(String errorMessage) {
    return CameraResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      type: CameraResultType.error,
    );
  }

  // Constructor para cancelación
  factory CameraResult.cancelled(String message) {
    return CameraResult._(
      isSuccess: false,
      errorMessage: message,
      type: CameraResultType.cancelled,
    );
  }

  // Constructor para mostrar opciones
  factory CameraResult.showOptions(String message) {
    return CameraResult._(
      isSuccess: false,
      errorMessage: message,
      type: CameraResultType.showOptions,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'CameraResult.success(path: $imagePath, size: $fileSize bytes)';
    } else {
      return 'CameraResult.${type.name}(message: $errorMessage)';
    }
  }
}

// Tipos de resultado de cámara
enum CameraResultType { success, error, cancelled, showOptions }

// Información de imagen
class ImageInfo {
  final String path;
  final String filename;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const ImageInfo({
    required this.path,
    required this.filename,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
  });

  // Tamaño formateado
  String get formattedSize {
    if (size <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double fileSize = size.toDouble();

    while (fileSize >= 1024 && i < suffixes.length - 1) {
      fileSize /= 1024;
      i++;
    }

    return '${fileSize.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  // Extensión del archivo
  String get extension {
    return path.split('.').last.toLowerCase();
  }

  // Verificar si es una imagen válida
  bool get isValidImage {
    const validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return validExtensions.contains(extension);
  }

  @override
  String toString() {
    return 'ImageInfo(filename: $filename, size: $formattedSize, created: $createdAt)';
  }
}

// Configuración de cámara
class CameraConfig {
  final int imageQuality;
  final double? maxWidth;
  final double? maxHeight;
  final bool preferFrontCamera;
  final bool enableFlash;

  const CameraConfig({
    this.imageQuality = 85,
    this.maxWidth,
    this.maxHeight,
    this.preferFrontCamera = false,
    this.enableFlash = false,
  });

  // Configuración predefinida para recibos
  factory CameraConfig.forReceipts() {
    return const CameraConfig(
      imageQuality: 90,
      maxWidth: 1920,
      maxHeight: 1080,
      preferFrontCamera: false,
      enableFlash: false,
    );
  }

  // Configuración predefinida para calidad alta
  factory CameraConfig.highQuality() {
    return const CameraConfig(
      imageQuality: 95,
      maxWidth: null,
      maxHeight: null,
      preferFrontCamera: false,
      enableFlash: false,
    );
  }

  // Configuración predefinida para tamaño pequeño
  factory CameraConfig.lowSize() {
    return const CameraConfig(
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 600,
      preferFrontCamera: false,
      enableFlash: false,
    );
  }

  CameraConfig copyWith({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    bool? preferFrontCamera,
    bool? enableFlash,
  }) {
    return CameraConfig(
      imageQuality: imageQuality ?? this.imageQuality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      preferFrontCamera: preferFrontCamera ?? this.preferFrontCamera,
      enableFlash: enableFlash ?? this.enableFlash,
    );
  }
}

// Estado de permisos
class PermissionStatus {
  final bool cameraGranted;
  final bool storageGranted;
  final String? errorMessage;

  const PermissionStatus({
    required this.cameraGranted,
    required this.storageGranted,
    this.errorMessage,
  });

  bool get allGranted => cameraGranted && storageGranted;
  bool get hasError => errorMessage != null;

  factory PermissionStatus.allGranted() {
    return const PermissionStatus(cameraGranted: true, storageGranted: true);
  }

  factory PermissionStatus.denied(String message) {
    return PermissionStatus(
      cameraGranted: false,
      storageGranted: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    return 'PermissionStatus(camera: $cameraGranted, storage: $storageGranted, error: $errorMessage)';
  }
}
