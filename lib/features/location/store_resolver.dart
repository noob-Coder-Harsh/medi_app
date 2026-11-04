import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/shop_session_store.dart';
import '../../data/models/listing.dart';
import '../../data/rpc/listing_rpc.dart';

class ResolvedStore {
  const ResolvedStore({required this.shop, required this.nearby});

  final NearbyStore shop;
  final List<NearbyStore> nearby;
}

class NearbyShops extends Notifier<List<NearbyStore>> {
  @override
  List<NearbyStore> build() => const <NearbyStore>[];

  void replace(List<NearbyStore> shops) => state = shops;
}

final nearbyShopsProvider =
    NotifierProvider<NearbyShops, List<NearbyStore>>(NearbyShops.new);

class ActiveShop {
  const ActiveShop({
    required this.storeId,
    required this.slug,
    this.name,
  });

  final String storeId;
  final String slug;
  final String? name;
}

class ActiveShopController extends Notifier<ActiveShop?> {
  @override
  ActiveShop? build() => null;

  void set(ActiveShop shop) => state = shop;
}

final activeShopProvider =
    NotifierProvider<ActiveShopController, ActiveShop?>(ActiveShopController.new);

final shopSessionStoreProvider = Provider<ShopSessionStore>(
  (Ref ref) => ShopSessionStore(),
);

/// Picks last shop if it is still in range, otherwise the nearest accepting shop.
class StoreResolver {
  StoreResolver({
    required NearbyStoreSource nearby,
    required ShopSessionStore session,
    required void Function(List<NearbyStore> shops) onNearby,
    void Function(NearbyStore shop)? onChosen,
  }) : _nearby = nearby,
       _session = session,
       _onNearby = onNearby,
       _onChosen = onChosen;

  final NearbyStoreSource _nearby;
  final ShopSessionStore _session;
  final void Function(List<NearbyStore> shops) _onNearby;
  final void Function(NearbyStore shop)? _onChosen;

  Future<ResolvedStore?> resolve({
    required double lat,
    required double lng,
    String? lastStoreId,
  }) async {
    final listed = await _nearby.listNearbyStores(lat: lat, lng: lng);
    final accepting = listed
        .where(
          (NearbyStore item) =>
              item.store.acceptsOnlineOrders && item.store.slug.isNotEmpty,
        )
        .toList();
    if (accepting.isEmpty) {
      _onNearby(const <NearbyStore>[]);
      return null;
    }

    var chosen = accepting.first;
    if (lastStoreId != null) {
      for (final item in accepting) {
        if (item.store.id == lastStoreId) {
          chosen = item;
          break;
        }
      }
    }

    await _session.save(
      storeId: chosen.store.id,
      slug: chosen.store.slug,
      nearby: accepting,
    );
    _onNearby(accepting);
    _onChosen?.call(chosen);
    return ResolvedStore(shop: chosen, nearby: accepting);
  }
}

final storeResolverProvider = Provider<StoreResolver>((Ref ref) {
  final memory = ref.read(nearbyShopsProvider.notifier);
  final active = ref.read(activeShopProvider.notifier);
  return StoreResolver(
    nearby: ref.watch(nearbyStoreSourceProvider),
    session: ref.watch(shopSessionStoreProvider),
    onNearby: memory.replace,
    onChosen: (NearbyStore shop) {
      active.set(
        ActiveShop(
          storeId: shop.store.id,
          slug: shop.store.slug,
          name: shop.store.name,
        ),
      );
    },
  );
});
