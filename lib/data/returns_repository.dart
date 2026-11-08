import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/listing.dart';
import 'models/staff_return.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for returns (DATA_PLANE).
class ReturnsRepository {
  ReturnsRepository(this._client);

  final SupabaseClient _client;

  Future<List<StaffReturnListItem>> listReturns({
    required String storeId,
    String? query,
    String status = 'all',
  }) async {
    var filter = _client
        .from('returns')
        .select(
          'id, order_id, customer_id, status, refund_status, refund_amount, '
          'created_at, '
          'orders(order_number, customer_snapshot), '
          'customers(name, phone), '
          'return_items(id)',
        )
        .eq('store_id', storeId);

    if (status != 'all') {
      filter = filter.eq('status', status);
    }

    final raw = await filter.order('created_at', ascending: false).limit(80);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <StaffReturnListItem>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = StaffReturnListItem.fromJoin(record);
      if (item.id.isEmpty) continue;
      if (term.isNotEmpty) {
        final hay =
            '${item.shortId} ${item.orderNumber ?? ''} ${item.customerName ?? ''} '
                    '${item.customerPhone}'
                .toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }

  Future<StaffReturnDetail?> getReturn({
    required String storeId,
    required String returnId,
  }) async {
    final raw = await _client
        .from('returns')
        .select(
          '*, orders(order_number, customer_snapshot), '
          'customers(name, phone), '
          'return_items(*, order_items(product_snapshot))',
        )
        .eq('store_id', storeId)
        .eq('id', returnId)
        .maybeSingle();

    final row = asRecord(raw);
    if (row == null) return null;
    return StaffReturnDetail.fromJoin(row);
  }
}

final returnsRepositoryProvider = Provider<ReturnsRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return ReturnsRepository(AppSupabase.client);
});
