const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';
const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

String normalizeDigits(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    final persianIndex = _persianDigits.indexOf(character);
    final arabicIndex = _arabicDigits.indexOf(character);
    if (persianIndex >= 0) {
      buffer.write(persianIndex);
    } else if (arabicIndex >= 0) {
      buffer.write(arabicIndex);
    } else {
      buffer.write(character);
    }
  }
  return buffer.toString();
}

String normalizeIranMobile(String value) {
  var normalized = normalizeDigits(value).replaceAll(RegExp(r'[\s\-()]'), '');
  if (normalized.startsWith('+98')) {
    normalized = '0${normalized.substring(3)}';
  } else if (normalized.startsWith('0098')) {
    normalized = '0${normalized.substring(4)}';
  }
  return normalized;
}

String? validateIranMobile(String? value) {
  final normalized = normalizeIranMobile(value ?? '');
  if (normalized.isEmpty) return 'شماره موبایل الزامی است';
  if (!RegExp(r'^09\d{9}$').hasMatch(normalized)) {
    return 'شماره باید با ۰۹ شروع شود و ۱۱ رقم باشد';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'رمز عبور الزامی است';
  if (value.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
  return null;
}

String? validateFullName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'نام کامل الزامی است';
  if (name.length < 2) return 'نام کامل باید حداقل ۲ کاراکتر باشد';
  return null;
}

String? validateServerUrl(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return 'آدرس سرور صحیح نیست';
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return 'آدرس سرور باید با http یا https شروع شود';
  }
  return null;
}
