import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ReceiptImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: _buildImage(),
              ),
            ),
          ),

          // Botón de eliminar
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      } else {
        return _buildErrorWidget();
      }
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'Error al cargar imagen',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ReceiptImageViewer extends StatelessWidget {
  final String imagePath;

  const ReceiptImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Comprobante'),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: ReceiptImageWidget(
            imagePath: imagePath,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
          ),
        ),
      ),
    );
  }
}
