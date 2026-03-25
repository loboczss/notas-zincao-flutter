import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/app_update_policy.dart';
import 'package:notas_zincao_flutter/screens/login_screen.dart';
import 'package:notas_zincao_flutter/screens/main_shell.dart';
import 'package:notas_zincao_flutter/services/app_update_service.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/app_update_viewmodel.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

/// Widget raiz que observa [AuthViewModel] e roteia entre Login e App principal.
/// Centraliza toda lógica de guarda de rotas — as telas filhas não sabem nada
/// sobre autenticação.
class AppRouter extends StatefulWidget {
  final AuthViewModel authViewModel;

  const AppRouter({super.key, required this.authViewModel});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> with WidgetsBindingObserver {
  late final AppUpdateViewModel _appUpdateViewModel;
  bool _isOptionalDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appUpdateViewModel = AppUpdateViewModel(AppUpdateService())
      ..addListener(_handleUpdateChanges);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appUpdateViewModel.checkForUpdates();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appUpdateViewModel
        ..resetOptionalPrompt()
        ..checkForUpdates(silently: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appUpdateViewModel.removeListener(_handleUpdateChanges);
    _appUpdateViewModel.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateChanges() async {
    if (!mounted || _isOptionalDialogOpen || !_appUpdateViewModel.shouldShowOptionalPrompt) {
      return;
    }

    _isOptionalDialogOpen = true;
    final policy = _appUpdateViewModel.policy;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atualização disponível'),
          content: Text(
            policy?.message ??
                'Existe uma versão mais recente do app. Atualize para receber melhorias e correções.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _appUpdateViewModel.dismissOptionalPrompt();
              },
              child: const Text('Depois'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _appUpdateViewModel.updateNow();
                _appUpdateViewModel.dismissOptionalPrompt();
              },
              child: const Text('Atualizar'),
            ),
          ],
        );
      },
    );

    _isOptionalDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.authViewModel, _appUpdateViewModel]),
      builder: (context, _) {
        if (_appUpdateViewModel.status == AppUpdateStatus.required) {
          return _ForceUpdateScreen(
            viewModel: _appUpdateViewModel,
            policy: _appUpdateViewModel.policy,
          );
        }

        switch (widget.authViewModel.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _SplashScreen();

          case AuthStatus.authenticated:
            return MainShell(authViewModel: widget.authViewModel);

          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return LoginScreen(viewModel: widget.authViewModel);
        }
      },
    );
  }
}

/// Tela de splash/loading exibida enquanto a sessão está sendo verificada.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _ForceUpdateScreen extends StatefulWidget {
  final AppUpdateViewModel viewModel;
  final AppUpdatePolicy? policy;

  const _ForceUpdateScreen({required this.viewModel, required this.policy});

  @override
  State<_ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<_ForceUpdateScreen> {
  bool _isUpdating = false;

  Future<void> _onUpdatePressed() async {
    setState(() => _isUpdating = true);
    await widget.viewModel.updateNow(immediate: true);
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.system_update_alt, size: 54, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Atualização obrigatória',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.policy?.message ??
                      'Para continuar usando o app, atualize para a versão mais recente.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isUpdating ? null : _onUpdatePressed,
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Atualizar agora'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          widget.viewModel.checkForUpdates(silently: true);
                        },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
