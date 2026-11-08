import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/brand.dart';
import 'package:medi_app/core/deep_links.dart';
import 'package:medi_app/core/format.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/core/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final host = kDeepLinkHost;

  test('https API host/{slug} maps to /shop/{slug}', () {
    expect(
      mapDeepLinkToLocation(Uri.parse('https://$host/city-pharmacy')),
      Routes.shop('city-pharmacy'),
    );
  });

  test('https category and product paths map', () {
    expect(
      mapDeepLinkToLocation(
        Uri.parse('https://$host/city/category/fever'),
      ),
      Routes.category('city', 'fever'),
    );
    expect(
      mapDeepLinkToLocation(
        Uri.parse('https://$host/city/product/dolo-650'),
      ),
      Routes.product('city', 'dolo-650'),
    );
  });

  test('custom medisync scheme maps', () {
    expect(
      mapDeepLinkToLocation(Uri.parse('medisync://shop/city-pharmacy')),
      Routes.shop('city-pharmacy'),
    );
    expect(
      mapDeepLinkToLocation(Uri.parse('medisync:///shop/city-pharmacy')),
      Routes.shop('city-pharmacy'),
    );
  });

  test('reserved marketing paths are ignored', () {
    expect(
      mapDeepLinkToLocation(Uri.parse('https://$host/for-pharmacies')),
      isNull,
    );
    expect(
      mapDeepLinkToLocation(Uri.parse('https://$host/privacy-policy')),
      isNull,
    );
    expect(
      mapDeepLinkToLocation(Uri.parse('https://example.com/city')),
      isNull,
    );
  });

  test('Brand public pages use API origin', () {
    expect(Brand.urls.privacyPolicy, contains(host));
    expect(Brand.urls.privacyPolicy, endsWith('/privacy-policy'));
    expect(Brand.urls.termsOfService, endsWith('/terms-and-conditions'));
    expect(Brand.urls.contact, endsWith('/contact'));
  });

  test('stock zero is numeric 0', () {
    expect(Format.stock(0), '0');
  });

  test('charge and touch targets match APP_SHAPE', () {
    expect(AppTheme.touchTarget, 48);
    expect(AppTheme.chargeHeight, 56);
    expect(AppTheme.emptyListMinHeight, greaterThanOrEqualTo(200));
  });

  test('hi STORE_FORM covers en keys', () async {
    await I18n.load();
    final sample = I18n.t(
      'STORE_FORM.MODULE_DELIVERY',
      locale: AppLocale.hi,
    );
    expect(sample, isNot(equals('STORE_FORM.MODULE_DELIVERY')));
    expect(sample, isNot(equals('Deliver orders with your own rider')));
  });
}
