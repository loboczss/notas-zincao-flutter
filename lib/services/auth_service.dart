import 'dart:convert';

import 'package:notas_zincao_flutter/models/profile.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de autenticação: envolve o Supabase Auth e o acesso à tabela profiles.
/// Stateless — não armazena estado da sessão. Use [AuthViewModel] para isso.
class AuthService {
  static const String _cachedProfileKey = 'auth_cached_profile_v1';

  /// Stream de mudanças de estado de autenticação do Supabase.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Sessão ativa atual (null se não autenticado).
  Session? get currentSession => supabase.auth.currentSession;

  /// Usuário autenticado atual.
  User? get currentUser => supabase.auth.currentUser;

  /// Realiza login via email e senha.
  /// Lança [AuthException] em caso de credenciais inválidas.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registra um novo usuário com email, senha e nome.
  /// O trigger [handle_new_user] cria o perfil automaticamente.
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nome': nome.trim()},
    );
  }

  /// Envia e-mail de recuperação de senha.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Realiza logout e invalida a sessão local.
  Future<void> signOut() async {
    await supabase.auth.signOut();
    await clearCachedProfile();
  }

  /// Busca o perfil do usuário autenticado da tabela public.profiles.
  Future<Profile?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('auth_uid', user.id)
        .maybeSingle();

    if (data == null) return null;
    final profile = Profile.fromMap(data);
    await cacheProfile(profile);
    return profile;
  }

  /// Persiste o último perfil autenticado para abertura offline do app.
  Future<void> cacheProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedProfileKey, jsonEncode(profile.toMap()));
  }

  /// Lê o perfil salvo em cache local, se existir.
  Future<Profile?> loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedProfileKey);
    if (raw == null || raw.isEmpty) return null;

    final data = jsonDecode(raw);
    if (data is! Map) return null;
    return Profile.fromMap(Map<String, dynamic>.from(data));
  }

  /// Remove cache de perfil local.
  Future<void> clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedProfileKey);
  }

  /// Atualiza campos editáveis do perfil do usuário.
  Future<void> updateProfile({
    required String authUid,
    String? nome,
    String? fotoPerfil,
  }) async {
    final payload = <String, dynamic>{};
    if (nome != null) payload['nome'] = nome;
    if (fotoPerfil != null) payload['foto_perfil'] = fotoPerfil;
    if (payload.isEmpty) return;

    await supabase
        .from('profiles')
        .update(payload)
        .eq('auth_uid', authUid);
  }
}
