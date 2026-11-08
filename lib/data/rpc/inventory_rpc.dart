import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import '../supabase_client.dart';

/// Owner inventory list RPC — `list_store_inventory`.
class InventoryRpc {
  InventoryRpc(this._client);

  final SupabaseClient _client;

  Future<InventoryPagePayload> listStoreInventory({
    String query = '',
    String? categoryId,
    String status = 'all',
    String rx = 'all',
    String stock = 'all',
    String sort = 'name',
    String sortDir = 'asc',
    int offset = 0,
    int limit = 25,
  }) async {
    final raw = await _client.rpc(
      'list_store_inventory',
      params: <String, dynamic>{
        'p_query': query,
        'p_category_id': categoryId,
        'p_status': status,
        'p_rx': rx,
        'p_stock': stock,
        'p_sort': sort,
        'p_sort_dir': sortDir,
        'p_offset': offset,
        'p_limit': limit,
      },
    );
    return parseInventoryPage(raw);
  }
}

final inventoryRpcProvider = Provider<InventoryRpc?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return InventoryRpc(AppSupabase.client);
});
