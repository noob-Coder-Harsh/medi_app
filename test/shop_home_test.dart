import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/features/location/store_resolver.dart';
import 'package:medi_app/features/storefront/store_home_controller.dart';

import 'nearby_fixtures.dart';

ListingCard _card(Map<String, Object?> row) {
  return parseListingCard(row)!;
}

StoreHomePayload _home({
  List<Category>? categories,
  List<ListingCard>? featured,
  List<ListingCard>? products,
  bool open = true,
  bool pickup = false,
  bool delivery = true,
}) {
  return StoreHomePayload(
    status: StoreShellStatus.ok,
    store: nearbyShop(
      id: 'a',
      slug: 'alpha',
      name: 'Alpha',
    ).store.copyWithOpen(
      isOpen: open,
      pickup: pickup,
      delivery: delivery,
      hours: true,
    ),
    categories: categories ??
        const <Category>[
          Category(
            id: 'c1',
            name: 'Tablets',
            slug: 'tablets',
            iconUrl: null,
            sortOrder: 0,
            isSystem: true,
            isActive: true,
            createdAt: '',
          ),
        ],
    featured: featured ??
        <ListingCard>[
          _card(<String, Object?>{
            'id': 'sp-1',
            'name': 'Dolo 650',
            'generic_name': 'Paracetamol',
            'pack_label': 'Strip of 15',
            'selling_price': 34,
            'mrp': 40,
            'schedule': 'h',
            'available_quantity': 12,
          }),
        ],
    products: products ??
        <ListingCard>[
          _card(<String, Object?>{
            'id': 'sp-2',
            'name': 'Crocin',
            'generic_name': 'Paracetamol',
            'pack_label': 'Strip of 10',
            'selling_price': 20,
            'mrp': 25,
            'available_quantity': 4,
          }),
          _card(<String, Object?>{
            'id': 'sp-3',
            'name': 'Cetirizine',
            'available_quantity': 0,
            'selling_price': 12,
          }),
        ],
  );
}

class FakeStoreHomeSource implements StoreHomeSource {
  FakeStoreHomeSource(this.bySlug);

  final Map<String, StoreHomePayload> bySlug;
  int calls = 0;

  @override
  Future<StoreHomePayload> getStoreHome(String slug) async {
    calls++;
    return bySlug[slug] ?? StoreHomePayload.empty;
  }
}

class SeededNearbyShops extends NearbyShops {
  SeededNearbyShops(this.seed);

  final List<NearbyStore> seed;

  @override
  List<NearbyStore> build() => seed;
}

extension on PublicStore {
  PublicStore copyWithOpen({
    required bool isOpen,
    required bool pickup,
    required bool delivery,
    required bool hours,
  }) {
    return PublicStore(
      id: id,
      name: name,
      slug: slug,
      phone: phone,
      description: description,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      whatsappNumber: whatsappNumber,
      openingTime: hours ? '09:00:00' : openingTime,
      closingTime: hours ? '21:00:00' : closingTime,
      serviceRadiusKm: serviceRadiusKm,
      minimumOrderAmount: minimumOrderAmount,
      deliveryCharge: deliveryCharge,
      freeDeliveryAbove: freeDeliveryAbove,
      allowCod: allowCod,
      allowManualUpi: allowManualUpi,
      allowPrescriptionUpload: allowPrescriptionUpload,
      modulePickup: pickup,
      moduleDelivery: delivery,
      upiId: upiId,
      upiQrUrl: upiQrUrl,
      isOpen: isOpen,
      acceptsOnlineOrders: acceptsOnlineOrders,
      salePolicy: salePolicy,
    );
  }
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required StoreHomePayload home,
    List<NearbyStore> nearby = const <NearbyStore>[],
    String slug = 'alpha',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeHomeSourceProvider.overrideWithValue(
            FakeStoreHomeSource(<String, StoreHomePayload>{slug: home}),
          ),
          nearbyShopsProvider.overrideWith(() => SeededNearbyShops(nearby)),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: '/shop/$slug'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('store home query key and 60s cache', () async {
    expect(storeHomeQueryKey('alpha'), <Object>['store', 'alpha', 'home']);
    final inner = FakeStoreHomeSource(<String, StoreHomePayload>{
      'alpha': _home(),
    });
    final cached = CachedStoreHomeSource(
      inner,
      ttl: const Duration(seconds: 60),
    );
    await cached.getStoreHome('alpha');
    await cached.getStoreHome('alpha');
    expect(inner.calls, 1);
    expect(cached.isStale('alpha'), isFalse);
    cached.invalidate('alpha');
    expect(cached.isStale('alpha'), isTrue);
    await cached.getStoreHome('alpha');
    expect(inner.calls, 2);
  });

