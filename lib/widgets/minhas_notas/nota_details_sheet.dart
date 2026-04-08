import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:notas_zincao_flutter/constants/db_schema.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/widgets/minhas_notas/status_badge.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/screens/retirada_produtos_screen.dart';
import 'package:notas_zincao_flutter/services/nota_retirada_service.dart';
import 'package:notas_zincao_flutter/screens/nota_edit_screen.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/widgets/shared/action_dialogs.dart';
import 'package:notas_zincao_flutter/widgets/shared/full_screen_image_viewer.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

class _NotaDetailsActions {
  /// Remove caracteres nao numericos do telefone para preparar para WhatsApp/URL.
  static String sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  static void _showUnavailableMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Abre WhatsApp com o numero fornecido.
  static Future<void> openWhatsApp(BuildContext context, String phoneNumber) async {
    final sanitized = sanitizePhone(phoneNumber);
    final clean = sanitized.startsWith('+') ? sanitized.substring(1) : sanitized;
    if (clean.isEmpty) {
      _showUnavailableMessage(context, 'Telefone invalido para abrir no WhatsApp.');
      return;
    }

    final uris = <Uri>[
      Uri.parse('whatsapp://send?phone=$clean'),
      Uri.parse('https://wa.me/$clean'),
    ];

    for (final uri in uris) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (e) {
        debugPrint('Falha ao abrir $uri: $e');
      }
    }

    if (!context.mounted) return;
    _showUnavailableMessage(
      context,
      'Nao foi possivel abrir o WhatsApp neste dispositivo.',
    );
  }

  /// Faz uma chamada telefonica.
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    final sanitized = sanitizePhone(phoneNumber);
    if (sanitized.isEmpty) {
      _showUnavailableMessage(context, 'Telefone invalido para ligacao.');
      return;
    }

    final telUrl = Uri.parse('tel:$sanitized');

    try {
      final launched = await launchUrl(telUrl, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (e) {
      debugPrint('Erro ao fazer chamada: $e');
    }

    if (!context.mounted) return;
    _showUnavailableMessage(
      context,
      'Nao foi possivel iniciar a ligacao neste dispositivo.',
    );
  }

  static PopupMenuButton<String> buildAdminMenu(
    BuildContext context,
    NotaRetirada nota,
    Function()? onActionComplete,
  ) {
    final cs = Theme.of(context).colorScheme;
    final service = NotaRetiradaService();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: cs.onSurface),
      color: cs.surface,
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotaEditScreen(nota: nota, onSave: onActionComplete),
            ),
          );
        } else if (value == 'cancel') {
          showDialog(
            context: context,
            builder: (ctx) => ConfirmationDialog(
              title: 'Cancelar Nota',
              message: 'Tem certeza que deseja cancelar esta nota? Esta ação não pode ser desfeita.',
              confirmLabel: 'Sim, Cancelar',
              confirmColor: AppColors.warning,
              onConfirm: () async {
                try {
                  await service.cancel(nota.id);
                  if (!context.mounted) return;
                  if (onActionComplete != null) onActionComplete();
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (fctx) => const ActionFeedbackDialog(
                      isSuccess: true,
                      title: 'Sucesso!',
                      message: 'A nota foi cancelada com sucesso.',
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (fctx) => ActionFeedbackDialog(
                      isSuccess: false,
                      title: 'Erro',
                      message: 'Nao foi possivel cancelar a nota: $e',
                    ),
                  );
                }
              },
            ),
          );
        } else if (value == 'delete') {
          showDialog(
            context: context,
            builder: (ctx) => ConfirmationDialog(
              title: 'Excluir Nota',
              message: 'Deseja excluir permanentemente esta nota do sistema?',
              confirmLabel: 'Excluir Agora',
              confirmColor: AppColors.error,
              onConfirm: () async {
                try {
                  await service.delete(nota.id);
                  if (!context.mounted) return;
                  if (onActionComplete != null) onActionComplete();
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (fctx) => const ActionFeedbackDialog(
                      isSuccess: true,
                      title: 'Excluida!',
                      message: 'A nota foi removida definitivamente do sistema.',
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (fctx) => ActionFeedbackDialog(
                      isSuccess: false,
                      title: 'Erro',
                      message: 'Ocorreu um erro ao tentar excluir: $e',
                    ),
                  );
                }
              },
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text('Editar Nota (Admin)', style: TextStyle(color: cs.onSurface))),
        if (nota.statusRetirada != StatusRetirada.cancelada)
          PopupMenuItem(value: 'cancel', child: Text('Cancelar Nota', style: TextStyle(color: cs.onSurface))),
        PopupMenuItem(value: 'delete', child: Text('Excluir Nota', style: TextStyle(color: cs.onSurface))),
      ],
    );
  }
}

