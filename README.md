# Notas Zincão (Flutter)

## Modelo de atualização automática implementado

O app agora possui fluxo completo de atualização com política remota:

- Atualização **obrigatória** (bloqueia o app) quando versão instalada é menor que `minSupportedVersion`.
- Atualização **opcional** (dialog) quando versão instalada é menor que `latestVersion`.
- Android tenta `in_app_update`; fallback para link da loja.
- iOS abre App Store via URL configurada na política.
- Cache local da última política para tolerar indisponibilidade temporária do endpoint.

## Arquivos principais

- `lib/models/app_update_policy.dart`
- `lib/services/app_update_service.dart`
- `lib/viewmodels/app_update_viewmodel.dart`
- `lib/router/app_router.dart`

## Configuração obrigatória (.env)

Adicione no `assets/.env`:

```env
UPDATE_CONFIG_URL=https://seu-dominio.com/update-policy.json
```

> O app já lê `.env` no startup, então basta incluir a variável acima.

## Formato do endpoint de política de atualização

Publique um JSON HTTP público (ou autenticado, se preferir) com este formato:

```json
{
	"latestVersion": "1.0.3",
	"minSupportedVersion": "1.0.1",
	"forceUpdate": false,
	"storeUrlAndroid": "https://play.google.com/store/apps/details?id=com.seuapp.notas",
	"storeUrlIos": "https://apps.apple.com/app/id1234567890",
	"rolloutPercent": 100,
	"message": "Nova versão disponível com melhorias e correções importantes."
}
```

Exemplo pronto no repositório: `public/update-policy.example.json`.

## Como operar releases via Git

Fluxo recomendado:

1. Atualize a versão no `pubspec.yaml` (`x.y.z+build`).
2. Faça merge em `main`.
3. Crie e envie tag: `vX.Y.Z`.
4. O workflow `.github/workflows/release-android.yml` gera `.aab` assinado e cria release.
5. Publique no Play Console/TestFlight.
6. Atualize o JSON de política (`latestVersion`, `minSupportedVersion`, `forceUpdate`).

### Segredos necessários no GitHub

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Estratégia sugerida de rollout

- Inicie com `rolloutPercent: 10`.
- Acompanhe erros/crash.
- Suba para `30`, `60`, `100`.
- Use `forceUpdate: true` apenas em cenários críticos.

## Observações importantes

- Git não atualiza app diretamente no dispositivo; ele aciona pipeline de build/release.
- iOS não permite atualização silenciosa fora dos fluxos oficiais da Apple.
- Se `UPDATE_CONFIG_URL` não estiver configurada, o app continua funcionando sem forçar update.
