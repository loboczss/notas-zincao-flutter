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
      id: map['id'] as String,
      authUid: map['auth_uid'] as String,
      nome: map['nome'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String?,
      workspaces: map['workspaces'] != null
          ? List<String>.from(map['workspaces'] as List)
          : null,
      ultimoLogin: map['ultimo_login'] != null
          ? DateTime.parse(map['ultimo_login'] as String)
          : null,
      fotoPerfil: map['foto_perfil'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_uid': authUid,
      'nome': nome,
      'email': email,
      'role': role,
      'workspaces': workspaces,
      'ultimo_login': ultimoLogin?.toIso8601String(),
      'foto_perfil': fotoPerfil,
      'updated_at': updatedAt?.toIso8601String(),
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
