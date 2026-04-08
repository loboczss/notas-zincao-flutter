import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

/// Tela dedicada para recuperação de senha via e-mail.
class ForgotPasswordScreen extends StatefulWidget {
  final AuthViewModel viewModel;

  const ForgotPasswordScreen({super.key, required this.viewModel});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    widget.viewModel.addListener(_handleViewModelChange);
  }

  void _handleViewModelChange() {
    if (!mounted) return;
    final vm = widget.viewModel;

    if (vm.actionResult == AuthActionResult.success) {
      setState(() => _emailSent = true);
      vm.clearActionResult();
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      vm.clearActionResult();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    widget.viewModel.removeListener(_handleViewModelChange);
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.viewModel.sendPasswordReset(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? Colors.white70 : onSurface.withValues(alpha: 0.7),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: _emailSent ? _buildSuccessState() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isLoading = widget.viewModel.status == AuthStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Ícone decorativo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: cs.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recuperar senha',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Informe seu e-mail e enviaremos um link para você criar uma nova senha.',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('forgot_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'E-mail cadastrado',
                      labelStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: cs.onSurface.withValues(alpha: 0.35),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('forgot_submit_button'),
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Enviar link de recuperação',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessState() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Ícone de sucesso animado
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'E-mail enviado!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Verifique sua caixa de entrada em\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurface.withValues(alpha: 0.65),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Siga o link no e-mail para criar uma nova senha.\nNão esqueça de verificar a pasta de spam.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withValues(alpha: 0.5),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            key: const Key('back_to_login_button'),
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Voltar para o login',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          key: const Key('resend_email_button'),
          onPressed: () => setState(() => _emailSent = false),
          style: TextButton.styleFrom(
            foregroundColor: cs.onSurface.withValues(alpha: 0.5),
          ),
          child: const Text('Reenviar e-mail'),
        ),
      ],
    );
  }
}
