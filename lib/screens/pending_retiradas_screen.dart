import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notas_zincao_flutter/services/retirada_sync_service.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';

class PendingRetiradasScreen extends StatefulWidget {
  const PendingRetiradasScreen({super.key});

  @override
  State<PendingRetiradasScreen> createState() => _PendingRetiradasScreenState();
}

class _PendingRetiradasScreenState extends State<PendingRetiradasScreen> {
  final RetiradaSyncService _syncService = RetiradaSyncService.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<PendingRetiradaItem> _items = const [];
  bool _loading = true;
  PendingRetiradaStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = _selectedStatus == null
        ? await _syncService.listarPendentes()
        : await _syncService.listarPorStatus(_selectedStatus!);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _syncAll() async {
    final result = await _syncService.processarComResumo();
    await _load();
    if (!mounted) return;

    final msg = result.processados == 0
        ? 'Nenhuma retirada pendente para sincronizar.'
        : 'Sincronização concluída: ${result.sucesso} sucesso(s), ${result.falhas} falha(s).';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _retryItem(PendingRetiradaItem item) async {
    final ok = await _syncService.processarItem(item.id);
    await _load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Retirada sincronizada com sucesso.'
              : 'Não foi possível sincronizar agora. Tente novamente.',
        ),
      ),
    );
  }

  Future<void> _deleteItem(PendingRetiradaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar retirada pendente?'),
        content: Text(
            'Descartar retirada da nota ${item.notaId}?\n\nAs fotos de comprovante serão deletadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _syncService.deletarItem(item.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retirada removida da fila.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover: $e')),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_done,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Não há retiradas pendentes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          // Filtros por status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ChoiceChip(
                  selected: _selectedStatus == null,
                  label: const Text('Todos'),
                  onSelected: (_) async {
                    setState(() => _selectedStatus = null);
                    await _load();
                  },
                ),
                const SizedBox(width: 8),
                ...PendingRetiradaStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _selectedStatus == status,
                      label: Text(status.label),
                      onSelected: (_) async {
                        setState(() => _selectedStatus = status);
                        await _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                final passouDoLimite = item.tentativas >= 3;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Nota ${item.notaId.substring(0, item.notaId.length >= 8 ? 8 : item.notaId.length)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: passouDoLimite
                                    ? Theme.of(context).colorScheme.errorContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Tentativas: ${item.tentativas}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: passouDoLimite
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Criado em: ${_dateFormat.format(item.timestamp.toLocal())}'),
                        const SizedBox(height: 4),
                        Text('Fotos: ${item.fotosPaths.length}'),
                        const SizedBox(height: 4),
                        Text('Itens da retirada: ${item.quantidades.length}'),
                        if ((item.erro ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Último erro: ${item.erro}',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _syncService.isProcessing.value
                                    ? null
                                    : () => _retryItem(item),
                                icon: const Icon(Icons.sync),
                                label: const Text('Tentar agora'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.errorContainer,
                              ),
                              onPressed: () => _deleteItem(item),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila de sincronização'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _syncService.isProcessing,
            builder: (context, processing, _) {
              return IconButton(
                tooltip: 'Sincronizar todas',
                onPressed: processing ? null : _syncAll,
                icon: processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
