# Instruções de Upload para Google Play Console

## 📦 App Bundle para Upload

Arquivo: `build/app/outputs/bundle/release/app-release.aab`
- Tamanho: ~120 MB
- Versão: Build otimizado com ofuscação e symbols separados
- Gerado em: 25/03/2026

## 🔧 Debug Symbols (Símbolos de Depuração)

Os símbolos de depuração foram extraídos para facilitar a análise de crashes:

```
debug_info/
├── app.android-arm.symbols      (2.8 MB)
├── app.android-arm64.symbols    (3.3 MB)
└── app.android-x64.symbols      (3.3 MB)
```

### Como fazer upload dos symbols:

1. **Acesse Google Play Console**
   - Vá para seu aplicativo → **Release** → **Production**
   - Clique na versão mais recente do AAB

2. **Navegue até "Symbols"**
   - Procure pela seção **Symbols** ou **Debug symbols**
   - Clique em **Upload symbols**

3. **Selecione os arquivos**
   - Faça upload de cada arquivo `.symbols` da pasta `debug_info/`
   - Ou coloque-os em um ZIP e faça upload em lote

4. **Confirmação**
   - Aguarde o processamento (geralmente alguns minutos)
   - Símbolos aparecem na aba "Symbols" quando processados

## 📊 Otimizações Aplicadas

✅ **Obfuscação de código** - Protege contra engenharia reversa
✅ **Separação de symbols** - Reduz tamanho do AAB em ~1.4%
✅ **Tree-shaking de ícones** - Reduz MaterialIcons de 1.6 MB a 12 KB

## 🚀 Próximos Passos

1. Upload do `app-release.aab` no console
2. Upload dos symbols (passos acima)
3. Configurar política de distribuição (por país, dispositivo, etc.)
4. Publicar na Play Store

## 📝 Notas

- O AAB será automaticamente decompilado em APKs específicos por arquitetura/densidade de tela
- Sem os symbols, o Play Console terá dificuldade em desembaraçar stack traces de crashes
- Os symbols são **fundamentais** para o Firebase Crashlytics funcionar corretamente
