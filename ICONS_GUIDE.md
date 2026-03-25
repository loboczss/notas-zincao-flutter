# Usando Ícones Adaptativos (Android + iOS)

Este guia explica como usar ícones que funcionam perfeitamente em **Android** e **iOS**.

## ⚡ Uso Rápido

### Opção 1: Usando `Icon()` com mapeamento automático (Recomendado)

```dart
// Import
import 'package:notas_zincao_flutter/theme/adaptive_icons.dart';

// Uso simples - funciona em ambas as plataformas
Icon(Icons.camera_alt)
Icon(Icons.person_outlined)
Icon(Icons.check_circle)

// Com propriedades
Icon(
  Icons.arrow_back,
  size: 20,
  color: Colors.blue,
)
```

O componente `AdaptiveIcon` detecta automaticamente se está no iOS ou Android e ajusta o ícone.

### Opção 2: Usando a extensão (Sintaxe alternativa)

```dart
import 'package:notas_zincao_flutter/theme/adaptive_icons.dart';

// Usando a extensão .adaptive
Icons.camera_alt.adaptive(
  size: 24,
  color: Colors.blue,
)
```

## 📋 Mapeamento de Ícones Suportados

| Material Icon | iOS (Cupertino) |
|---|---|
| `Icons.camera_alt` | camera |
| `Icons.person` | person |
| `Icons.email` | mail |
| `Icons.check_circle` | checkmark_circled |
| `Icons.arrow_back` | back |
| `Icons.close` | xmark |
| `Icons.search` | search |
| `Icons.add` | plus |
| `Icons.edit` | pencil |
| `Icons.delete` | trash |
| E mais 80+ ícones... | ✓ Todos mapeados! |

## 🔧 Migrando Código Existente

### Antes (Som funciona em Android)
```dart
Icon(Icons.camera_alt, size: 24)  // ✓ Android | ✗ iOS pode não aparecer bem
```

### Depois (Funciona em ambos)
```dart
Icon(Icons.camera_alt, size: 24)  // ✓ Android | ✓ iOS auto-ajustado
```

**Bom news**: Você NÃO precisa alterar nada! Os ícones já são automaticamente mapeados quando você usar `Icon()` normalmente.

## 🎯 Se Criar Novo Widget com Ícones

```dart
import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/theme/adaptive_icons.dart';

// Widget que usa ícone
Widget meuWidget() {
  return Icon(Icons.camera_alt); // Adaptativo automaticamente!
}
```

## ✨ Casos de Uso

### Botão com ícone
```dart
ElevatedButton.icon(
  icon: Icon(Icons.add), // Adaptativo!
  label: Text('Adicionar'),
  onPressed: () {},
)
```

### IconButton
```dart
IconButton(
  icon: Icon(Icons.delete), // Adaptativo!
  onPressed: () {},
)
```

### ListTile
```dart
ListTile(
  leading: Icon(Icons.person), // Adaptativo!
  title: Text('Usuário'),
)
```

## 🔍 Testando

1. **No Android**: Abra o app normalmente
2. **No iOS**: Abra o app ou execute `flutter run -d`

Os ícones devem aparecer consistentemente em ambas as plataformas, mas com o estilo nativo de cada sistema operacional.

## ❓ Ícone Não Está no Mapeamento?

Se encontrar um ícone Material que não tem equivalente Cupertino mapeado:

1. Abra `/lib/theme/adaptive_icons.dart`
2. Localize o `_mapToCupertinoIcon()` método
3. Adicione o mapeamento na seção apropriada do dicionário `mapping`

Exemplo:
```dart
const mapping = {
  Icons.seu_icone_novo: CupertinoIcons.seu_equivalente,
  // ... resto do mapeamento
};
```

## 🚀 Performance

- ✅ Sem custo de performance - usa o Ice nativo do sistema
- ✅ Automático - não requer código adicional
- ✅ Compatível - funciona com todos os widgets do Flutter

## 📱 Suporte

Este sistema suporta:
- ✅ Android (Material Design)
- ✅ iOS (Cupertino)
- ✅ Web (fallback para Material Icons)
- ✅ macOS (suporte via CupertinoIcons)

---

**Resumo**: Use `Icon(Icons.*)` normalmente em seu código. O sistema automaticamente ajusta para o ícone correto no iOS! 🎉
