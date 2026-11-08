import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/local/location_store.dart';
import 'package:medi_app/data/local/shop_session_store.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/features/location/location_screen.dart';
import 'package:medi_app/features/location/location_service.dart';

import 'nearby_fixtures.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService(this.fix, {this.alreadyGranted = false});

  LocationFix fix;
  bool alreadyGranted;

  @override
  Future<LocationFix> requestAndRead() async => fix;

  @override
  Future<LocationFix?> readIfAlreadyGranted() async {
    if (!alreadyGranted) return null;
    if (fix.status != LocationFixStatus.granted) return null;
    return fix;
  }

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpLocation(
    WidgetTester tester, {
    required LocationService service,
    List<NearbyStore> nearby = const <NearbyStore>[],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(service),
          nearbyStoreSourceProvider.overrideWithValue(
            FakeNearbySource(nearby),
          ),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.location),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('grant opens nearest shop and stores session', (
    WidgetTester tester,
  ) async {
    await pumpLocation(
      tester,
      service: _FakeLocationService(
        const LocationFix(
          status: LocationFixStatus.granted,
          point: SavedLocation(lat: 28.61, lng: 77.21),
        ),
      ),
      nearby: <NearbyStore>[
        nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha', km: 0.5),
        nearbyShop(id: 'b', slug: 'beta', name: 'Beta', km: 2),
      ],
    );

    await tester.tap(find.byKey(const Key('location-allow')));
    await tester.pumpAndSettle();

    expect(find.byType(LocationScreen), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.textContaining('Sign in'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(LocationStore.latKey), 28.61);
    expect(prefs.getString(ShopSessionStore.storeIdKey), 'a');
    expect(prefs.getString(ShopSessionStore.slugKey), 'alpha');
    expect(prefs.getString(ShopSessionStore.nearbyKey), contains('beta'));
  });

  testWidgets('zero nearby shops shows empty state', (WidgetTester tester) async {
    await pumpLocation(
      tester,
      service: _FakeLocationService(
        const LocationFix(
          status: LocationFixStatus.granted,
          point: SavedLocation(lat: 28.61, lng: 77.21),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('location-allow')));
    await tester.pumpAndSettle();

    expect(find.byType(LocationScreen), findsOneWidget);
    expect(
      find.text(t('STOREFRONT.MARKETPLACE_NEARBY_EMPTY_TITLE')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('location-allow')), findsOneWidget);
  });

  testWidgets('deny shows retry copy and does not crash', (
    WidgetTester tester,
  ) async {
    await pumpLocation(
      tester,
      service: _FakeLocationService(
        const LocationFix(status: LocationFixStatus.denied),
      ),
    );

    await tester.tap(find.byKey(const Key('location-allow')));
    await tester.pumpAndSettle();

    expect(find.text(t('STOREFRONT.LOCATION_SHEET_DENIED')), findsOneWidget);
    expect(find.byType(LocationScreen), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(LocationStore.latKey), isNull);
  });

  testWidgets('cold start with saved location keeps last shop in range', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocationStore.latKey: 28.61,
      LocationStore.lngKey: 77.21,
      ShopSessionStore.storeIdKey: 'b',
    });

    await pumpLocation(
      tester,
      service: _FakeLocationService(
        const LocationFix(
          status: LocationFixStatus.granted,
          point: SavedLocation(lat: 28.61, lng: 77.21),
        ),
        alreadyGranted: true,
      ),
      nearby: <NearbyStore>[
        nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha', km: 0.5),
        nearbyShop(id: 'b', slug: 'beta', name: 'Beta', km: 1.8),
      ],
    );

    expect(find.byType(LocationScreen), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('logo long-press 600ms opens staff login', (
    WidgetTester tester,
  ) async {
    await pumpLocation(
      tester,
      service: _FakeLocationService(
        const LocationFix(status: LocationFixStatus.denied),
      ),
    );

    final Offset logo = tester.getCenter(find.byKey(const Key('location-logo')));
    final TestGesture gesture = await tester.startGesture(logo);
    await tester.pump(kStaffLogoLongPress);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_LOGIN_TITLE')), findsOneWidget);
    expect(find.byType(LocationScreen), findsNothing);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('short press on logo does not open staff', (
    WidgetTester tester,
  ) async {
    await pumpLocation(
      tester,
      service: _FakeLocationService(
        const LocationFix(status: LocationFixStatus.denied),
      ),
    );

    await tester.tap(find.byKey(const Key('location-logo')));
    await tester.pumpAndSettle();

    expect(find.byType(LocationScreen), findsOneWidget);
    expect(find.text(t('STORE_LOGIN_TITLE')), findsNothing);
  });
}
