import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/models/profile.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';

class NotaRetiradaService {
  /// Busca todas as notas de retirada do Supabase de acordo com o nível de acesso.
  Future<List<NotaRetirada>> fetchAll(Profile? profile) async {
    try {
      if (profile == null) return [];

      var query = supabase.from(DbTables.notasRetirada).select();

      // Se não for admin e não for colaborador, visualiza apenas as notas criadas por ele
      if (profile.role != 'admin' && profile.role != 'colaborador') {
        query = query.eq(ColsNotasRetirada.ownerUserId, profile.authUid);
      }

      final response = await query.order(ColsNotasRetirada.dataCompra, ascending: false);
      
      return (response as List)
          .map((data) => NotaRetirada.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Busca uma nota específica pelo ID.
  Future<NotaRetirada?> getById(String id) async {
    try {
      final response = await supabase
          .from(DbTables.notasRetirada)
          .select()
          .eq(ColsNotasRetirada.id, id)
          .single();
      
      return NotaRetirada.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Inserta uma nova nota.
  Future<void> create(NotaRetirada nota) async {
    try {
      await supabase.from(DbTables.notasRetirada).insert(nota.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Atualiza uma nota existente.
  Future<void> update(NotaRetirada nota) async {
    try {
      await supabase
          .from(DbTables.notasRetirada)
          .update(nota.toMap())
          .eq(ColsNotasRetirada.id, nota.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Exclui uma nota.
  Future<void> delete(String id) async {
    try {
      await supabase.from(DbTables.notasRetirada).delete().eq(ColsNotasRetirada.id, id);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancela uma nota.
  Future<void> cancel(String id) async {
    try {
      await supabase
          .from(DbTables.notasRetirada)
          .update({ColsNotasRetirada.statusRetirada: 'cancelada'})
          .eq(ColsNotasRetirada.id, id);
    } catch (e) {
      rethrow;
    }
  }
}
