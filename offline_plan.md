# Plano de Suporte Offline — Notas Zincão

## Situação Atual

O app **não tem suporte offline**. Toda leitura e escrita vai direto ao Supabase. Sem internet:
- A tela de notas não carrega
- Não é possível cadastrar notas nem retiradas
- O estoque não aparece
- Uploads de foto falham silenciosamente

---

## Estratégia Adotada: Offline-First com Fila de Sincronização

**Princípio:** O app opera com dados locais (SQLite via `drift`). Quando há conexão, sincroniza com o Supabase em segundo plano.

```
[App]  ←read/write→  [SQLite Local]  ←sync→  [Supabase]
                         ↑
                    [Fila de Sync]
```

---

## Sprint 1 — Infraestrutura Base

### 1.1 Dependências a adicionar (`pubspec.yaml`)

```yaml
dependencies:
  connectivity_plus: ^6.1.1      # detectar estado da rede
  drift: ^2.21.0                 # ORM SQLite type-safe
  drift_flutter: ^0.2.4          # integração Flutter
  sqlite3_flutter_libs: ^0.5.28  # binários SQLite

dev_dependencies:
  drift_dev: ^2.21.0
  build_runner: ^2.4.0
```

### 1.2 Serviço de Conectividade (`lib/services/connectivity_service.dart`)

- Expõe `Stream<bool> isOnlineStream`
- Expõe `bool get isOnlineSync` (síncrono para guards imediatos)
- Usa `connectivity_plus` + validação real (ping ao Supabase ou DNS)
- Singleton acessível globalmente via Provider

### 1.3 Banco de Dados Local (`lib/database/`)

Criar schema com `drift`:

**Tabelas locais:**

| Tabela | Finalidade |
|--------|-----------|
| `notas_cache` | Espelho de `notas_retirada` (todas as notas carregadas) |
| `estoque_cache` | Espelho de `bd_estoque_geral` (produtos pesquisados/paginados) |
| `profiles_cache` | Perfis de usuário vistos até agora |
| `sync_queue` | Operações pendentes para sincronizar quando voltar a internet |

**Schema `sync_queue`:**
```sql
CREATE TABLE sync_queue (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  operacao    TEXT NOT NULL,   -- 'create_nota' | 'create_retirada' | 'upload_foto' | 'update_nota'
  payload     TEXT NOT NULL,   -- JSON com os dados da operação
  tentativas  INTEGER DEFAULT 0,
  criado_em   TEXT NOT NULL,
  erro_ultimo TEXT             -- último erro para exibição
);
```

---

## Sprint 2 — Cache de Leituras

### 2.1 Notas (`NotaRetiradaService`)

**Fluxo proposto:**
```
fetchNotas() →
  1. Retorna dados do SQLite imediatamente (UI renderiza)
  2. Se online: busca do Supabase → atualiza SQLite → UI atualiza via Stream
  3. Se offline: UI mostra banner "Exibindo dados salvos"
```

**Implementação:**
- `NotaRetiradaService.watchNotas()` retorna `Stream<List<NotaRetirada>>` do drift
- Refresh em background via `_syncNotasFromRemote()` chamado quando online

**O que cachear:**
- Todas as notas do usuário (campo `owner_user_id`)
- Admins: notas dos últimos 90 dias (limitar tamanho do cache)
- Fotos: **não** cachear binários — manter URLs, exibir placeholder offline

### 2.2 Estoque (`EstoqueProdutoService`)

- Cache dos produtos já pesquisados (LRU simples em SQLite)
- Expiração: 1 hora (campo `cached_at` na tabela)
- Pesquisa offline: full-text search local na coluna `DESCRICAO`
- Estoque exibido como **"valor aproximado — offline"** quando não há refresh recente

### 2.3 Perfil do Usuário

- Cache do `Profile` do usuário logado em `shared_preferences` (já tem, expandir)
- Cache de perfis de outros usuários em `profiles_cache` (necessário para exibir autores das notas)

---

## Sprint 3 — Fila de Escritas (Write Queue)

### 3.1 Criação de Nota

**Offline:**
1. Salvar foto localmente (em `path_provider` → diretório de app)
2. Criar `NotaRetirada` com `id` temporário (UUID local, prefixo `local_`)
3. Inserir na `notas_cache` com `status_sync = 'pending'`
4. Inserir na `sync_queue` com operação `create_nota`
5. UI exibe nota normalmente com badge "Aguardando sincronização"

**AI/OCR desabilitado offline:**
- Se offline, desabilitar o botão de "extrair dados automaticamente"
- Exibir mensagem: "Preenchimento automático requer internet. Preencha manualmente."
- Formulário manual permanece 100% funcional

### 3.2 Registro de Retirada

