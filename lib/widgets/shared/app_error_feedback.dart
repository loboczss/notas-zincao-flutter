import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

class AppErrorFeedback {
  static void show(
    BuildContext context, {
    String? message,
    Object? error,
    String? fallbackMessage,
  }) {
    final friendly = AppErrorMessageMapper.map(
      message: message,
      error: error,
      fallbackMessage: fallbackMessage,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: AppErrorSnackBarContent(message: friendly),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          duration: const Duration(seconds: 5),
        ),
      );
  }
}

class AppErrorSnackBarContent extends StatelessWidget {
  final String message;

  const AppErrorSnackBarContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppErrorMessageMapper {
  static String map({
    String? message,
    Object? error,
    String? fallbackMessage,
  }) {
    final raw = [message, error?.toString()]
        .whereType<String>()
        .join(' ')
        .trim()
        .toLowerCase();

    if (raw.isEmpty) {
      return fallbackMessage ?? 'Ocorreu um erro inesperado. Tente novamente.';
    }

    if (raw.contains('uq_notas_retirada_owner_numero_serie') ||
        raw.contains('duplicate key value violates unique constraint') ||
        raw.contains('23505')) {
      return 'Já existe uma nota com este número e série para este usuário.';
    }

    if (raw.contains('usuário não autenticado') || raw.contains('usuario nao autenticado')) {
      return 'Sua sessão expirou. Faça login novamente para continuar.';
    }

    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'A operação demorou mais do que o esperado. Tente novamente.';
    }

    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }

    if (raw.contains('invalid input syntax for type') || raw.contains('data de compra inválida')) {
      return 'Há dados inválidos no formulário. Revise os campos e tente novamente.';
    }

    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }

    return fallbackMessage ?? 'Não foi possível concluir a operação. Tente novamente.';
  }
}
