import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:path/path.dart' as p;

/// Um visualizador de imagem simples com suporte a zoom (InteractiveViewer).
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? tag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.tag,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();


  /// Método utilitário para abrir o visualizador
  static void show(BuildContext context, String imageUrl, {String? tag}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl, tag: tag),
      ),
    );
  }
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  static const MethodChannel _galleryChannel = MethodChannel('notas_zincao/gallery');

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.scrim,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.scrim.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.close, color: colorScheme.onInverseSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.scrim.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Salvar no celular',
              onPressed: _isSaving ? null : _saveImage,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onInverseSurface,
                      ),
                    )
                  : Icon(Icons.download_rounded, color: colorScheme.onInverseSurface),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
            Navigator.pop(context);
          }
        },
        child: Center(
          child: Hero(
            tag: widget.tag ?? widget.imageUrl,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.onInverseSurface),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      color: colorScheme.onInverseSurface.withValues(alpha: 0.7),
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    _log('Iniciando salvamento da imagem');
    _log('URL original: ${widget.imageUrl}');

    try {
      final uri = Uri.parse(widget.imageUrl);
      _log('URI parseada: $uri');

      final response = await http.get(uri);
      _log('Download concluido com status ${response.statusCode}');
      _log('Headers recebidos: ${response.headers}');
      _log('Bytes recebidos: ${response.bodyBytes.length}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Falha ao baixar imagem');
      }

      final fileName = _buildFileName(uri);
      final extension = _resolveImageExtension(uri, response.headers['content-type']);
      final mimeType = _resolveMimeType(extension, response.headers['content-type']);
      _log('Nome base gerado: $fileName');
      _log('Extensao resolvida: $extension');
      _log('MimeType resolvido: $mimeType');

      if (Platform.isAndroid) {
        await _saveImageOnAndroid(
          bytes: response.bodyBytes,
          fileName: '$fileName$extension',
          mimeType: mimeType,
        );
      } else {
        await _saveImageWithGalFallback(
          bytes: response.bodyBytes,
          fileName: fileName,
          extension: extension,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem salva na galeria do celular.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on GalException catch (error) {
      _log('GalException capturada');
      _log('Tipo: ${error.type}');
      _log('Platform code: ${error.platformException.code}');
      _log('Platform message: ${error.platformException.message}');
      _log('Platform details: ${error.platformException.details}');
      _log('Platform stacktrace: ${error.platformException.stacktrace}');
      debugPrintStack(stackTrace: error.stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_buildGalErrorMessage(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } on PlatformException catch (error, stackTrace) {
      _log('PlatformException capturada no canal nativo');
      _log('Code: ${error.code}');
      _log('Message: ${error.message}');
      _log('Details: ${error.details}');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: ${error.message ?? error.code}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (error, stackTrace) {
      _log('Erro generico capturado: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      _log('Fluxo de salvamento finalizado');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _buildFileName(Uri uri) {
    final segments = uri.pathSegments;
    final rawName = segments.isNotEmpty ? segments.last : 'nota';
    final sanitized = rawName.split('?').first;
    if (sanitized.contains('.')) {
      return sanitized.split('.').first;
    }

    final suffix = DateTime.now().millisecondsSinceEpoch + Random().nextInt(999);
    return 'nota_$suffix';
  }

  String _resolveImageExtension(Uri uri, String? contentType) {
    final pathExtension = p.extension(uri.path).toLowerCase();
    if (pathExtension.isNotEmpty) {
      return pathExtension;
    }

    final normalizedContentType = (contentType ?? '').toLowerCase();
    if (normalizedContentType.contains('png')) {
      return '.png';
    }
    if (normalizedContentType.contains('webp')) {
      return '.webp';
    }
    if (normalizedContentType.contains('gif')) {
      return '.gif';
    }
    if (normalizedContentType.contains('heic') || normalizedContentType.contains('heif')) {
      return '.heic';
    }
    return '.jpg';
  }

  String _resolveMimeType(String extension, String? contentType) {
    final normalizedContentType = (contentType ?? '').toLowerCase();
    if (normalizedContentType.startsWith('image/')) {
      return normalizedContentType;
    }

    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _saveImageOnAndroid({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    _log('Usando canal nativo Android para salvar imagem');
    _log('Arquivo final Android: $fileName');

    final result = await _galleryChannel.invokeMethod<bool>('saveImageToGallery', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
    });

    _log('Resultado do canal nativo: $result');
  }

  Future<void> _saveImageWithGalFallback({
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {
    final granted = await Gal.requestAccess();
    _log('Resultado do requestAccess fallback: $granted');
    if (!granted) {
      throw Exception('Permissao negada para salvar na galeria.');
    }

    final tempFile = File(p.join(Directory.systemTemp.path, '$fileName$extension'));
    _log('Arquivo temporario fallback: ${tempFile.path}');
    await tempFile.writeAsBytes(bytes, flush: true);
    _log('Arquivo temporario fallback salvo. Existe=${await tempFile.exists()} Tamanho=${await tempFile.length()}');
    await Gal.putImage(tempFile.path);
    _log('Gal.putImage fallback executado com sucesso');
  }

  String _mapGalError(GalExceptionType type) {
    switch (type) {
      case GalExceptionType.accessDenied:
        return 'Permissão negada para salvar na galeria.';
      case GalExceptionType.notEnoughSpace:
        return 'Sem espaço suficiente para salvar a imagem.';
      case GalExceptionType.notSupportedFormat:
        return 'Formato da imagem não suportado para salvar.';
      case GalExceptionType.unexpected:
        return 'Não foi possível salvar a imagem.';
    }
  }

  String _buildGalErrorMessage(GalException error) {
    final base = _mapGalError(error.type);
    final platformMessage = error.platformException.message;
    if (platformMessage == null || platformMessage.trim().isEmpty) {
      return base;
    }
    return '$base Detalhe: $platformMessage';
  }

  void _log(String message) {
    debugPrint('[FullScreenImageViewer] $message');
  }
}
