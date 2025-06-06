import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/camera_service.dart';

// Estado de la cámara
class CameraState {
  final String? lastCapturedImage;
  final bool isLoading;
  final String? errorMessage;
  final bool hasPermissions;
  final List<String> capturedImages;

  const CameraState({
    this.lastCapturedImage,
    this.isLoading = false,
    this.errorMessage,
    this.hasPermissions = false,
    this.capturedImages = const [],
  });

  CameraState copyWith({
    String? lastCapturedImage,
    bool? isLoading,
    String? errorMessage,
    bool? hasPermissions,
    List<String>? capturedImages,
  }) {
    return CameraState(
      lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      capturedImages: capturedImages ?? this.capturedImages,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasImages => capturedImages.isNotEmpty;
  int get imageCount => capturedImages.length;
}

// StateNotifier para manejar la cámara
class CameraNotifier extends StateNotifier<CameraState> {
  final CameraService _cameraService;

  CameraNotifier(this._cameraService) : super(const CameraState()) {
    _checkPermissions();
  }

  // Verificar permisos al inicializar
  Future<void> _checkPermissions() async {
    try {
      final hasPermissions = await _cameraService.checkAllPermissions();
      state = state.copyWith(hasPermissions: hasPermissions);

      if (hasPermissions) {
        print('✅ Permisos de cámara verificados');
      } else {
        print('⚠️ Faltan permisos de cámara');
      }
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      state = state.copyWith(
        errorMessage: 'Error verificando permisos de cámara',
        hasPermissions: false,
      );
    }
  }

  // Solicitar permisos
  Future<bool> requestPermissions() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final granted = await _cameraService.requestAllPermissions();

      state = state.copyWith(
        hasPermissions: granted,
        isLoading: false,
        errorMessage: granted ? null : 'Permisos de cámara denegados',
      );

      return granted;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      state = state.copyWith(
        hasPermissions: false,
        isLoading: false,
        errorMessage: 'Error al solicitar permisos: $e',
      );
      return false;
    }
  }

