/// Digits for `https://wa.me/{number}`. Indian 10-digit numbers get `91`.
String? whatsAppDigits(String? number) {
  final digits = (number ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.length == 10) return '91$digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '91${digits.substring(1)}';
  }
  return digits;
}

Uri? whatsAppUri({String? number, String? text}) {
  final digits = whatsAppDigits(number);
  if (digits == null) return null;
  final base = Uri.parse('https://wa.me/$digits');
  if (text == null || text.isEmpty) return base;
  return base.replace(queryParameters: <String, String>{'text': text});
}
