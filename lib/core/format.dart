import 'package:intl/intl.dart';

import 'i18n.dart';

/// Indian date (`DD/MM/YYYY`) and rupee formatting.
/// Locale changes labels, not grouping or digits.
abstract final class Format {
  static String date(DateTime value, {AppLocale locale = AppLocale.en}) {
    // Pattern is numeric; locale is accepted so callers can pass en_IN / hi_IN
    // without changing the DD/MM/YYYY shape.
    final name = locale.intlName;
    try {
      return DateFormat('dd/MM/yyyy', name).format(value);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(value);
    }
  }

  /// Compact list timestamp, e.g. `08 Nov 2026, 02:14 PM`.
  static String dateTime(DateTime value, {AppLocale locale = AppLocale.en}) {
    final name = locale.intlName;
    try {
      return DateFormat('dd MMM yyyy, hh:mm a', name).format(value);
    } catch (_) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value);
    }
  }

  static String rupee(num amount, {int? decimalDigits}) {
    final digits = decimalDigits ?? (amount % 1 == 0 ? 0 : 2);
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: digits,
    ).format(amount);
  }

  /// Always a number. Stock shows `0`, never "Out of Stock".
  static String stock(num quantity) {
    return NumberFormat.decimalPattern('en_IN').format(quantity);
  }
}
