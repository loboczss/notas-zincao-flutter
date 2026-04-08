import 'dart:io';
import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/viewmodels/retirada_form_viewmodel.dart';

class MultiplePhotoCapture extends StatelessWidget {
  final RetiradaViewModel viewModel;

  const MultiplePhotoCapture({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final fotos = viewModel.fotosComprovante;
    final isCapturing = viewModel.status == RetiradaStatus.capturing;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: cs.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Fotos de Comprovante',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tire fotos do cliente retirando os produtos ou dos produtos que estão sendo retirados.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          
          if (fotos.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _PhotoThumbnail(
                    image: fotos[index],
                    onRemove: () => viewModel.removerFoto(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isCapturing ? null : viewModel.tirarFoto,
              icon: isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_a_photo, size: 20),
              label: Text(
                isCapturing ? 'Abrindo câmera...' : 'Adicionar Foto',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                foregroundColor: cs.onSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final File image;
  final VoidCallback onRemove;

  const _PhotoThumbnail({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            image,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
