/// Converte qualquer valor para double.
/// Trata: num, string com R$, vírgula como separador decimal, null → fallback.
double parseDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  var clean = value.toString().replaceAll('R\$', '').replaceAll(' ', '').trim();
  if (clean.contains(',')) {
    clean = clean.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(clean) ?? fallback;
}
