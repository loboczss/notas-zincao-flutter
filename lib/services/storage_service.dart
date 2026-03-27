import 'dart:io';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço centralizado para upload de imagens no Supabase Storage.
class StorageService {
  static final _bucket = supabase.storage.from(StorageBuckets.cupons);

  /// Upload de uma única imagem. Retorna a URL pública.
  static Future<String> uploadImage(File imageFile, String userId) async {
    final ext = p.extension(imageFile.path).replaceFirst('.', '');
    final storagePath =
        '${StorageBuckets.cupons}/${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await imageFile.readAsBytes();
    await _bucket.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
    );
    return _bucket.getPublicUrl(storagePath);
  }

  /// Upload de múltiplas imagens em paralelo. Retorna lista de URLs públicas.
  static Future<List<String>> uploadImages(
    List<File> images,
    String userId,
  ) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return Future.wait(
      List.generate(images.length, (i) async {
        final file = images[i];
        final ext = p.extension(file.path).replaceFirst('.', '');
        final storagePath =
            '${StorageBuckets.cupons}/${userId}_retirada_${ts}_$i.$ext';
        final bytes = await file.readAsBytes();
        await _bucket.uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
        );
        return _bucket.getPublicUrl(storagePath);
      }),
    );
  }
}
