import 'package:flutter/material.dart';

/// Modelo de dados de uma nota.
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Color color;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.color,
  });

  /// Cria uma [Note] a partir de um Map retornado pelo Supabase.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.parse(map['created_at'] as String),
      color: _colorFromARGB(map['color'] as int? ?? 0xFF6366F1),
    );
  }

  /// Converte a [Note] para um Map compatível com o Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      // Compõe o int ARGB sem usar .value (depreciado)
      'color': _colorToARGB(color),
    };
  }

  /// Reconstrói uma [Color] a partir de um inteiro ARGB.
  static Color _colorFromARGB(int argb) {
    return Color.fromARGB(
      (argb >> 24) & 0xFF,
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
    );
  }

  /// Converte [Color] para inteiro ARGB usando os accessors modernos .a .r .g .b
  /// Evita o `.value` depreciado.
  static int _colorToARGB(Color color) {
    final a = (color.a * 255).round();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    Color? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      color: color ?? this.color,
    );
  }
}
