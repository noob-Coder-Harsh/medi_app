import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/brand.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/link_opener.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/whatsapp.dart';
import 'package:medi_app/data/local/locale_store.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/features/location/store_resolver.dart';
import 'package:medi_app/features/storefront/store_copy.dart';
import 'package:medi_app/features/storefront/store_home_controller.dart';

import 'nearby_fixtures.dart';

class RecordingLinks implements LinkOpener {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class FakeStoreHomeSource implements StoreHomeSource {
  FakeStoreHomeSource(this.bySlug);

  final Map<String, StoreHomePayload> bySlug;

  @override
  Future<StoreHomePayload> getStoreHome(String slug) async {
    return bySlug[slug] ?? StoreHomePayload.empty;
  }
}

class SeededNearbyShops extends NearbyShops {
  SeededNearbyShops(this.seed);

  final List<NearbyStore> seed;

  @override
  List<NearbyStore> build() => seed;
}

class SeededActiveShop extends ActiveShopController {
  SeededActiveShop(this.seed);

  final ActiveShop? seed;

  @override
  ActiveShop? build() => seed;
}

StoreHomePayload _home(NearbyStore shop) {
  return StoreHomePayload(
    status: StoreShellStatus.ok,
    store: shop.store,
    categories: const <Category>[],
    featured: const <ListingCard>[],
    products: const <ListingCard>[],
  );
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('wa.me uses country code for Indian mobiles', () {
    expect(whatsAppDigits('9876543210'), '919876543210');
    expect(whatsAppDigits('+91 98765 43210'), '919876543210');
    expect(
      whatsAppUri(number: '9876543210')?.toString(),
      'https://wa.me/919876543210',
    );
    expect(storeHoursLabel(nearbyShop(
      id: 'a',
      slug: 'alpha',
      name: 'Alpha',
      openingTime: '09:00:00',
      closingTime: '21:00:00',
    ).store), '09:00–21:00');
  });

  testWidgets('guest account copy, language, and legal links', (
    WidgetTester tester,
  ) async {
    final links = RecordingLinks();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkOpenerProvider.overrideWithValue(links),
        ],
        child: MediApp(router: createAppRouter(initialLocation: '/account')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Account'), findsOneWidget);
    expect(find.text(t('STOREFRONT.ACCOUNT_GUEST')), findsOneWidget);
    expect(find.byKey(const Key('account-sign-in')), findsOneWidget);
    expect(find.textContaining('OTP sent'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-terms')));
    await tester.pumpAndSettle();
    expect(
      links.opened.map((Uri uri) => uri.toString()).toList(),
      <String>[Brand.urls.privacyPolicy, Brand.urls.termsOfService],
    );

    await tester.tap(find.byKey(const Key('account-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('otp-stub-title')), findsOneWidget);
    expect(find.text(t('STOREFRONT.OTP_SEND')), findsOneWidget);
    await tester.tap(find.text(t('STOREFRONT.CLOSE_DRAWER')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-privacy')), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-hi')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'खाता'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocaleStore.prefsKey), 'hi');
  });

  testWidgets('shop info and Rx job open wa.me', (WidgetTester tester) async {
    final links = RecordingLinks();
    final shop = nearbyShop(
      id: 'a',
      slug: 'alpha',
      name: 'Alpha',
      phone: '01123456789',
      address: '12 Market Road',
      city: 'Delhi',
      whatsappNumber: '9876543210',
      openingTime: '09:00:00',
      closingTime: '21:00:00',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkOpenerProvider.overrideWithValue(links),
          storeHomeSourceProvider.overrideWithValue(
            FakeStoreHomeSource(<String, StoreHomePayload>{
              'alpha': _home(shop),
            }),
          ),
          nearbyShopsProvider.overrideWith(() => SeededNearbyShops(<NearbyStore>[shop])),
          activeShopProvider.overrideWith(
            () => SeededActiveShop(
              const ActiveShop(storeId: 'a', slug: 'alpha', name: 'Alpha'),
            ),
          ),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: '/shop/alpha/info'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, t('STOREFRONT.STORE_INFO')), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('12 Market Road, Delhi'), findsOneWidget);
    expect(find.text('09:00–21:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-info-whatsapp')));
    await tester.pumpAndSettle();
    expect(links.opened.single.toString(), 'https://wa.me/919876543210');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linkOpenerProvider.overrideWithValue(links),
          storeHomeSourceProvider.overrideWithValue(
            FakeStoreHomeSource(<String, StoreHomePayload>{
              'alpha': _home(shop),
            }),
          ),
          nearbyShopsProvider.overrideWith(() => SeededNearbyShops(<NearbyStore>[shop])),
          activeShopProvider.overrideWith(
            () => SeededActiveShop(
              const ActiveShop(storeId: 'a', slug: 'alpha', name: 'Alpha'),
            ),
          ),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: '/prescription'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, t('STOREFRONT.PRESCRIPTION_TITLE')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('rx-send-whatsapp')));
    await tester.pumpAndSettle();
    expect(links.opened.last.scheme, 'https');
    expect(links.opened.last.host, 'wa.me');
    expect(links.opened.last.path, '/919876543210');
    expect(links.opened.last.queryParameters['text'], isNotEmpty);
  });
}
