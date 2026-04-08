// Constantes de colunas para todas as tabelas do Supabase.
//
// Use estas constantes em vez de strings literais nas queries para ter
// verificação em tempo de compilação e facilitar refatorações.
//
// Exemplo:
//   supabase.from(DbTables.notasRetirada)
//     .select()
//     .eq(ColsNotasRetirada.ownerUserId, userId)
//     .order(ColsNotasRetirada.criadoEm, ascending: false);

// ─── notas_retirada ───────────────────────────────────────────────────────────

abstract class ColsNotasRetirada {
  /// UUID — chave primária gerada pelo banco.
  static const id = 'id';

  /// UUID do usuário dono da nota (FK → auth.users).
  static const ownerUserId = 'owner_user_id';

  /// URL pública da foto do cupom no Storage.
  static const fotoUrl = 'foto_url';

  /// Nome completo do cliente.
  static const nomeCliente = 'nome_cliente';

  /// CPF ou CNPJ do cliente.
  static const documentoCliente = 'documento_cliente';

  /// Telefone do cliente (usado para vincular ao CRM).
  static const telefoneCliente = 'telefone_cliente';

  /// Número da nota fiscal (ex: "000001").
  static const numeroNota = 'numero_nota';

  /// Série da nota fiscal (padrão: "1").
  static const serieNota = 'serie_nota';

  /// Chave de acesso da NFe (44 dígitos).
  static const chaveNfe = 'chave_nfe';

  /// Data da compra (formato YYYY-MM-DD).
  static const dataCompra = 'data_compra';

  /// Data prevista para retirada (opcional).
  static const dataPrevistaRetirada = 'data_prevista_retirada';

  /// Array JSON de produtos — ver [ProdutoNota].
  static const produtos = 'produtos';

  /// Array JSON com histórico de retiradas parciais.
  static const historicoRetiradas = 'historico_retiradas';

  /// Valor bruto total da nota.
  static const valorTotal = 'valor_total';

  /// Desconto total aplicado na nota.
  static const descontoTotal = 'desconto_total';

  /// Observações livres.
  static const observacoes = 'observacoes';

  /// Status atual da retirada: pendente | parcial | retirada | cancelada.
  static const statusRetirada = 'status_retirada';

  /// Data efetiva da retirada completa.
  static const dataRetirada = 'data_retirada';

  /// ID do usuário que confirmou a retirada.
  static const retiradaConfirmadaPor = 'retirada_confirmada_por';

  /// URL do comprovante de retirada.
  static const comprovanteRetiradaUrl = 'comprovante_retirada_url';

  /// Timestamp de criação (gerado pelo banco).
  static const criadoEm = 'criado_em';

  /// Timestamp da última atualização.
  static const atualizadoEm = 'atualizado_em';

  /// Identificador do contato (telefone) — FK → crm_zincao.contato_id.
  static const contatoId = 'contato_id';
}

// ─── bd_estoque_geral ─────────────────────────────────────────────────────────
// Atenção: esta tabela usa colunas em MAIÚSCULAS.

abstract class ColsEstoqueGeral {
  /// INT — chave primária do produto.
  static const idProduto = 'IDPRODUTO';

  /// Descrição/nome do produto.
  static const descricao = 'DESCRICAO';

  /// Unidade de embalagem de saída (ex: UN, CX, KG).
  static const embalagemSaida = 'EMBALAGEMSAIDA';

  /// Categoria/tipo do produto.
  static const tipoProduto = 'TIPOPRODUTO';

  /// Quantidade em estoque.
  static const quantidadeEstoque = 'QUANTIDADEESTOQUE';

  /// Preço de venda no varejo.
  static const valPrecoVarejo = 'VALPRECOVAREJO';

  /// ID do produto pai do qual o estoque é deduzido.
  static const idProdutoPai = 'IDPRODUTOPAI';

  /// Multiplicador de dedução do produto pai (ex: 0.5).
  static const fatorConversao = 'FATORCONVERSAO';
}

// ─── crm_zincao ───────────────────────────────────────────────────────────────

abstract class ColsCrmZincao {
  /// Telefone do cliente — chave primária (ex: "11999998888").
  static const contatoId = 'contato_id';

  /// Nome do cliente.
  static const nome = 'nome';
}

// ─── profiles ─────────────────────────────────────────────────────────────────

abstract class ColsProfiles {
  /// UUID — chave primária do perfil.
  static const id = 'id';

  /// UUID do usuário no Supabase Auth (FK → auth.users).
  static const authUid = 'auth_uid';

  /// Nome de exibição do usuário.
  static const nome = 'nome';

  /// E-mail do usuário.
  static const email = 'email';

  /// Papel do usuário no sistema (ex: "admin", "colaborador").
  static const role = 'role';

  /// Lista de workspaces/grupos a que o usuário pertence.
  static const workspaces = 'workspaces';

  /// Timestamp do último login.
  static const ultimoLogin = 'ultimo_login';

  /// URL da foto de perfil.
  static const fotoPerfil = 'foto_perfil';

  /// Timestamp da última atualização do perfil.
  static const updatedAt = 'updated_at';
}

// ─── Campos do JSON aninhado produtos[] ──────────────────────────────────────
// Colunas do objeto ProdutoNota dentro de notas_retirada.produtos.

abstract class ColsProdutoNota {
  static const idProdutoEstoque = 'id_produto_estoque';
  static const nome = 'nome';
  static const tipoProduto = 'tipo_produto';
  static const quantidade = 'quantidade';
  static const quantidadeRetirada = 'quantidade_retirada';
  static const embalagem = 'embalagem';
  static const tipoUnidade = 'tipo_unidade';
  static const valorUnitario = 'valor_unitario';
  static const valorTotal = 'valor_total';
}

// ─── RPC Functions ───────────────────────────────────────────────────────────

abstract class RpcFunctions {
  /// Debita estoque atomicamente. Retorna a quantidade efetivamente retirada.
  /// Params: [p_id_produto] (int), [p_quantidade_solicitada] (double).
  static const baixarEstoqueProduto = 'baixar_estoque_produto';
}
