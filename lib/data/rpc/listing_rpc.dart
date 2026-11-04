import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import '../supabase_client.dart';

abstract class NearbyStoreSource {
  Future<List<NearbyStore>> listNearbyStores({
    required double lat,
    required double lng,
    int limit = 20,
  });
}

abstract class StoreHomeSource {
  Future<StoreHomePayload> getStoreHome(String slug);
}

abstract class CatalogSource {
  Future<StoreShellPayload> getStoreShell({String? slug, String? storeId});

  Future<List<ListingCard>> searchStoreCatalog({
    required String storeId,
    String query = '',
    String? categoryId,
    int limit = 20,
  });

  Future<ListingCard?> getStoreProduct({
    required String storeId,
    required String slug,
  });

  Future<List<ListingCard>> getListingCards({
    required String storeId,
    required List<String> ids,
  });
}

/// Public listing RPCs — same names and args as the web client.
class ListingRpc implements NearbyStoreSource, StoreHomeSource, CatalogSource {
  ListingRpc(this._client);

  final SupabaseClient _client;

  Future<Object?> listNearbyStoresRaw({
    required double lat,
    required double lng,
    int limit = 20,
  }) async {
    return await _client.rpc(
      'list_nearby_stores',
      params: <String, dynamic>{
        'p_lat': lat,
        'p_lng': lng,
        'p_limit': limit,
      },
    );
  }

  @override
  Future<List<NearbyStore>> listNearbyStores({
    required double lat,
    required double lng,
    int limit = 20,
  }) async {
    final raw = await listNearbyStoresRaw(lat: lat, lng: lng, limit: limit);
    return parseNearbyStores(raw);
  }

  @override
  Future<StoreShellPayload> getStoreShell({String? slug, String? storeId}) async {
    final raw = await _client.rpc(
      'get_store_shell',
      params: <String, dynamic>{
        'p_slug': slug,
        'p_store_id': storeId,
      },
    );
    return parseStoreShell(raw);
  }

  @override
  Future<StoreHomePayload> getStoreHome(String slug) async {
    final raw = await _client.rpc(
      'get_store_home',
      params: <String, dynamic>{'p_slug': slug},
    );
    return parseStoreHome(raw);
  }

  @override
  Future<List<ListingCard>> searchStoreCatalog({
    required String storeId,
    String query = '',
    String? categoryId,
    int limit = 20,
  }) async {
    final raw = await _client.rpc(
      'search_store_catalog',
      params: <String, dynamic>{
        'p_store_id': storeId,
        'p_query': query,
        'p_category_id': categoryId,
        'p_limit': limit,
      },
    );
    return parseListingCards(raw);
  }

  @override
  Future<ListingCard?> getStoreProduct({
    required String storeId,
    required String slug,
  }) async {
    final raw = await _client.rpc(
      'get_store_product',
      params: <String, dynamic>{
        'p_store_id': storeId,
        'p_slug': slug,
      },
    );
    return parseListingCard(raw);
  }

  @override
  Future<List<ListingCard>> getListingCards({
    required String storeId,
    required List<String> ids,
  }) async {
    final raw = await _client.rpc(
      'get_listing_cards',
      params: <String, dynamic>{
        'p_store_id': storeId,
        'p_ids': ids,
      },
    );
    return parseListingCards(raw);
  }

  Future<List<Category>> listSystemCategories() async {
    final raw = await _client.rpc('list_system_categories');
    return parseCategories(raw);
  }
}

final listingRpcProvider = Provider<ListingRpc>(
  (Ref ref) => ListingRpc(AppSupabase.client),
);

final nearbyStoreSourceProvider = Provider<NearbyStoreSource>(
  (Ref ref) => ref.watch(listingRpcProvider),
);
