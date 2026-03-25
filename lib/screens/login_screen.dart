import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/screens/forgot_password_screen.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/theme/theme_controller.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

/// Tela de autenticação com duas abas: Login e Cadastro.
class LoginScreen extends StatefulWidget {
  final AuthViewModel viewModel;

  const LoginScreen({super.key, required this.viewModel});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {}); // Rebuild para trocar o formulário e ajustar altura
    });
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    widget.viewModel.addListener(_handleViewModelChange);
  }

  void _handleViewModelChange() {
    final vm = widget.viewModel;
    if (!mounted) return;

    // Exibe erros de login/cadastro
    if (vm.errorMessage != null) {
      _showToast(vm.errorMessage!, isError: true);
      vm.clearActionResult();
      return;
    }

    // Exibe mensagem de sucesso no cadastro e volta para aba de login
    if (vm.actionResult == AuthActionResult.success && vm.actionMessage != null) {
      _showToast(vm.actionMessage!, isError: false);
      _tabController.animateTo(0);
      vm.clearActionResult();
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    widget.viewModel.removeListener(_handleViewModelChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Alternar tema',
                      onPressed: ThemeController.instance.toggleTheme,
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  _buildLogo(),
                  const SizedBox(height: 36),
                  _buildTabCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.15),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset('public/logo-icone.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 18),
        Text(
          'Notas Zincão',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gestão de notas de retirada',
          style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildTabCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          // Abas
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: cs.onPrimary,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Entrar'),
                Tab(text: 'Cadastrar'),
              ],
            ),
          ),
          // Conteúdo das abas com altura dinâmica
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _tabController.index == 0
                ? _LoginForm(
                    key: const ValueKey('login_form'),
                    viewModel: widget.viewModel,
                  )
                : _SignUpForm(
                    key: const ValueKey('signup_form'),
                    viewModel: widget.viewModel,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário de Login
// ---------------------------------------------------------------------------
class _LoginForm extends StatefulWidget {
  final AuthViewModel viewModel;

  const _LoginForm({super.key, required this.viewModel});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isLoading = widget.viewModel.status == AuthStatus.loading;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AuthTextField(
                  id: 'login_email_field',
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                _AuthTextField(
                  id: 'login_password_field',
                  controller: _passwordController,
                  label: 'Senha',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  enabled: !isLoading,
                  validator: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('forgot_password_link'),
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ForgotPasswordScreen(
                                  viewModel: widget.viewModel,
                                ),
                              ),
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Esqueci minha senha', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                _SubmitButton(
                  id: 'login_submit_button',
                  label: 'Entrar',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Formulário de Cadastro
// ---------------------------------------------------------------------------
class _SignUpForm extends StatefulWidget {
  final AuthViewModel viewModel;

  const _SignUpForm({super.key, required this.viewModel});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.viewModel.signUp(
      nome: _nomeController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isLoading = widget.viewModel.status == AuthStatus.loading;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthTextField(
                    id: 'signup_nome_field',
                    controller: _nomeController,
                    label: 'Nome completo',
                    icon: Icons.person_outline_rounded,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe seu nome';
                      if (v.trim().length < 2) return 'Nome muito curto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _AuthTextField(
                    id: 'signup_email_field',
                    controller: _emailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  _AuthTextField(
                    id: 'signup_password_field',
                    controller: _passwordController,
                    label: 'Senha',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AuthTextField(
                    id: 'signup_confirm_field',
                    controller: _confirmPasswordController,
                    label: 'Confirmar senha',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirm,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirme sua senha';
                      if (v != _passwordController.text) return 'As senhas não coincidem';
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SubmitButton(
                    id: 'signup_submit_button',
                    label: 'Criar conta',
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets compartilhados
// ---------------------------------------------------------------------------

String? _validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'E-mail inválido';
  return null;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Informe a senha';
  if (v.length < 6) return 'Mínimo de 6 caracteres';
  return null;
}

class _AuthTextField extends StatelessWidget {
  final String id;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.id,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      key: Key(id),
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String id;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.id,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        key: Key(id),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                label,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
