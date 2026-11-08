import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/listing.dart';
import 'models/staff_store.dart';
import 'rpc/listing_rpc.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for My Store + categories (DATA_PLANE).
class StoreSettingsRepository {
  StoreSettingsRepository(this._client, {ListingRpc? listing})
    : _listing = listing;

  final SupabaseClient _client;
  final ListingRpc? _listing;

  ListingRpc get _listingRpc => _listing ?? ListingRpc(_client);

  Future<StaffStore?> getStore({required String storeId}) async {
    final raw = await _client
        .from('stores')
        .select()
        .eq('id', storeId)
        .maybeSingle();
    final row = asRecord(raw);
    if (row == null) return null;
    return StaffStore.fromJson(row);
  }

  Future<List<StaffCategory>> listStoreCategories({
    required String storeId,
  }) async {
    final raw = await _client
        .from('store_categories')
        .select('category_id, categories(*)')
        .eq('store_id', storeId);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final out = <StaffCategory>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final category = asRecord(record['categories']);
      if (category == null) continue;
      final parsed = parseCategory(category);
      if (parsed == null || parsed.id.isEmpty) continue;
      out.add(StaffCategory.fromCategory(parsed, attached: true));
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  Future<List<StaffCategory>> listAvailableCategories({
    required String storeId,
    String? query,
  }) async {
    final system = await _listingRpc.listSystemCategories();
    final attached = await listStoreCategories(storeId: storeId);
    final attachedIds = attached.map((StaffCategory c) => c.id).toSet();

    // Custom categories owned by this store's mappings or all non-system
    // attached elsewhere still show under custom; catalog = system not attached.
    final customRaw = await _client
        .from('categories')
        .select()
        .eq('is_system', false)
        .eq('is_active', true)
        .order('name', ascending: true)
        .limit(100);
    final customRows = customRaw as List<dynamic>? ?? const <dynamic>[];
    final custom = <StaffCategory>[];
    for (final row in customRows) {
      final record = asRecord(row);
      if (record == null) continue;
      final parsed = parseCategory(record);
      if (parsed == null) continue;
      custom.add(
        StaffCategory.fromCategory(
          parsed,
          attached: attachedIds.contains(parsed.id),
        ),
      );
    }

    final term = query?.trim().toLowerCase() ?? '';
    final catalog = system
        .where((Category c) => !attachedIds.contains(c.id))
        .map((Category c) => StaffCategory.fromCategory(c))
        .where((StaffCategory c) {
          if (term.isEmpty) return true;
          return c.name.toLowerCase().contains(term) ||
              c.slug.toLowerCase().contains(term);
        })
        .toList(growable: false);

    final filteredCustom = custom.where((StaffCategory c) {
      if (term.isEmpty) return true;
      return c.name.toLowerCase().contains(term) ||
          c.slug.toLowerCase().contains(term);
    }).toList(growable: false);

    return <StaffCategory>[...catalog, ...filteredCustom];
  }
}

final storeSettingsRepositoryProvider =
    Provider<StoreSettingsRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return StoreSettingsRepository(AppSupabase.client);
});