  // Capturar imagen desde la cámara
  Future<String?> captureFromCamera({CameraConfig? config}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Verificar permisos
      if (!state.hasPermissions) {
        final granted = await requestPermissions();
        if (!granted) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Permisos de cámara requeridos',
          );
          return null;
        }
      }

      // Usar configuración predeterminada para recibos si no se proporciona
      final cameraConfig = config ?? CameraConfig.forReceipts();

      // Capturar imagen
      final result = await _cameraService.captureFromCamera(
        imageQuality: cameraConfig.imageQuality,
        maxWidth: cameraConfig.maxWidth,
        maxHeight: cameraConfig.maxHeight,
      );

      if (result.isSuccess && result.imagePath != null) {
        // Agregar imagen a la lista
        final updatedImages = [...state.capturedImages, result.imagePath!];

        state = state.copyWith(
          lastCapturedImage: result.imagePath,
          capturedImages: updatedImages,
          isLoading: false,
        );

        print('✅ Imagen capturada: ${result.imagePath}');
        return result.imagePath;
      } else {
        String errorMsg = 'Error desconocido';

        switch (result.type) {
          case CameraResultType.cancelled:
            errorMsg = 'Captura cancelada';
            break;
          case CameraResultType.error:
            errorMsg = result.errorMessage ?? 'Error al capturar imagen';
            break;
          default:
            errorMsg = result.errorMessage ?? 'Error desconocido';
        }

        state = state.copyWith(isLoading: false, errorMessage: errorMsg);

        return null;
      }
    } catch (e) {
      print('❌ Error en captura desde cámara: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al capturar imagen: $e',
      );
      return null;
    }
  }

  // Seleccionar imagen desde galería
  Future<String?> pickFromGallery({CameraConfig? config}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Usar configuración predeterminada para recibos si no se proporciona
      final cameraConfig = config ?? CameraConfig.forReceipts();

      // Seleccionar imagen
      final result = await _cameraService.pickFromGallery(
        imageQuality: cameraConfig.imageQuality,
        maxWidth: cameraConfig.maxWidth,
        maxHeight: cameraConfig.maxHeight,
      );

      if (result.isSuccess && result.imagePath != null) {
        // Agregar imagen a la lista
        final updatedImages = [...state.capturedImages, result.imagePath!];

        state = state.copyWith(
          lastCapturedImage: result.imagePath,
          capturedImages: updatedImages,
          isLoading: false,
        );

        print('✅ Imagen seleccionada: ${result.imagePath}');
        return result.imagePath;
      } else {
        String errorMsg = 'Error desconocido';

        switch (result.type) {
          case CameraResultType.cancelled:
            errorMsg = 'Selección cancelada';
            break;
          case CameraResultType.error:
            errorMsg = result.errorMessage ?? 'Error al seleccionar imagen';
            break;
          default:
            errorMsg = result.errorMessage ?? 'Error desconocido';
        }

        state = state.copyWith(isLoading: false, errorMessage: errorMsg);

        return null;
      }
    } catch (e) {
      print('❌ Error seleccionando desde galería: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al seleccionar imagen: $e',
      );
      return null;
    }
  }

  // Eliminar imagen
  Future<bool> deleteImage(String imagePath) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final success = await _cameraService.deleteImage(imagePath);

      if (success) {
        // Remover de la lista
        final updatedImages = state.capturedImages
            .where((path) => path != imagePath)
            .toList();

        // Si la imagen eliminada era la última capturada, limpiar referencia
        String? lastCaptured = state.lastCapturedImage;
        if (lastCaptured == imagePath) {
          lastCaptured = updatedImages.isNotEmpty ? updatedImages.last : null;
        }

        state = state.copyWith(
          capturedImages: updatedImages,
          lastCapturedImage: lastCaptured,
          isLoading: false,
        );

        print('✅ Imagen eliminada: $imagePath');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo eliminar la imagen',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error eliminando imagen: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar imagen: $e',
      );
      return false;
    }
  }

  // Verificar si una imagen existe
  Future<bool> imageExists(String imagePath) async {
    try {
      return await _cameraService.imageExists(imagePath);
    } catch (e) {
      print('❌ Error verificando existencia de imagen: $e');
      return false;
    }
  }

  // Obtener información de una imagen
  Future<ImageInfo?> getImageInfo(String imagePath) async {
    try {
      return await _cameraService.getImageInfo(imagePath);
    } catch (e) {
      print('❌ Error obteniendo info de imagen: $e');
      return null;
    }
  }

  // Limpiar imágenes temporales
  Future<void> cleanupTempImages() async {
    try {
      await _cameraService.cleanupOldImages();
      print('✅ Limpieza de imágenes temporales completada');
    } catch (e) {
      print('❌ Error en limpieza de imágenes: $e');
    }
  }

  // Obtener espacio usado por las imágenes
  Future<String> getStorageUsed() async {
    try {
      final bytes = await _cameraService.getStorageUsed();
      return _cameraService.formatFileSize(bytes);
    } catch (e) {
      print('❌ Error obteniendo espacio usado: $e');
      return '0 B';
    }
  }

  // Limpiar lista de imágenes capturadas en sesión
  void clearCapturedImages() {
    state = state.copyWith(capturedImages: [], lastCapturedImage: null);
  }

  // Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Resetear estado de cámara
  void reset() {
    state = const CameraState();
    _checkPermissions();
  }

  // Agregar imagen existente a la lista (para cuando se carga desde BD)
  void addExistingImage(String imagePath) {
    if (!state.capturedImages.contains(imagePath)) {
      final updatedImages = [...state.capturedImages, imagePath];
      state = state.copyWith(
        capturedImages: updatedImages,
        lastCapturedImage: imagePath,
      );
    }
  }

  // Remover imagen de la lista sin eliminar archivo
  void removeImageFromList(String imagePath) {
    final updatedImages = state.capturedImages
        .where((path) => path != imagePath)
        .toList();

    String? lastCaptured = state.lastCapturedImage;
    if (lastCaptured == imagePath) {
      lastCaptured = updatedImages.isNotEmpty ? updatedImages.last : null;
    }

    state = state.copyWith(
      capturedImages: updatedImages,
      lastCapturedImage: lastCaptured,
    );
  }
}

// Provider del CameraNotifier
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((
  ref,
) {
  return CameraNotifier(CameraService());
});

// Providers derivados
final cameraLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cameraProvider).isLoading;
});

final cameraErrorProvider = Provider<String?>((ref) {
  return ref.watch(cameraProvider).errorMessage;
});

final hasImagesProvider = Provider<bool>((ref) {
  return ref.watch(cameraProvider).hasImages;
});

final imageCountProvider = Provider<int>((ref) {
  return ref.watch(cameraProvider).imageCount;
});

final lastCapturedImageProvider = Provider<String?>((ref) {
  return ref.watch(cameraProvider).lastCapturedImage;
});

final capturedImagesProvider = Provider<List<String>>((ref) {
  return ref.watch(cameraProvider).capturedImages;
});

final hasPermissionsProvider = Provider<bool>((ref) {
  return ref.watch(cameraProvider).hasPermissions;
});

// Provider para configuraciones de cámara predefinidas
final cameraConfigProvider = Provider<Map<String, CameraConfig>>((ref) {
  return {
    'receipts': CameraConfig.forReceipts(),
    'high_quality': CameraConfig.highQuality(),
    'low_size': CameraConfig.lowSize(),
  };
});

// Provider para verificar si una imagen específica existe
final imageExistsProvider = Provider.family<Future<bool>, String>((
  ref,
  imagePath,
) {
  return ref.read(cameraProvider.notifier).imageExists(imagePath);
});

// Provider para obtener información de una imagen específica
final imageInfoProvider = Provider.family<Future<ImageInfo?>, String>((
  ref,
  imagePath,
) {
  return ref.read(cameraProvider.notifier).getImageInfo(imagePath);
});
