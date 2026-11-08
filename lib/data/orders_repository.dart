import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/listing.dart';
import 'models/staff_order.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for staff order board (DATA_PLANE).
class OrdersRepository {
  OrdersRepository(this._client);

  final SupabaseClient _client;

  Future<List<StaffOrderListItem>> listOrders({
    required String storeId,
    String? query,
    String status = 'all',
    String source = 'all',
  }) async {
    var filter = _client
        .from('orders')
        .select(
          'id, customer_id, order_number, source, status, total_amount, '
          'placed_at, fulfillment_type, payment_method, payment_status, '
          'customer_snapshot, '
          'order_items(id, product_snapshot, '
          'store_products(master_products(image_url, name)))',
        )
        .eq('store_id', storeId);

    if (status != 'all') {
      filter = filter.eq('status', status);
    }
    if (source != 'all') {
      filter = filter.eq('source', source);
    }

    final raw = await filter.order('placed_at', ascending: false).limit(80);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <StaffOrderListItem>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = StaffOrderListItem.fromJoin(record);
      if (item.id.isEmpty) continue;
      // Skip draft/kiosk noise on the board unless explicitly filtered.
      if (source == 'all' && item.source == 'kiosk') continue;
      if (term.isNotEmpty) {
        final hay =
            '${item.orderNumber} ${item.customerName ?? ''} ${item.customerPhone}'
                .toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }

  Future<StaffOrderDetail?> getOrder({
    required String storeId,
    required String orderId,
  }) async {
    final raw = await _client
        .from('orders')
        .select(
          '*, order_items(*, store_products(master_products(image_url))), '
          'order_status_history(*)',
        )
        .eq('store_id', storeId)
        .eq('id', orderId)
        .maybeSingle();

    final row = asRecord(raw);
    if (row == null) return null;
    return StaffOrderDetail.fromJoin(row);
  }

  Future<List<StaffOrderListItem>> listDeliveredOrders({
    required String storeId,
    String? query,
  }) {
    return listOrders(
      storeId: storeId,
      query: query,
      status: 'delivered',
      source: 'all',
    );
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return OrdersRepository(AppSupabase.client);
});
