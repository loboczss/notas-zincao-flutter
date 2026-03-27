# Auditoria do App Flutter — Plano de Correções

Resultado da análise completa dos 38 arquivos Dart do projeto `notas-zincao-flutter`. Os problemas estão organizados por **criticidade** (🔴 Crítico → 🟡 Moderado → 🟢 Melhoria).

---

## User Review Required

> [!CAUTION]
> **Segurança da API Key OpenAI:** A chave da OpenAI (`OPENAI_API_KEY`) está sendo lida diretamente no app cliente e enviada via HTTP. Qualquer pessoa que descompilar o APK terá acesso à chave. A recomendação é mover a chamada para uma Edge Function no Supabase ou um proxy server. **Isso requer decisão sua sobre a abordagem.**


> [!IMPORTANT]
> **Cobertura de testes:** O projeto não possui testes reais (apenas um placeholder). O plano inclui sugestão de testes unitários para ViewModels, mas preciso de confirmação se deseja que eu os crie agora ou em etapa futura.

---

## Problemas Encontrados

### 🔴 P1 — Segurança: API Key OpenAI exposta no cliente

**Arquivo:** [nota_form_service.dart](file:///d:/dev/notas-zincao-flutter/lib/services/nota_form_service.dart#L189-L200)

A `OPENAI_API_KEY` é lida do `.env` e usada direto do Flutter para chamar `api.openai.com`. Isso significa que:
- Qualquer usuário pode extrair a chave do APK
- A chave pode ser usada fora do app sem limite

**Correção proposta:** Criar uma Edge Function no Supabase que receba a imagem e faça a chamada à OpenAI no server-side, removendo a key do cliente.

---

### 🔴 P2 — Crash: Acesso a índice sem validação no histórico de retiradas

**Arquivo:** [nota_details_sheet.dart](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#L442-L446)

```dart
final idx = item['index'];
final prod = nota.produtos[idx]; // ← CRASH se idx >= produtos.length ou null
```

Se os dados do histórico estiverem inconsistentes (produto removido, index corrompido), o app **crashará** com `RangeError`.

**Correção:** Validar que `idx` é um `int` válido dentro do range antes de acessar.

---

### 🔴 P3 — Crash: cast de [Map](file:///d:/dev/notas-zincao-flutter/lib/models/profile.dart#45-58) sem verificação segura

**Arquivo:** [retirada_form_viewmodel.dart](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/retirada_form_viewmodel.dart#L54)

```dart
final p = notaSelecionada!.produtos[i] as Map<String, dynamic>; // ← crash se não for Map
```

Se `produtos[i]` for `null` ou não for um [Map](file:///d:/dev/notas-zincao-flutter/lib/models/profile.dart#45-58), o app crashará. O mesmo padrão se repete em [retirada_produtos_screen.dart](file:///d:/dev/notas-zincao-flutter/lib/screens/retirada_produtos_screen.dart#L216) e [retirada_form_service.dart](file:///d:/dev/notas-zincao-flutter/lib/services/retirada_form_service.dart#L50).

**Correção:** Usar cast seguro com fallback ou validação prévia.

---

### 🟡 P4 — Segurança: Falta de `try-catch` no listener de auth

**Arquivo:** [auth_viewmodel.dart](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/auth_viewmodel.dart#L38-L46)

```dart
_authService.authStateChanges.listen((event) async {
  // sem try-catch — se _loadProfile() lançar erro inesperado
  // o stream morre silenciosamente
});
```

**Correção:** Adicionar `try-catch` no listener e um [onError](file:///d:/dev/notas-zincao-flutter/lib/widgets/produtos_estoque/produto_dialog.dart#139-154) handler.

---

### 🟡 P5 — Estabilidade: [ProductStockHeaderViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/product_stock_header_viewmodel.dart#6-43) é Singleton mutável

**Arquivo:** [product_stock_header_viewmodel.dart](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/product_stock_header_viewmodel.dart)

O singleton `instance` nunca é disposado e usa `ChangeNotifier`. Se uma tela chamar `addListener` e não chamar `removeListener`, haverá **memory leak**. Além disso, como é singleton, o [dispose()](file:///d:/dev/notas-zincao-flutter/lib/screens/main_shell.dart#35-39) natural do Flutter não é chamado.

**Correção:** Documentar que listeners **devem** ser removidos manualmente, ou migrar para um `ValueNotifier` injetado via `InheritedWidget`.

---

### 🟡 P6 — Estabilidade: `HttpClient` usado sem timeout na chamada OpenAI 

**Arquivo:** [nota_form_service.dart](file:///d:/dev/notas-zincao-flutter/lib/services/nota_form_service.dart#L250-L287)

A requisição HTTP para a OpenAI não tem timeout. Se a API estiver lenta, o app travará indefinidamente mostrando o indicador de carregamento.

**Correção:** Adicionar timeout no `HttpClient` (ex: 60s).

---

### 🟡 P7 — Estabilidade: `assert` em produção é silencioso

**Arquivo:** [supabase_config.dart](file:///d:/dev/notas-zincao-flutter/lib/supabase_config.dart#L14-L15)

```dart
assert(url != null && url.isNotEmpty, 'SUPABASE_URL não encontrado');
```

Em builds release, `assert` **não executa**. Se o `.env` estiver ausente, o app continuará com `url == null` e crashará mais tarde de forma confusa.

**Correção:** Trocar `assert` por `throw` explícito.

---

### 🟡 P8 — Estabilidade: Falta tratamento de erro em `Image.network`

**Arquivo:** [nota_details_sheet.dart](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#L390-L395)

```dart
Image.network(nota.fotoUrl!, width: double.infinity, height: 200, fit: BoxFit.cover)
```

Se a URL da imagem estiver quebrada ou offline, aparecerá o erro padrão feio do Flutter. Múltiplas ocorrências no mesmo arquivo.

**Correção:** Adicionar `errorBuilder` para exibir fallback visual.

---

### 🟢 P9 — Arquitetura: [NotaFormViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/nota_form_viewmodel.dart#34-946) tem 946 linhas

**Arquivo:** [nota_form_viewmodel.dart](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/nota_form_viewmodel.dart) (30KB)

Este ViewModel faz tudo: gerencia formulário, controla foto, chama IA, valida duplicatas, lida com catálogo de produtos, faz parsing de dados da IA. Violação clara do princípio de responsabilidade única.

**Melhoria proposta (futura):** Quebrar em ViewModels menores:
- `NotaFormFieldsViewModel` — campos do formulário
- `NotaPhotoViewModel` — captura e upload de foto
- `NotaIaAnalysisViewModel` — análise de cupom via IA
- `NotaCatalogService` — busca de produtos do catálogo

---

### 🟢 P10 — Arquitetura: Funções top-level no [nota_details_sheet.dart](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart)

**Arquivo:** [nota_details_sheet.dart](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#L18-L55)

As funções [_sanitizePhone](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#17-21), [_openWhatsApp](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#22-40), [_makePhoneCall](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#41-56) e [_buildAdminMenu](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart#58-160) estão soltas como top-level. Seria melhor organizá-las em um helper ou encapsulá-las em um widget.

---

### 🟢 P11 — Melhoria: Sem cobertura de testes

O arquivo [test/widget_test.dart](file:///d:/dev/notas-zincao-flutter/test/widget_test.dart) contém apenas um placeholder. Nenhuma lógica de negócio é testada. Os ViewModels ([NotaFormViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/nota_form_viewmodel.dart#34-946), [RetiradaViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/retirada_form_viewmodel.dart#11-279), [AuthViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/auth_viewmodel.dart#14-195)) e Services são os candidatos principais para testes unitários.

---

## Proposed Changes

### 🔴 Correções Críticas (Sprint 1)

#### [MODIFY] [nota_details_sheet.dart](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart)
- Validar `idx` antes de acessar `nota.produtos[idx]` (P2)
- Adicionar `errorBuilder` em todos os `Image.network` (P8)

#### [MODIFY] [retirada_form_viewmodel.dart](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/retirada_form_viewmodel.dart)
- Cast seguro de `produtos[i]` com fallback (P3)

#### [MODIFY] [retirada_form_service.dart](file:///d:/dev/notas-zincao-flutter/lib/services/retirada_form_service.dart)
- Cast seguro de `novosProdutos[i]` com fallback (P3)

#### [MODIFY] [retirada_produtos_screen.dart](file:///d:/dev/notas-zincao-flutter/lib/screens/retirada_produtos_screen.dart)
- Cast seguro de `produtos[index]` com fallback (P3)

---

### 🟡 Correções Moderadas (Sprint 2)

#### [MODIFY] [auth_viewmodel.dart](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/auth_viewmodel.dart)
- Envolver listener de auth com `try-catch` (P4)

#### [MODIFY] [supabase_config.dart](file:///d:/dev/notas-zincao-flutter/lib/supabase_config.dart)
- Trocar `assert` por `throw` explícito para validar `.env` (P7)

#### [MODIFY] [nota_form_service.dart](file:///d:/dev/notas-zincao-flutter/lib/services/nota_form_service.dart)
- Adicionar timeout de 60s na requisição HTTP para a OpenAI (P6)

---

### 🟢 Melhorias Futuras (Backlog)

- P1 — Mover chamada OpenAI para Edge Function Supabase (requer decisão de arquitetura)
- P5 — Documentar ou refatorar o singleton [ProductStockHeaderViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/product_stock_header_viewmodel.dart#6-43)
- P9 — Quebrar [NotaFormViewModel](file:///d:/dev/notas-zincao-flutter/lib/viewmodels/nota_form_viewmodel.dart#34-946) em múltiplos ViewModels menores
- P10 — Organizar funções top-level do [nota_details_sheet.dart](file:///d:/dev/notas-zincao-flutter/lib/widgets/minhas_notas/nota_details_sheet.dart)
- P11 — Introduzir testes unitários nos ViewModels e Services

---

## Verification Plan

### Automated Tests

O projeto possui apenas um teste placeholder. Após as correções, o comando a seguir confirma que a análise estática está limpa:

```bash
flutter analyze --no-pub
```

### Manual Verification

> [!IMPORTANT]
> Preciso da sua orientação: deseja que eu crie testes unitários para os ViewModels/Services durante a execução, ou prefere focar apenas nas correções agora?

**Testes manuais recomendados após as correções:**

1. **P2/P3 — Crash por index/cast:** Abrir uma nota que tenha histórico de retiradas, verificar que a tela de detalhes abre sem crash
2. **P6 — Timeout:** Tirar uma foto e enviar para análise da IA. Verificar que, se a internet está lenta, o app não trava indefinidamente
3. **P7 — .env validation:** Remover temporariamente `SUPABASE_URL` do `.env` e confirmar que o app mostra erro claro em vez de crashar
4. **P8 — Image fallback:** Editar uma nota no banco para conter uma `foto_url` inválida e verificar que aparece um placeholder em vez de erro vermelho
