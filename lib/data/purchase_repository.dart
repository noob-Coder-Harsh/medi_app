import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/listing.dart';
import 'models/purchase.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for purchases + suppliers (DATA_PLANE).
class PurchaseRepository {
  PurchaseRepository(this._client);

  final SupabaseClient _client;

  Future<List<SupplierOption>> listSuppliers({
    required String storeId,
    String? query,
  }) async {
    final raw = await _client
        .from('suppliers')
        .select('id, name, phone, is_active')
        .eq('store_id', storeId)
        .isFilter('deleted_at', null)
        .order('name', ascending: true)
        .limit(100);

    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <SupplierOption>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final supplier = SupplierOption.fromJson(record);
      if (!supplier.isActive || supplier.id.isEmpty) continue;
      if (term.isNotEmpty) {
        final hay = '${supplier.name} ${supplier.phone ?? ''}'.toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(supplier);
    }
    return out;
  }

  Future<List<PurchaseListItem>> listPurchases({
    required String storeId,
    String? query,
    String status = 'all',
  }) async {
    final filter = _client
        .from('purchase_orders')
        .select(
          'id, supplier_id, invoice_number, invoice_date, grand_total, '
          'status, payment_status, due_amount, created_at, '
          'suppliers(name), purchase_order_items(id)',
        )
        .eq('store_id', storeId);

    final filtered = status != 'all' ? filter.eq('status', status) : filter;
    final raw = await filtered
        .order('created_at', ascending: false)
        .limit(50);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final term = query?.trim().toLowerCase() ?? '';
    final out = <PurchaseListItem>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final item = PurchaseListItem.fromJoin(record);
      if (item.id.isEmpty) continue;
      if (term.isNotEmpty) {
        final hay =
            '${item.invoiceNumber} ${item.supplierName}'.toLowerCase();
        if (!hay.contains(term)) continue;
      }
      out.add(item);
    }
    return out;
  }

  Future<PurchaseDetail?> getPurchase({
    required String storeId,
    required String purchaseOrderId,
  }) async {
    final raw = await _client
        .from('purchase_orders')
        .select(
          '*, suppliers(name), '
          'purchase_order_items(*, store_products(master_products(name)))',
        )
        .eq('store_id', storeId)
        .eq('id', purchaseOrderId)
        .maybeSingle();

    final row = asRecord(raw);
    if (row == null) return null;
    final supplier = asRecord(row['suppliers']);
    final itemRows = row['purchase_order_items'];
    final items = <PurchaseLineItem>[];
    if (itemRows is List) {
      for (final item in itemRows) {
        final record = asRecord(item);
        if (record == null) continue;
        items.add(PurchaseLineItem.fromJson(record));
      }
    }

    return PurchaseDetail(
      id: asString(row['id']),
      supplierId: asString(row['supplier_id']),
      supplierName: asString(supplier?['name'], '—'),
      invoiceNumber: asString(row['invoice_number']),
      invoiceDate: asString(row['invoice_date']),
      subtotal: asNumber(row['subtotal']),
      discountAmount: asNumber(row['discount_amount']),
      taxAmount: asNumber(row['tax_amount']),
      otherCharges: asNumber(row['other_charges']),
      roundOffAmount: asNumber(row['round_off_amount']),
      grandTotal: asNumber(row['grand_total']),
      paymentStatus: asString(row['payment_status'], 'pending'),
      paymentMethod: asNullableString(row['payment_method']),
      paidAmount: asNumber(row['paid_amount']),
      dueAmount: asNumber(row['due_amount']),
      status: asString(row['status'], 'draft'),
      notes: asNullableString(row['notes']),
      items: items,
    );
  }
}

final purchaseRepositoryProvider = Provider<PurchaseRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return PurchaseRepository(AppSupabase.client);
});
