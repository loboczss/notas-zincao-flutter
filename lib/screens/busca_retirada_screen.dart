import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';

class BuscaRetiradaScreen extends StatelessWidget {
  final AuthViewModel authViewModel;

  const BuscaRetiradaScreen({super.key, required this.authViewModel});

  @override
  Widget build(BuildContext context) {
    // Redireciona visualmente para a lista padrão onde o usuário acha a nota,
    // mas pode futuramente ter um leitor de QRCode da Nota
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          Text(
            'Efetuar Retirada',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Busque a nota na lista para iniciar\nou aguarde o leitor de QR Code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
