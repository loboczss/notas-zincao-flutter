import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Ícone adaptativo que funciona em Android (Material Icons) e iOS (CupertinoIcons)
class AdaptiveIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AdaptiveIcon(
    this.icon, {
    this.size,
    this.color,
    this.semanticLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino =
        Theme.of(context).platform == TargetPlatform.iOS;

    // Mapear ícone Material para Cupertino equivalente
    final adaptiveIconData = isCupertino
        ? _mapToCupertinoIcon(icon)
        : icon;

    return Icon(
      adaptiveIconData,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }

  /// Mapeia Material Icons para CupertinoIcons equivalentes usando codePoint
  static IconData _mapToCupertinoIcon(IconData materialIcon) {
    // Mapa usando código numérico do IconData (codePoint)
    final mapping = <int, IconData>{
      // Setas e navegação
      Icons.arrow_back.codePoint: CupertinoIcons.back,
      Icons.close.codePoint: CupertinoIcons.xmark,
      Icons.clear_rounded.codePoint: CupertinoIcons.xmark_circle,
      Icons.check.codePoint: CupertinoIcons.check_mark,
      Icons.check_circle.codePoint: CupertinoIcons.checkmark_circle_fill,

      // Controles de visibilidade
      Icons.visibility.codePoint: CupertinoIcons.eye,
      Icons.visibility_off.codePoint: CupertinoIcons.eye_slash,
      Icons.visibility_off_outlined.codePoint: CupertinoIcons.eye_slash,

      // Email e comunicação
      Icons.email.codePoint: CupertinoIcons.mail,
      Icons.email_outlined.codePoint: CupertinoIcons.mail,
      Icons.phone.codePoint: CupertinoIcons.phone,
      Icons.phone_rounded.codePoint: CupertinoIcons.phone,

      // Câmera e mídia
      Icons.camera_alt.codePoint: CupertinoIcons.camera,
      Icons.camera_alt_rounded.codePoint: CupertinoIcons.camera,
      Icons.photo_library.codePoint: CupertinoIcons.photo,
      Icons.photo_library_rounded.codePoint: CupertinoIcons.photo,
      Icons.add_a_photo.codePoint: CupertinoIcons.camera,
      Icons.image.codePoint: CupertinoIcons.photo,

      // Formulários e entrada
      Icons.person.codePoint: CupertinoIcons.person,
      Icons.person_outlined.codePoint: CupertinoIcons.person,
      Icons.person_outline_rounded.codePoint: CupertinoIcons.person,
      Icons.badge.codePoint: CupertinoIcons.creditcard,
      Icons.badge_outlined.codePoint: CupertinoIcons.creditcard,
      Icons.lock.codePoint: CupertinoIcons.lock,
      Icons.lock_outline.codePoint: CupertinoIcons.lock,
      Icons.lock_outline_rounded.codePoint: CupertinoIcons.lock,
      Icons.lock_reset_rounded.codePoint: CupertinoIcons.lock_slash,

      // Data e calendário
      Icons.calendar_today.codePoint: CupertinoIcons.calendar,
      Icons.calendar_today_rounded.codePoint: CupertinoIcons.calendar,
      Icons.event.codePoint: CupertinoIcons.calendar,
      Icons.event_rounded.codePoint: CupertinoIcons.calendar,

      // Finança
      Icons.payments.codePoint: CupertinoIcons.money_dollar,
      Icons.payments_rounded.codePoint: CupertinoIcons.money_dollar,
      Icons.attach_money.codePoint: CupertinoIcons.money_dollar,
      Icons.attach_money_rounded.codePoint: CupertinoIcons.money_dollar,

      // Busca e navegação
      Icons.search.codePoint: CupertinoIcons.search,
      Icons.search_rounded.codePoint: CupertinoIcons.search,
      Icons.refresh.codePoint: CupertinoIcons.refresh,
      Icons.more_vert.codePoint: CupertinoIcons.ellipsis_vertical,
      Icons.menu.codePoint: CupertinoIcons.bars,

      // Formulário/documento
      Icons.description.codePoint: CupertinoIcons.doc,
      Icons.description_outlined.codePoint: CupertinoIcons.doc,
      Icons.receipt.codePoint: CupertinoIcons.doc_text,
      Icons.receipt_long.codePoint: CupertinoIcons.doc_text,
      Icons.receipt_long_rounded.codePoint: CupertinoIcons.doc_text,
      Icons.notes.codePoint: CupertinoIcons.doc_text,
      Icons.notes_rounded.codePoint: CupertinoIcons.doc_text,
      Icons.vpn_key.codePoint: CupertinoIcons.lock,
      Icons.vpn_key_rounded.codePoint: CupertinoIcons.lock,

      // Inventário e produtos
      Icons.inventory_2.codePoint: CupertinoIcons.cube_box,
      Icons.inventory_2_outlined.codePoint: CupertinoIcons.cube_box,
      Icons.shopping_bag.codePoint: CupertinoIcons.bag,
      Icons.shopping_bag_outlined.codePoint: CupertinoIcons.bag,

      // Números e adição
      Icons.add.codePoint: CupertinoIcons.plus,
      Icons.add_rounded.codePoint: CupertinoIcons.plus,
      Icons.add_circle_outline.codePoint: CupertinoIcons.plus_circle,
      Icons.remove.codePoint: CupertinoIcons.minus,
      Icons.remove_circle_outline.codePoint: CupertinoIcons.minus_circle,
      Icons.add_box.codePoint: CupertinoIcons.plus_circle,
      Icons.add_box_outlined.codePoint: CupertinoIcons.plus_circle,

      // Ações
      Icons.edit.codePoint: CupertinoIcons.pencil,
      Icons.edit_rounded.codePoint: CupertinoIcons.pencil,
      Icons.delete.codePoint: CupertinoIcons.trash,
      Icons.delete_rounded.codePoint: CupertinoIcons.trash,
      Icons.copy.codePoint: CupertinoIcons.doc_on_doc,
      Icons.copy_rounded.codePoint: CupertinoIcons.doc_on_doc,

      // Modo e aparência
      Icons.light_mode.codePoint: CupertinoIcons.sun_max,
      Icons.light_mode_rounded.codePoint: CupertinoIcons.sun_max,
      Icons.dark_mode.codePoint: CupertinoIcons.moon,
      Icons.dark_mode_rounded.codePoint: CupertinoIcons.moon,

      // Status e feedback
      Icons.warning.codePoint: CupertinoIcons.exclamationmark_triangle,
      Icons.warning_amber_rounded.codePoint: CupertinoIcons.exclamationmark_triangle,
      Icons.error.codePoint: CupertinoIcons.xmark_circle_fill,
      Icons.info.codePoint: CupertinoIcons.info_circle,
      Icons.auto_awesome.codePoint: CupertinoIcons.sparkles,
      Icons.auto_awesome_outlined.codePoint: CupertinoIcons.sparkles,

      // Transporte e entrega
      Icons.local_shipping_outlined.codePoint: CupertinoIcons.cube_box,
      Icons.outbox.codePoint: CupertinoIcons.tray_arrow_up,

      // Histórico
      Icons.history.codePoint: CupertinoIcons.clock,
      Icons.history_rounded.codePoint: CupertinoIcons.clock,

      // Grids e visualização
      Icons.grid_view.codePoint: CupertinoIcons.square_grid_2x2,

      // Outros
      Icons.tag.codePoint: CupertinoIcons.tag,
    };

    // Se encontrar um mapeamento, usa o Cupertino, senão retorna o original
    return mapping[materialIcon.codePoint] ?? materialIcon;
  }
}

/// Extensão para usar ícone adaptativo de forma mais curta
extension AdaptiveIconExt on IconData {
  AdaptiveIcon adaptive({
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return AdaptiveIcon(
      this,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
