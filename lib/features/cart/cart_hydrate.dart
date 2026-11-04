import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/listing.dart';
import '../storefront/catalog_controller.dart';
import 'cart_controller.dart';

const Duration kCartCardsTtl = Duration(seconds: 15);

/// Query key: `['cart-cards', storeId, sortedIds]`.
List<Object> cartCardsQueryKey(String storeId, List<String> ids) {
  final sorted = List<String>.from(ids)..sort();
  return <Object>['cart-cards', storeId, sorted];
}

class _CartIds {
  const _CartIds({required this.storeId, required this.ids});

  final String storeId;
  final List<String> ids;

  @override
  bool operator ==(Object other) {
    if (other is! _CartIds ||
        other.storeId != storeId ||
        other.ids.length != ids.length) {
      return false;
    }
    for (var i = 0; i < ids.length; i++) {
      if (other.ids[i] != ids[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(storeId, Object.hashAll(ids));
}

class CachedCartCards {
  CachedCartCards({this.ttl = kCartCardsTtl});

  final Duration ttl;
  final Map<String, ({List<ListingCard> data, DateTime at})> _cache =
      <String, ({List<ListingCard> data, DateTime at})>{};

  String _key(String storeId, List<String> ids) {
    return cartCardsQueryKey(storeId, ids).join('|');
  }

  Future<List<ListingCard>> load({
    required String storeId,
    required List<String> ids,
    required Future<List<ListingCard>> Function() fetch,
  }) async {
    final key = _key(storeId, ids);
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < ttl) {
      return hit.data;
    }
    final data = await fetch();
    _cache[key] = (data: data, at: DateTime.now());
    return data;
  }

  void invalidate() => _cache.clear();
}

final cartCardsCacheProvider = Provider<CachedCartCards>(
  (Ref ref) => CachedCartCards(),
);

final cartLineIdsProvider = Provider<_CartIds?>((Ref ref) {
  final cart = ref.watch(cartProvider);
  final storeId = cart.storeId;
  if (storeId == null || cart.items.isEmpty) return null;
  final ids = cart.items.map((line) => line.storeProductId).toList()
    ..sort();
  return _CartIds(storeId: storeId, ids: ids);
});

/// Hydrate local cart ids with `get_listing_cards`. Qty changes do not refetch.
final cartCardsProvider = FutureProvider.autoDispose<List<ListingCard>>((
  ref,
) async {
  final lines = ref.watch(cartLineIdsProvider);
  if (lines == null) return const <ListingCard>[];
  final cache = ref.watch(cartCardsCacheProvider);
  final source = ref.watch(catalogSourceProvider);
  return cache.load(
    storeId: lines.storeId,
    ids: lines.ids,
    fetch: () => source.getListingCards(storeId: lines.storeId, ids: lines.ids),
  );
});
