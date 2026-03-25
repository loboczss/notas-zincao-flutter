import 'package:flutter/foundation.dart';
import 'package:notas_zincao_flutter/models/profile.dart';
import 'package:notas_zincao_flutter/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estado imutável do fluxo de autenticação.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Resultado pontual de uma operação (signUp, resetPassword).
enum AuthActionResult { none, success, error }

/// ViewModel central de autenticação. Gerencia sessão, perfil e navegação
/// usando [ChangeNotifier] para reatividade.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  Profile? _profile;
  String? _errorMessage;

  /// Resultado da última ação de cadastro/recuperação (para fluxos one-shot).
  AuthActionResult _actionResult = AuthActionResult.none;
  String? _actionMessage;

  AuthViewModel(this._authService) {
    _init();
  }

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  AuthActionResult get actionResult => _actionResult;
  String? get actionMessage => _actionMessage;

  /// Ouve mudanças de sessão do Supabase Auth em tempo real.
  void _init() {
    _authService.authStateChanges.listen((event) async {
      if (event.session != null) {
        await _loadProfile();
      } else {
        _profile = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    // Verifica sessão existente ao iniciar.
    final session = _authService.currentSession;
    if (session != null) {
      _loadProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      _profile = await _authService.fetchProfile();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  /// Realiza login com email e senha.
  Future<void> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
      // O listener _init irá atualizar o estado automaticamente.
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Registra um novo usuário com email, senha e nome.
  /// Retorna [AuthActionResult.success] quando o e-mail de confirmação é enviado.
  Future<void> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _actionResult = AuthActionResult.none;
    notifyListeners();
    try {
      await _authService.signUp(email: email, password: password, nome: nome);
      _actionResult = AuthActionResult.success;
      _actionMessage = 'Conta criada! Verifique seu e-mail para confirmar o cadastro.';
      _status = AuthStatus.unauthenticated;
    } on AuthException catch (e) {
      _errorMessage = _mapSignUpError(e.message);
      _actionResult = AuthActionResult.error;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
      _actionResult = AuthActionResult.error;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Envia e-mail de recuperação de senha.
  Future<void> sendPasswordReset({required String email}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _actionResult = AuthActionResult.none;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email: email);
      _actionResult = AuthActionResult.success;
      _actionMessage =
          'E-mail de recuperação enviado para $email. Verifique sua caixa de entrada.';
      _status = AuthStatus.unauthenticated;
    } on AuthException catch (e) {
      _errorMessage = _mapResetError(e.message);
      _actionResult = AuthActionResult.error;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
      _actionResult = AuthActionResult.error;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Limpa o resultado de ação para não re-exibir após rebuild.
  void clearActionResult() {
    _actionResult = AuthActionResult.none;
    _actionMessage = null;
    _errorMessage = null;
  }

  /// Realiza logout e limpa o estado local.
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();
    await _authService.signOut();
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('Too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos.';
    }
    return 'Falha no login. Verifique suas credenciais.';
  }

  String _mapSignUpError(String message) {
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (message.contains('Password should be')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (message.contains('Invalid email')) {
      return 'Formato de e-mail inválido.';
    }
    return 'Não foi possível criar a conta. Tente novamente.';
  }

  String _mapResetError(String message) {
    if (message.contains('Invalid email') || message.contains('not found')) {
      return 'E-mail não encontrado. Verifique e tente novamente.';
    }
    if (message.contains('Too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos.';
    }
    return 'Não foi possível enviar o e-mail. Tente novamente.';
  }
}
