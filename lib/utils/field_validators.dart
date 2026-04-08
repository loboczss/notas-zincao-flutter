String onlyDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

bool isValidCpf(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

  int calcDigit(String base, int factor) {
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      sum += int.parse(base[i]) * (factor - i);
    }
    final mod = sum % 11;
    return mod < 2 ? 0 : 11 - mod;
  }

  final d1 = calcDigit(digits.substring(0, 9), 10);
  final d2 = calcDigit(digits.substring(0, 10), 11);
  return digits.endsWith('$d1$d2');
}

bool isValidCnpj(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 14) return false;
  if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return false;

  int calcDigit(String base, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < base.length; i++) {
      sum += int.parse(base[i]) * weights[i];
    }
    final mod = sum % 11;
    return mod < 2 ? 0 : 11 - mod;
  }

  const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  final d1 = calcDigit(digits.substring(0, 12), w1);
  final d2 = calcDigit(digits.substring(0, 13), w2);
  return digits.endsWith('$d1$d2');
}

String? normalizeDocumento(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = onlyDigits(value);
  if (digits.length == 11 && isValidCpf(digits)) return digits;
  if (digits.length == 14 && isValidCnpj(digits)) return digits;
  return null;
}

String? normalizePhoneBr(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  var digits = onlyDigits(value);
  if (digits.startsWith('55') && digits.length >= 12) {
    digits = digits.substring(2);
  }
  if (digits.length == 10 || digits.length == 11) return digits;
  return null;
}

String? normalizeChaveNfe(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = onlyDigits(value);
  return digits.length == 44 ? digits : null;
}

String? normalizeIsoDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final text = value.trim();

  DateTime? parsed;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    parsed = DateTime.tryParse(text);
  } else {
    final m = RegExp(r'^(\d{1,2})\/(\d{1,2})\/(\d{2,4})$').firstMatch(text);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      var y = int.tryParse(m.group(3)!);
      if (d != null && mo != null && y != null) {
        if (y < 100) y += 2000;
        parsed = DateTime.tryParse(
          '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
        );
      }
    }
  }

  if (parsed == null) return null;
  final now = DateTime.now();
  if (parsed.year < 2000 || parsed.year > now.year + 1) return null;
  return parsed.toIso8601String().split('T').first;
}