import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/listing.dart';
import 'models/staff_books.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for customers, suppliers, payments (DATA_PLANE).
class BooksRepository {
  BooksRepository(this._client);

  final SupabaseClient _client;

  Future<List<StaffCustomer>> listCustomers({
    required String storeId,
    String? query,
  }) async {
    final raw = await _client
        .from('store_customers')
        .select('*, customers(*)')
        .eq('store_id', storeId)
        .order('updated_at', ascending: false)
        .limit(100);

    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <StaffCustomer>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = StaffCustomer.fromJoin(record);
      if (item.id.isEmpty) continue;
      if (term.isNotEmpty) {
        final hay = '${item.displayName} ${item.phone}'.toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }

  Future<List<StaffSupplier>> listSuppliers({
    required String storeId,
    String? query,
    bool activeOnly = false,
  }) async {
    final raw = await _client
        .from('suppliers')
        .select('*')
        .eq('store_id', storeId)
        .isFilter('deleted_at', null)
        .order('name', ascending: true)
        .limit(100);

    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <StaffSupplier>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = StaffSupplier.fromJson(record);
      if (item.id.isEmpty) continue;
      if (activeOnly && !item.isActive) continue;
      if (term.isNotEmpty) {
        final hay =
            '${item.name} ${item.contactPerson ?? ''} ${item.phone ?? ''} ${item.email ?? ''}'
                .toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }

  Future<List<StaffPayment>> listPayments({
    required String storeId,
    String? query,
  }) async {
    final raw = await _client
        .from('payments')
        .select(
          '*, orders(order_number, customer_snapshot), '
          'suppliers(name), purchase_orders(invoice_number)',
        )
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(100);

    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <StaffPayment>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = StaffPayment.fromJoin(record);
      if (item.id.isEmpty) continue;
      if (term.isNotEmpty) {
        final hay = [
          item.customerName,
          item.supplierName,
          item.orderNo,
          item.purchaseInvoice,
          item.referenceNumber,
          item.paymentType,
          item.method,
        ].whereType<String>().join(' ').toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }
}

final booksRepositoryProvider = Provider<BooksRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return BooksRepository(AppSupabase.client);
});
