import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/listing.dart';
import '../../data/rpc/listing_rpc.dart';
import '../../data/supabase_client.dart';

/// Query key for shop home: `['store', slug, 'home']`.
List<Object> storeHomeQueryKey(String slug) => <Object>['store', slug, 'home'];

const Duration kStoreHomeTtl = Duration(seconds: 60);

/// Listing RPC when Supabase is ready; empty payload otherwise (tests / no env).
class ListingStoreHomeSource implements StoreHomeSource {
  const ListingStoreHomeSource();

  @override
  Future<StoreHomePayload> getStoreHome(String slug) async {
    if (!AppSupabase.isReady) {
      return StoreHomePayload.empty;
    }
    return ListingRpc(AppSupabase.client).getStoreHome(slug);
  }
}

/// 15–60s freshness. Home may be slightly stale.
class CachedStoreHomeSource implements StoreHomeSource {
  CachedStoreHomeSource(
    this._inner, {
    this.ttl = kStoreHomeTtl,
  });

  final StoreHomeSource _inner;
  final Duration ttl;
  final Map<String, ({StoreHomePayload data, DateTime at})> _cache =
      <String, ({StoreHomePayload data, DateTime at})>{};

  String _cacheKey(String slug) => storeHomeQueryKey(slug).join('|');

  bool isStale(String slug, {DateTime? now}) {
    final hit = _cache[_cacheKey(slug)];
    if (hit == null) return true;
    return (now ?? DateTime.now()).difference(hit.at) >= ttl;
  }

  void invalidate(String slug) => _cache.remove(_cacheKey(slug));

  Future<StoreHomePayload> load(String slug, {bool force = false}) async {
    final key = _cacheKey(slug);
    final hit = _cache[key];
    if (!force &&
        hit != null &&
        DateTime.now().difference(hit.at) < ttl) {
      return hit.data;
    }
    final data = await _inner.getStoreHome(slug);
    _cache[key] = (data: data, at: DateTime.now());
    return data;
  }

  @override
  Future<StoreHomePayload> getStoreHome(String slug) => load(slug);
}

final storeHomeSourceProvider = Provider<StoreHomeSource>(
  (Ref ref) => CachedStoreHomeSource(const ListingStoreHomeSource()),
);

final storeHomeProvider =
    FutureProvider.family<StoreHomePayload, String>((ref, slug) {
      return ref.watch(storeHomeSourceProvider).getStoreHome(slug);
    });
