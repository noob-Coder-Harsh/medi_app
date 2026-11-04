import 'package:flutter_test/flutter_test.dart';

import 'package:medi_app/core/format.dart';
import 'package:medi_app/core/i18n.dart';

void main() {
  test('dates are DD/MM/YYYY', () {
    final formatted = Format.date(DateTime(2026, 10, 31), locale: AppLocale.en);
    expect(formatted, '31/10/2026');
  });

  test('rupees use Indian grouping', () {
    expect(Format.rupee(100000), contains('1,00,000'));
    expect(Format.rupee(100000), startsWith('₹'));
  });

  test('stock shows 0, never Out of Stock', () {
    expect(Format.stock(0), '0');
    expect(Format.stock(0), isNot(contains('Out of Stock')));
  });
}
