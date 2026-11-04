import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/data/local/shop_session_store.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/features/location/store_resolver.dart';

import 'nearby_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('picks nearest accepting shop and persists session', () async {
    final session = ShopSessionStore();
    List<NearbyStore> memory = const <NearbyStore>[];
    final resolver = StoreResolver(
      nearby: FakeNearbySource(<NearbyStore>[
        nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha', km: 0.4),
        nearbyShop(id: 'b', slug: 'beta', name: 'Beta', km: 1.1),
      ]),
      session: session,
      onNearby: (List<NearbyStore> shops) => memory = shops,
    );

    final resolved = await resolver.resolve(lat: 28.6, lng: 77.2);

    expect(resolved!.shop.store.slug, 'alpha');
    expect(memory.length, 2);
    expect(await session.readLastStoreId(), 'a');
    expect(await session.readLastSlug(), 'alpha');
    expect((await session.readNearby()).map((s) => s.store.slug), ['alpha', 'beta']);
  });

  test('keeps last shop when it is still in range', () async {
    final resolver = StoreResolver(
      nearby: FakeNearbySource(<NearbyStore>[
        nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha', km: 0.4),
        nearbyShop(id: 'b', slug: 'beta', name: 'Beta', km: 1.1),
      ]),
      session: ShopSessionStore(),
      onNearby: (_) {},
    );

    final resolved = await resolver.resolve(
      lat: 28.6,
      lng: 77.2,
      lastStoreId: 'b',
    );
    expect(resolved!.shop.store.slug, 'beta');
  });

  test('returns null when no accepting shops', () async {
    final resolver = StoreResolver(
      nearby: FakeNearbySource(<NearbyStore>[
        nearbyShop(
          id: 'x',
          slug: 'closed',
          name: 'Closed',
          accepts: false,
        ),
      ]),
      session: ShopSessionStore(),
      onNearby: (_) {},
    );

    expect(await resolver.resolve(lat: 28.6, lng: 77.2), isNull);
  });
}
