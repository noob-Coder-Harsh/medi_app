import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/inventory_batch.dart';
import 'models/listing.dart';
import 'supabase_client.dart';

/// Owner JWT SELECT for batches + store flags (DATA_PLANE).
class InventoryRepository {
  InventoryRepository(this._client);

  final SupabaseClient _client;

  Future<bool> allowsOpeningStock(String storeId) async {
    final raw = await _client
        .from('stores')
        .select('onboarding_completed')
        .eq('id', storeId)
        .maybeSingle();
    final row = asRecord(raw);
    if (row == null) return true;
    return row['onboarding_completed'] != true;
  }

  Future<List<InventoryBatch>> listBatches(String storeProductId) async {
    final raw = await _client
        .from('inventory_batches')
        .select('*')
        .eq('store_product_id', storeProductId)
        .order('expires_at', ascending: true);
    final rows = raw as List<dynamic>? ?? const <dynamic>[];
    final out = <InventoryBatch>[];
    for (final row in rows) {
      final record = asRecord(row);
      if (record == null) continue;
      final batch = InventoryBatch.fromJson(record);
      if (batch.id.isEmpty) continue;
      out.add(batch);
    }
    return out;
  }

  Future<ListingCard?> getListingCard(String storeProductId) async {
    final raw = await _client
        .from('store_products')
        .select(
          'id, store_id, product_id, is_active, is_featured, sale_policy, '
          'rack_location, reorder_level, on_hand_quantity, reserved_quantity, '
          'available_quantity, listing_mrp, listing_selling_price, '
          'created_at, updated_at, '
          'master_products(*, categories(id, name, slug))',
        )
        .eq('id', storeProductId)
        .maybeSingle();
    final row = asRecord(raw);
    if (row == null) return null;
    return _listingFromJoin(row);
  }

  ListingCard? _listingFromJoin(Map<String, Object?> row) {
    final master = asRecord(row['master_products']);
    if (master == null) return null;
    final category = asRecord(master['categories']);
    final schedule = asString(master['drug_schedule'], 'none');
    final available = asNumber(row['available_quantity']);
    return ListingCard(
      id: asString(row['id']),
      storeId: asString(row['store_id']),
      productId: asString(row['product_id']),
      slug: asString(master['slug']),
      name: asString(master['name']),
      genericName: asNullableString(master['generic_name']),
      manufacturer: asNullableString(master['manufacturer']),
      composition: asNullableString(master['composition']),
      description: asNullableString(master['description']),
      thumb: asNullableString(master['image_url']),
      imageUrl: asNullableString(master['image_url']),
      packLabel: 'Unit',
      baseUnit: asNullableString(master['base_unit']),
      primaryPackType: asNullableString(master['primary_pack_type']),
      primaryPackQuantity: asNullableNumber(master['primary_pack_quantity']),
      secondaryPackType: asNullableString(master['secondary_pack_type']),
      secondaryPackQuantity: asNullableNumber(master['secondary_pack_quantity']),
      dosageForm: asNullableString(master['dosage_form']),
      strength: asNullableString(master['strength']),
      mrp: asNullableNumber(row['listing_mrp']),
      sellingPrice: asNullableNumber(row['listing_selling_price']),
      unit: asNullableString(master['base_unit']),
      inStock: available > 0,
      availableQuantity: available,
      onHandQuantity: asNumber(row['on_hand_quantity']),
      reservedQuantity: asNumber(row['reserved_quantity']),
      reorderLevel: asNumber(row['reorder_level']),
      rackLocation: asNullableString(row['rack_location']),
      salePolicy: asString(row['sale_policy'], 'inherit'),
      schedule: schedule,
      kind: asString(master['product_kind'], 'tablet_capsule'),
      categoryId: asNullableString(master['category_id']) ??
          asNullableString(category?['id']),
      categoryName: asNullableString(category?['name']),
      categorySlug: asNullableString(category?['slug']),
      isFeatured: asBoolean(row['is_featured']),
      isActive: asBoolean(row['is_active'], true),
      requiresPrescription: isPrescriptionRequired(schedule),
      gstRate: asNullableNumber(master['gst_rate']),
      hsnCode: asNullableString(master['hsn_code']),
      trackBatch: asBoolean(master['track_batch'], true),
      storage: asString(master['storage'], 'ambient'),
      isSystem: asBoolean(master['is_system'], true),
      createdAt: asString(row['created_at']),
      updatedAt: asString(row['updated_at']),
    );
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository?>((Ref ref) {
  if (!AppSupabase.isReady) return null;
  return InventoryRepository(AppSupabase.client);
});