  testWidgets('home slice order for a guest', (WidgetTester tester) async {
    await pumpHome(
      tester,
      home: _home(),
      nearby: <NearbyStore>[
        nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha', km: 0.5),
      ],
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text(t('STOREFRONT.OPEN')), findsOneWidget);
    expect(find.text(t('STOREFRONT.FULFILLMENT_PICKUP_SHORT')), findsNothing);
    expect(find.text(t('STOREFRONT.FULFILLMENT_DELIVERY_SHORT')), findsOneWidget);
    expect(find.text(t('STOREFRONT.SEARCH_PLACEHOLDER')), findsOneWidget);
    expect(find.text(t('STOREFRONT.JOB_RX')), findsOneWidget);
    expect(find.text(t('STOREFRONT.JOB_WHATSAPP')), findsOneWidget);
    expect(find.text(t('STOREFRONT.JOB_REORDER')), findsNothing);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(find.text('Tablets'), findsOneWidget);
    expect(find.text(t('STOREFRONT.FEATURED')), findsOneWidget);
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.text(t('STOREFRONT.ALL_PRODUCTS')), findsOneWidget);
    expect(find.text('Crocin'), findsOneWidget);
    expect(
      find.textContaining(t('STOREFRONT.TRUST_LICENSED')),
      findsOneWidget,
    );
    expect(find.text(t('STOREFRONT.TODAYS_DEAL')), findsNothing);
    expect(find.text(t('STOREFRONT.OUT_OF_STOCK')), findsNothing);
    expect(find.text('Cetirizine'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.textContaining('47'), findsNothing);
    expect(find.byKey(const Key('shop-switcher')), findsNothing);

    final headerY = tester.getTopLeft(find.byKey(const Key('shop-header'))).dy;
    final searchY = tester.getTopLeft(find.byKey(const Key('home-search'))).dy;
    final jobsY = tester.getTopLeft(find.byKey(const Key('home-jobs'))).dy;
    final catsY = tester.getTopLeft(find.byKey(const Key('home-categories'))).dy;
    final featY = tester.getTopLeft(find.byKey(const Key('home-featured'))).dy;
    final trustY = tester.getTopLeft(find.byKey(const Key('home-trust'))).dy;
    expect(headerY, lessThan(searchY));
    expect(searchY, lessThan(jobsY));
    expect(jobsY, lessThan(catsY));
    expect(catsY, lessThan(featY));
    expect(featY, lessThan(trustY));
  });

  testWidgets('featured rail omitted when empty', (WidgetTester tester) async {
    await pumpHome(
      tester,
      home: _home(featured: const <ListingCard>[]),
    );

    expect(find.text(t('STOREFRONT.FEATURED')), findsNothing);
    expect(find.text(t('STOREFRONT.TODAYS_DEAL')), findsNothing);
    expect(find.text('Crocin'), findsOneWidget);
  });

  testWidgets('quiet shop switcher when more than one nearby', (
    WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      home: _home(),
      nearby: <NearbyStore>[
        nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha', km: 0.5),
        nearbyShop(id: 'b', slug: 'beta', name: 'Beta', km: 1.8),
      ],
    );

    expect(find.byKey(const Key('shop-switcher')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-switcher')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Beta'), findsWidgets);

    await tester.tap(find.textContaining('Beta').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lastStoreSlug'), 'beta');
    expect(prefs.getString('lastStoreId'), 'b');
  });

  testWidgets('search bar opens search tab', (WidgetTester tester) async {
    await pumpHome(tester, home: _home());

    await tester.tap(find.byKey(const Key('home-search')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Search'), findsOneWidget);
  });
}
