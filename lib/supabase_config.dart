import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ponto único de acesso ao cliente Supabase em todo o app.
/// Use `supabase.from(...)` para queries, `supabase.auth` para auth, etc.
final supabase = Supabase.instance.client;

/// Inicializa o Supabase lendo as credenciais do arquivo .env.
/// Deve ser chamado em [main] antes de [runApp].
Future<void> initializeSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  assert(url != null && url.isNotEmpty, 'SUPABASE_URL não encontrado no .env');
  assert(anonKey != null && anonKey.isNotEmpty, 'SUPABASE_ANON_KEY não encontrado no .env');

  await Supabase.initialize(
    url: url!,
    anonKey: anonKey!,
    debug: false, // mude para true durante desenvolvimento se precisar
  );
}
