class Validators {
  static String? requiredText(String? value, {String label = 'هذا الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $label';
    }
    return null;
  }

  static String? phone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'يرجى إدخال رقم الهاتف';
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length < 7) return 'رقم الهاتف غير صالح';
    return null;
  }

  static String? positiveMoney(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'يرجى إدخال المبلغ';
    final amount = double.tryParse(raw.replaceAll(',', '.'));
    if (amount == null) return 'أدخل رقماً صالحاً';
    if (amount <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';
    return null;
  }

  static double parseMoney(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  static String? roomCode(String? value) {
    final code = normalizeRoomCode(value);
    if (code.length != 6) {
      return 'أدخل كود الغرفة المكوّن من 6 أحرف';
    }
    return null;
  }

  static String normalizeRoomCode(String? value) {
    return (value ?? '')
        .trim()
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .toUpperCase();
  }
}