void showNotaDetails(BuildContext context, NotaRetirada nota, AuthViewModel authViewModel, [Function()? onActionComplete]) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final cs = Theme.of(context).colorScheme;
          final isElegivelParaRetirada = 
              nota.statusRetirada != StatusRetirada.retirada && 
              nota.statusRetirada != StatusRetirada.cancelada;
              
          final isAdmin = authViewModel.profile?.role == 'admin';
          final isColaborador = authViewModel.profile?.role == 'colaborador';
          final canMakeRetirada = isElegivelParaRetirada && (isAdmin || isColaborador);

          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Hanlder de puxar e cabeçalho fixo
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: nota.statusRetirada),
                      Row(
                        children: [
                          if (isAdmin)
                              _NotaDetailsActions.buildAdminMenu(context, nota, onActionComplete),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: cs.onSurface),
                          ),
                        ]
                      )
                    ],
                  ),
                ),

                // Conteúdo rolável
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destaque do cliente e nota
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Nota: ${nota.numeroNota}",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nota.nomeCliente.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: cs.onSurface.withValues(alpha: 0.6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(nota.criadoEm),
                                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75), fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: cs.onSurface.withValues(alpha: 0.6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cadastrado por: ${nota.cadastradoPorNome ?? '—'}',
                                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75), fontSize: 13),
                                  ),
                                ],
                              ),
                              if (nota.telefoneCliente != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 14, color: cs.onSurface.withValues(alpha: 0.6)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              nota.telefoneCliente!,
                                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75), fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: 'WhatsApp',
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          iconSize: 18,
                                          onPressed: () => _NotaDetailsActions.openWhatsApp(context, nota.telefoneCliente!),
                                          icon: Icon(
                                            Icons.chat_bubble_outline,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Ligar',
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          iconSize: 18,
                                          onPressed: () => _NotaDetailsActions.makePhoneCall(context, nota.telefoneCliente!),
                                          icon: Icon(
                                            Icons.call_outlined,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Text('Lista de Produtos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: nota.produtos.map((p) {
                              final nome = p[ColsProdutoNota.nome] ?? 'Produto';
                              final idProduto = p[ColsProdutoNota.idProdutoEstoque]?.toString() ?? '-';
                              final qtdOriginal = double.tryParse(p[ColsProdutoNota.quantidade]?.toString() ?? '1') ?? 1.0;
                              final qtdRetirada = double.tryParse(p[ColsProdutoNota.quantidadeRetirada]?.toString() ?? '0') ?? 0.0;
                              final tipoStr = p[ColsProdutoNota.tipoUnidade] ?? 'UN';
                              final isComplete = qtdRetirada >= qtdOriginal;
                              final valorUnit = p[ColsProdutoNota.valorUnitario];

                              return ListTile(
                                leading: Icon(
                                  isComplete ? Icons.check_circle : Icons.inventory_2_outlined,
                                  color: isComplete ? AppColors.success : cs.onSurfaceVariant,
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(nome, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500)),
                                    Text(
                                      'ID: $idProduto',
                                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Comprado: $qtdOriginal $tipoStr | Entregue: $qtdRetirada $tipoStr',
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                ),
                                trailing: valorUnit != null
                                    ? Text(
                                        NumberFormat.simpleCurrency(locale: 'pt_BR').format((valorUnit as num).toDouble()),
                                        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              );
                            }).toList(),
                          ),
                        ),
                        
                        if (nota.observacoes != null) ...[
                          const SizedBox(height: 24),
                          Text('Observações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          const SizedBox(height: 8),
                          Container(
                             padding: const EdgeInsets.all(16),
                             width: double.infinity,
                             decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                             child: Text(nota.observacoes!, style: const TextStyle(color: AppColors.warning)),
                          ),
                        ],

                        // ─── Cupom Fiscal ───
                        if (nota.fotoUrl != null) ...[
                          const SizedBox(height: 24),
                          Text('Cupom Fiscal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => FullScreenImageViewer.show(context, nota.fotoUrl!, tag: 'cupom_${nota.id}'),
                            child: Hero(
                              tag: 'cupom_${nota.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  nota.fotoUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                        const SizedBox(height: 8),
                                        Text('Imagem indisponível', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ─── Histórico de Retiradas (Eventos) ───
                        if (nota.historicoRetiradas != null && nota.historicoRetiradas!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Histórico de Retiradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                          const SizedBox(height: 12),
                          ...nota.historicoRetiradas!.map((evento) {
                             final dataStr = evento['data'] as String?;
                             final dt = dataStr != null ? DateTime.tryParse(dataStr) : null;
                             final dtFormatted = dt != null ? DateFormat("dd/MM/yyyy 'às' HH:mm").format(dt) : 'Data Desconhecida';
                              final responsavelNome = (evento['responsavel_nome'] ?? '').toString().trim();
                              final responsavelId = (evento['responsavel_id'] ?? '').toString().trim();
                             
                             final listaItens = evento['itens_retirados'] as List<dynamic>?;
                             final fotos = evento['fotos'] as List<dynamic>?;
                             
                             return Container(
                               margin: const EdgeInsets.only(bottom: 12),
                               padding: const EdgeInsets.all(16),
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 color: AppColors.info.withValues(alpha: 0.08),
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     children: [
                                       const Icon(Icons.history, color: AppColors.info, size: 20),
                                       const SizedBox(width: 8),
                                       Expanded(
                                         child: Text(
                                           'Retirada em $dtFormatted',
                                           style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                                         ),
                                       ),
                                     ],
                                   ),
                                   if (responsavelNome.isNotEmpty || responsavelId.isNotEmpty) ...[
                                     const SizedBox(height: 8),
                                     Row(
                                       children: [
                                         Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                                         const SizedBox(width: 6),
                                         Expanded(
                                           child: Text(
                                             responsavelNome.isNotEmpty
                                                 ? 'Retirada por: $responsavelNome'
                                                 : 'Retirada por usuário: $responsavelId',
                                             style: TextStyle(
                                               color: cs.onSurfaceVariant,
                                               fontSize: 13,
                                               fontWeight: FontWeight.w600,
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                   if (listaItens != null && listaItens.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text('Itens Entregues:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      ...listaItens.map((item) {
                                        final idx = item['index'];
                                        final qtd = item['quantidade'];
                                        String nome = 'Desconhecido';
                                        if (idx is int && idx >= 0 && idx < nota.produtos.length) {
                                          final prod = nota.produtos[idx];
                                          if (prod is Map<String, dynamic>) {
                                            nome = (prod[ColsProdutoNota.nome] ?? 'Desconhecido').toString();
                                          }
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text('• $qtd x $nome', style: TextStyle(color: cs.onSurface, fontSize: 14)),
                                        );
                                      }),
                                   ],
                                   if (fotos != null && fotos.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text('Evidências / Fotos:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 80,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: fotos.length,
                                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                                          itemBuilder: (ctx, i) {
                                            final fotoUrl = fotos[i] as String;
                                            return GestureDetector(
                                              onTap: () => FullScreenImageViewer.show(context, fotoUrl, tag: 'hist_${evento['data']}_$i'),
                                              child: Hero(
                                                tag: 'hist_${evento['data']}_$i',
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    fotoUrl,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 80,
                                                      height: 80,
                                                      decoration: BoxDecoration(
                                                        color: cs.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(Icons.broken_image_outlined, size: 24, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        )
                                      )
                                   ]
                                 ]
                               )
                             );
                          })
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // ─── Botão Fixo no Rodapé ───
                if (canMakeRetirada)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24).copyWith(top: 16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(
                        top: BorderSide(
                          color: cs.outlineVariant,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Fecha o bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RetiradaProdutosScreen(
                                nota: nota,
                                authViewModel: authViewModel,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.outbox, color: cs.onPrimary),
                        label: Text(
                          'Fazer Nova Retirada',
                          style: GoogleFonts.inter(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
