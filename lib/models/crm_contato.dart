import 'package:notas_zincao_flutter/constants/db_schema.dart';

/// Contato armazenado na tabela `crm_zincao`.
/// O [contatoId] é o número de telefone e serve como chave primária.
class CrmContato {
  final String contatoId;
  final String nome;

  const CrmContato({required this.contatoId, required this.nome});

  factory CrmContato.fromMap(Map<String, dynamic> map) {
    return CrmContato(
      contatoId: map[ColsCrmZincao.contatoId] as String,
      nome: map[ColsCrmZincao.nome] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        ColsCrmZincao.contatoId: contatoId,
        ColsCrmZincao.nome: nome,
      };

  CrmContato copyWith({String? contatoId, String? nome}) => CrmContato(
        contatoId: contatoId ?? this.contatoId,
        nome: nome ?? this.nome,
      );

  @override
  String toString() => 'CrmContato(contatoId: $contatoId, nome: $nome)';
}
