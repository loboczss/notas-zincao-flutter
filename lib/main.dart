import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:notas_zincao_flutter/router/app_router.dart';
import 'package:notas_zincao_flutter/services/auth_service.dart';
import 'package:notas_zincao_flutter/supabase_config.dart';
import 'package:notas_zincao_flutter/theme/app_theme.dart';
import 'package:notas_zincao_flutter/theme/theme_controller.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega as variáveis de ambiente do arquivo .env
  await dotenv.load(fileName: 'assets/.env');

  // 2. Inicializa o Supabase com as credenciais do .env
  await initializeSupabase();

  // 3. Instancia o ViewModel de autenticação (singleton durante a vida do app)
  final authViewModel = AuthViewModel(AuthService());

  // 4. Inicializa tema persistido (light/dark)
  await ThemeController.instance.init();

  runApp(NotasZincaoApp(authViewModel: authViewModel));
}

class NotasZincaoApp extends StatelessWidget {
  final AuthViewModel authViewModel;

  const NotasZincaoApp({super.key, required this.authViewModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'Notas Zincão',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          home: AppRouter(authViewModel: authViewModel),
        );
      },
    );
  }
}
