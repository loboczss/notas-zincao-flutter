import 'dart:convert';

import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/constants/db_tables.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/models/profile.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotaRetiradaService {
  static const String _cachePrefix = 'notas_retirada_cache_v1';

  /// Busca todas as notas de retirada do Supabase de acordo com o nível de acesso.
  Future<List<NotaRetirada>> fetchAll(Profile? profile) async {
    if (profile == null) return [];

    try {

      var query = supabase.from(DbTables.notasRetirada).select();

      // Se não for admin e não for colaborador, visualiza apenas as notas criadas por ele
      if (profile.role != 'admin' && profile.role != 'colaborador') {
        query = query.eq(ColsNotasRetirada.ownerUserId, profile.authUid);
      }

      final response = await query.order(ColsNotasRetirada.dataCompra, ascending: false);

      final notas = (response as List)
          .map((data) => NotaRetirada.fromMap(data as Map<String, dynamic>))
          .toList();

      final enriched = await _enrichWithUserNames(notas, currentProfile: profile);
      await _saveCache(profile, enriched);
      return enriched;
    } catch (e) {
      final cached = await _loadCache(profile);
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  String _cacheKey(Profile profile) {
    final role = (profile.role ?? 'sem_role').toLowerCase();
    return '$_cachePrefix:${profile.authUid}:$role';
  }

  Future<void> _saveCache(Profile profile, List<NotaRetirada> notas) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(
      notas
          .map((n) => {
                ...n.toMap(),
                // Campo transiente útil para render offline da listagem.
                'cadastrado_por_nome': n.cadastradoPorNome,
              })
          .toList(),
    );
    await prefs.setString(_cacheKey(profile), serialized);
  }

  Future<List<NotaRetirada>> _loadCache(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(profile));
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final nome = map['cadastrado_por_nome'] as String?;
          map.remove('cadastrado_por_nome');
          return NotaRetirada.fromMap(map).copyWith(cadastradoPorNome: nome);
        })
        .toList();
  }

  /// Busca o mapa authUid → nome para os IDs fornecidos e enriquece as notas.
  Future<List<NotaRetirada>> _enrichWithUserNames(
    List<NotaRetirada> notas, {
    Profile? currentProfile,
  }) async {
    if (notas.isEmpty) return notas;

    final ownerIds = notas.map((n) => n.ownerUserId).toSet().toList();

    try {
      final profilesData = await supabase
          .from(DbTables.profiles)
          .select('${ColsProfiles.authUid}, ${ColsProfiles.nome}')
          .inFilter(ColsProfiles.authUid, ownerIds);

      final nameMap = <String, String>{
        for (final p in profilesData as List)
          (p as Map<String, dynamic>)[ColsProfiles.authUid] as String:
              ((p)[ColsProfiles.nome] as String?) ?? 'Usuário',
      };

      return notas.map((n) {
        final nomeDoBanco = nameMap[n.ownerUserId];
        final nomeDoUsuarioAtual =
            (currentProfile != null && n.ownerUserId == currentProfile.authUid)
                ? currentProfile.nome
                : null;

        return n.copyWith(cadastradoPorNome: nomeDoBanco ?? nomeDoUsuarioAtual);
      }).toList();
    } catch (_) {
      // Se falhar não bloqueia a listagem
      return notas.map((n) {
        final nomeDoUsuarioAtual =
            (currentProfile != null && n.ownerUserId == currentProfile.authUid)
                ? currentProfile.nome
                : null;
        return n.copyWith(cadastradoPorNome: nomeDoUsuarioAtual);
      }).toList();
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
