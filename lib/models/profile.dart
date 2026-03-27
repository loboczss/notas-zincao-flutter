import 'package:notas_zincao_flutter/constants/db_schema.dart';

/// Modelo de domínio que representa o perfil de um usuário autenticado.
class Profile {
  final String id;
  final String authUid;
  final String? nome;
  final String? email;
  final String? role;
  final List<String>? workspaces;
  final DateTime? ultimoLogin;
  final String? fotoPerfil;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    required this.authUid,
    this.nome,
    this.email,
    this.role,
    this.workspaces,
    this.ultimoLogin,
    this.fotoPerfil,
    this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map[ColsProfiles.id] as String,
      authUid: map[ColsProfiles.authUid] as String,
      nome: map[ColsProfiles.nome] as String?,
      email: map[ColsProfiles.email] as String?,
      role: map[ColsProfiles.role] as String?,
      workspaces: map[ColsProfiles.workspaces] != null
          ? List<String>.from(map[ColsProfiles.workspaces] as List)
          : null,
      ultimoLogin: map[ColsProfiles.ultimoLogin] != null
          ? DateTime.parse(map[ColsProfiles.ultimoLogin] as String)
          : null,
      fotoPerfil: map[ColsProfiles.fotoPerfil] as String?,
      updatedAt: map[ColsProfiles.updatedAt] != null
          ? DateTime.parse(map[ColsProfiles.updatedAt] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ColsProfiles.id: id,
      ColsProfiles.authUid: authUid,
      ColsProfiles.nome: nome,
      ColsProfiles.email: email,
      ColsProfiles.role: role,
      ColsProfiles.workspaces: workspaces,
      ColsProfiles.ultimoLogin: ultimoLogin?.toIso8601String(),
      ColsProfiles.fotoPerfil: fotoPerfil,
      ColsProfiles.updatedAt: updatedAt?.toIso8601String(),
    };
  }

  /// Retorna as iniciais do nome para uso em avatares.
  String get initials {
    final displayName = nome ?? email ?? '?';
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(1, 2)).toUpperCase();
  }

  Profile copyWith({
    String? id,
    String? authUid,
    String? nome,
    String? email,
    String? role,
    List<String>? workspaces,
    DateTime? ultimoLogin,
    String? fotoPerfil,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      role: role ?? this.role,
      workspaces: workspaces ?? this.workspaces,
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
