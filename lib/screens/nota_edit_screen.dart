import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/models/nota_retirada.dart';
import 'package:notas_zincao_flutter/services/nota_retirada_service.dart';
import 'package:notas_zincao_flutter/theme/app_colors.dart';
import 'package:notas_zincao_flutter/widgets/shared/app_error_feedback.dart';

class NotaEditScreen extends StatefulWidget {
  final NotaRetirada nota;
  final Function()? onSave;

  const NotaEditScreen({super.key, required this.nota, this.onSave});

  @override
  State<NotaEditScreen> createState() => _NotaEditScreenState();
}

class _NotaEditScreenState extends State<NotaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = NotaRetiradaService();
  
  late TextEditingController _nomeClienteCtrl;
  late TextEditingController _telefoneClienteCtrl;
  late TextEditingController _numeroNotaCtrl;
  late TextEditingController _observacoesCtrl;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeClienteCtrl = TextEditingController(text: widget.nota.nomeCliente);
    _telefoneClienteCtrl = TextEditingController(text: widget.nota.telefoneCliente);
    _numeroNotaCtrl = TextEditingController(text: widget.nota.numeroNota);
    _observacoesCtrl = TextEditingController(text: widget.nota.observacoes ?? '');
  }

  @override
  void dispose() {
    _nomeClienteCtrl.dispose();
    _telefoneClienteCtrl.dispose();
    _numeroNotaCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updatedNota = widget.nota.copyWith(
         nomeCliente: _nomeClienteCtrl.text.trim(),
         telefoneCliente: _telefoneClienteCtrl.text.trim().isEmpty ? null : _telefoneClienteCtrl.text.trim(),
         numeroNota: _numeroNotaCtrl.text.trim(),
         observacoes: _observacoesCtrl.text.trim().isEmpty ? null : _observacoesCtrl.text.trim(),
      );
      
      await _service.update(updatedNota);
      
      if (mounted) {
         if (widget.onSave != null) widget.onSave!();
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota salva com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
         AppErrorFeedback.show(
           context,
           error: e,
           fallbackMessage: 'Não foi possível salvar as alterações da nota.',
         );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Editar Nota', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 18)),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _numeroNotaCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _buildInputDecoration('Número da Nota', Icons.tag),
                validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeClienteCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _buildInputDecoration('Nome do Cliente', Icons.person),
                validator: (val) => val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneClienteCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _buildInputDecoration('Telefone', Icons.phone),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacoesCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                maxLines: 3,
                decoration: _buildInputDecoration('Observações', Icons.notes),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                    ? CircularProgressIndicator(color: colorScheme.onPrimary)
                    : Text('Salvar Alterações', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              )
            ]
          )
        )
      )
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}