**Offline:**
1. Salvar fotos de prova localmente
2. Criar evento de retirada localmente (atualizar `historicoRetiradas` no cache)
3. Atualizar `statusRetirada` local otimisticamente
4. Inserir na `sync_queue` com operação `create_retirada`
5. **NÃO deduzir estoque local** (RPC de estoque é crítico, marcar como pendente)

### 3.3 Motor de Sincronização (`lib/services/sync_service.dart`)

```
SyncService (Singleton)
├── listenConnectivity()          → ao voltar online, dispara _processSyncQueue()
├── _processSyncQueue()           → processa itens em ordem FIFO
│   ├── _syncCreateNota()         → upload foto + insert Supabase + remover local_id
│   ├── _syncCreateRetirada()     → insert histórico + chamar RPC de estoque
│   └── _syncUploadFoto()         → upload foto isolado (retry de falha anterior)
├── _handleConflict()             → server wins por padrão
└── markAsError(id, mensagem)     → registra erro para exibição ao usuário
```

**Política de retry:**
- Máximo 3 tentativas por item
- Backoff exponencial: 30s → 2min → 10min
- Após 3 falhas: item marcado como `failed`, usuário notificado

---

## Sprint 4 — UX Adaptações

### 4.1 Indicador de Conexão

- Banner no topo da tela principal quando offline: `"Modo offline — dados podem não estar atualizados"`
- Ícone de sincronização no AppBar quando há itens na fila

### 4.2 Estados de Sincronização nas Notas

Badge visual nas notas com `status_sync`:
- Sem badge → sincronizado
- `⏳ Pendente` → na fila de sync
- `❌ Erro` → falha no sync, com botão "Tentar novamente"

### 4.3 Desabilitar Ações Impossíveis Offline

| Ação | Comportamento Offline |
|------|-----------------------|
| OCR automático (OpenAI) | Desabilitado, tooltip explicativo |
| Exportar relatório PDF | Disponível (dados locais) |
| Cancelar nota | Enfileirado para sync |
| Ver foto do cupom | Exibe da URL (pode falhar) ou placeholder |
| Atualizar estoque (RPC) | Enfileirado para sync |

---

## Sprint 5 — Resolução de Conflitos

### Regras de conflito (server wins na maioria dos casos):

**Notas:**
- Se nota local `pending` foi criada offline e uma nota com mesmo `chaveNfe` já existe no servidor → **descartar local, notificar usuário**
- Se nota local foi atualizada offline e servidor tem versão mais nova → **server wins** (comparar `atualizado_em`)

**Retiradas:**
- Registro de retirada é append-only → sem conflito estrutural
- Quantidade de estoque → sempre processar em ordem cronológica pelo servidor

**Estratégia geral:** `updated_at` timestamp para detectar conflitos. Em caso de conflito, o servidor prevalece e o usuário é notificado sobre o dado descartado.

---

## Decisões de Design

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| ORM local | `drift` | Type-safe, streams nativos, boa integração Flutter |
| Tamanho do cache | 90 dias / usuário | Evitar crescimento ilimitado do SQLite |
| Fotos offline | Apenas locais (não sync remoto) | Evitar consumo de armazenamento excessivo |
| OCR offline | Não suportado | OpenAI requer servidor; investimento alto para benefício limitado |
| Estoque offline | Somente leitura (cache) | RPC de deduç ão é crítica para integridade |
| Conflito | Server wins | Simplicidade; dados de estoque/retirada são críticos |

---

## Ordem de Implementação Recomendada

```
Sprint 1  →  Infraestrutura (connectivity + drift + schema)         ~1-2 dias
Sprint 2  →  Cache de leitura de notas                              ~1-2 dias  
Sprint 3  →  Fila de escrita + motor de sync                        ~2-3 dias
Sprint 4  →  UX / indicadores visuais                               ~1 dia
Sprint 5  →  Resolução de conflitos                                 ~1 dia
```

**Total estimado:** ~6-9 dias de desenvolvimento.

---

## Arquivos que Serão Criados/Modificados

### Novos arquivos:
```
lib/database/
  app_database.dart           # schema drift + DAOs
  app_database.g.dart         # gerado pelo build_runner
  daos/
    notas_dao.dart
    estoque_dao.dart
    sync_queue_dao.dart

lib/services/
  connectivity_service.dart   # estado da rede
  sync_service.dart           # motor de sincronização

lib/models/
  sync_queue_item.dart        # modelo da fila de sync
```

### Modificações:
```
lib/services/nota_retirada_service.dart      # retornar Stream do drift, sync em background
lib/services/estoque_produto_service.dart    # cache de pesquisa
lib/services/retirada_form_service.dart      # enfileirar quando offline
lib/services/nota_form_service.dart          # desabilitar OCR offline, salvar foto local
lib/viewmodels/nota_form_viewmodel.dart      # verificar conectividade antes de OCR
lib/widgets/                                 # badge de sync, banner offline
pubspec.yaml                                 # novas dependências
```
