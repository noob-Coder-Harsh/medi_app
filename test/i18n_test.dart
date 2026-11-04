import 'package:flutter_test/flutter_test.dart';

import 'package:medi_app/core/i18n.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await I18n.load();
  });

  test("t('NAV.HOME') is Home in English", () {
    expect(t('NAV.HOME', locale: AppLocale.en), 'Home');
  });

  test("t('NAV.HOME') is होम in Hindi", () {
    expect(t('NAV.HOME', locale: AppLocale.hi), 'होम');
  });

  test('EN | हिं chrome strings exist', () {
    expect(t('LANGUAGE.EN', locale: AppLocale.en), 'EN');
    expect(t('LANGUAGE.HI', locale: AppLocale.en), 'हिं');
  });
}
