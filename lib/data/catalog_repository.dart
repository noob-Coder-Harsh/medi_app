import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/catalog_product.dart';
import 'models/listing.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for master catalogue + store links (DATA_PLANE).
class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  Future<Set<String>> storeMasterProductIds(String storeId) async {
    final raw = await _client
        .from('store_products')
        .select('product_id')
        .eq('store_id', storeId);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final ids = <String>{};
    for (final row in rows) {
      final record = asRecord(row);
      final id = asNullableString(record?['product_id']);
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  Future<List<CatalogProduct>> browseAvailable({
    required String storeId,
    int limit = 80,
  }) async {
    final inStore = await storeMasterProductIds(storeId);
    final fetchLimit = (limit + inStore.length).clamp(1, 2000);
    final raw = await _client
        .from('master_products')
        .select('*, categories(name)')
        .eq('is_system', true)
        .eq('is_active', true)
        .order('name', ascending: true)
        .limit(fetchLimit);

    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final out = <CatalogProduct>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final id = asString(record['id']);
      if (id.isEmpty || inStore.contains(id)) continue;
      out.add(CatalogProduct.fromRow(record, isInStore: false));
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<CatalogProduct>> searchCatalog({
    required String storeId,
    required String query,
    int limit = 30,
  }) async {
    final term = query.trim();
    if (term.isEmpty) return browseAvailable(storeId: storeId, limit: limit);

    final inStore = await storeMasterProductIds(storeId);
    final raw = await _client
        .from('master_products')
        .select('*, categories(name)')
        .eq('is_system', true)
        .eq('is_active', true)
        .or(
          'name.ilike.%$term%,generic_name.ilike.%$term%,manufacturer.ilike.%$term%',
        )
        .order('name', ascending: true)
        .limit(limit);

    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final out = <CatalogProduct>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final id = asString(record['id']);
      if (id.isEmpty) continue;
      out.add(CatalogProduct.fromRow(record, isInStore: inStore.contains(id)));
    }
    return out;
  }

  Future<List<StoreCatalogProduct>> listStoreProducts({
    required String storeId,
    String? query,
    int limit = 80,
  }) async {
    final raw = await _client
        .from('store_products')
        .select(
          'id, product_id, is_active, master_products(*, categories(name))',
        )
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(limit);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <StoreCatalogProduct>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = StoreCatalogProduct.fromJoin(record);
      if (item.name.isEmpty) continue;
      if (term.isNotEmpty) {
        final hay = [
          item.name,
          item.genericName ?? '',
          item.manufacturer ?? '',
          item.categoryName ?? '',
        ].join(' ').toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return CatalogRepository(AppSupabase.client);
});
