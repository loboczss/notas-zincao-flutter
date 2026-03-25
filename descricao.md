# Descrição do App

## Descrição breve

O **Notas Zincão** é um aplicativo Flutter para cadastro e controle de notas/cupons fiscais, com foco no acompanhamento de retirada de produtos. Ele permite capturar foto do cupom, usar IA para extrair dados automaticamente, salvar tudo no Supabase e acompanhar o status da retirada (pendente, parcial, retirada ou cancelada).

## Descrição completa

O **Notas Zincão** foi desenvolvido para digitalizar e organizar o processo de gestão de notas fiscais e retirada de mercadorias. O app reduz trabalho manual ao transformar fotos de cupons em dados estruturados e centraliza todo o ciclo da nota, desde o cadastro até a confirmação da retirada.

### Principais funcionalidades

- **Autenticação de usuários** com recuperação de senha.
- **Cadastro e edição de notas** com dados do cliente, número/série da nota, data da compra, produtos, valor total e observações.
- **Captura de imagem** por câmera ou seleção da galeria.
- **Upload de imagens** para o Supabase Storage.
- **Leitura inteligente de cupons com IA**: envia a foto para a API da OpenAI Vision e preenche automaticamente campos como cliente, número da nota, produtos e total.
- **Busca e listagem de notas** com controle por perfil de acesso.
- **Fluxo de retirada parcial e total**, com atualização de quantidades retiradas por item.
- **Histórico de retiradas** com registro de responsável, data e comprovantes fotográficos.
- **Controle de status** da nota: pendente, parcial, retirada e cancelada.
- **Política de atualização remota do app** (opcional ou obrigatória), com suporte a rollout e fallback de loja.

### Fluxo de uso

1. O usuário entra no app e abre o cadastro de nota.
2. Captura ou seleciona a foto do cupom fiscal.
3. A IA analisa a imagem e sugere/preenche os dados extraídos.
4. O usuário revisa os campos, ajusta se necessário e salva a nota.
5. A nota fica disponível para acompanhamento e retirada.
6. Durante a retirada, o app registra quantidades retiradas, comprovantes e histórico.
7. O status é atualizado automaticamente até concluir a retirada total.

### Tecnologias e arquitetura

- **Frontend:** Flutter (Dart), com organização em camadas (`screens`, `viewmodels`, `services`, `models`).
- **Backend/BaaS:** Supabase (banco de dados, autenticação e storage).
- **IA para OCR semântico de cupons:** OpenAI via endpoint de chat com entrada de imagem.
- **Bibliotecas de apoio:** `image_picker`, `flutter_dotenv`, `supabase_flutter`, `in_app_update`, `shared_preferences`, entre outras.

### Benefícios para operação

- Diminui erros de digitação e retrabalho no cadastro de notas.
- Acelera o processo de entrada de dados com preenchimento automático por IA.
- Melhora rastreabilidade das retiradas com histórico e evidências.
- Centraliza informações de clientes, produtos e status em um único sistema.
- Facilita manutenção do app com mecanismo de atualização controlada por política remota.
