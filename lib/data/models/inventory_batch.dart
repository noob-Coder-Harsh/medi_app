import 'listing.dart';

class InventoryBatch {
  const InventoryBatch({
    required this.id,
    required this.storeProductId,
    required this.mrp,
    required this.sellingPrice,
    required this.quantity,
    required this.availableQuantity,
    this.batchNo,
    this.purchasePrice,
    this.reservedQuantity = 0,
    this.manufacturedAt,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String storeProductId;
  final String? batchNo;
  final double? purchasePrice;
  final double mrp;
  final double sellingPrice;
  final double quantity;
  final double availableQuantity;
  final double reservedQuantity;
  final String? manufacturedAt;
  final String? expiresAt;
  final String? createdAt;

  double get soldQuantity {
    final sold = quantity - availableQuantity;
    return sold < 0 ? 0 : sold;
  }

  factory InventoryBatch.fromJson(Map<String, Object?> row) {
    return InventoryBatch(
      id: asString(row['id']),
      storeProductId: asString(row['store_product_id']),
      batchNo: asNullableString(row['batch_no']),
      purchasePrice: asNullableNumber(row['purchase_price']),
      mrp: asNumber(row['mrp']),
      sellingPrice: asNumber(row['selling_price']),
      quantity: asNumber(row['quantity']),
      availableQuantity: asNumber(row['available_quantity']),
      reservedQuantity: asNumber(row['reserved_quantity']),
      manufacturedAt: asNullableString(row['manufactured_at']),
      expiresAt: asNullableString(row['expires_at']),
      createdAt: asNullableString(row['created_at']),
    );
  }

  InventoryBatch copyWith({
    double? sellingPrice,
    double? availableQuantity,
    double? quantity,
  }) {
    return InventoryBatch(
      id: id,
      storeProductId: storeProductId,
      batchNo: batchNo,
      purchasePrice: purchasePrice,
      mrp: mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      reservedQuantity: reservedQuantity,
      manufacturedAt: manufacturedAt,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}

class OpeningBatchInput {
  const OpeningBatchInput({
    required this.batchNo,
    required this.mrp,
    required this.sellingPrice,
    required this.quantity,
    required this.purchasePrice,
    this.manufacturedAt,
    this.expiresAt,
  });

  final String batchNo;
  final double mrp;
  final double sellingPrice;
  final int quantity;
  final double purchasePrice;
  final String? manufacturedAt;
  final String? expiresAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'batch_no': batchNo.trim(),
      'mrp': mrp,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'manufactured_at': _emptyToNull(manufacturedAt),
      'expires_at': _emptyToNull(expiresAt),
    };
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class UpdateStoreProductInput {
  const UpdateStoreProductInput({
    this.isActive,
    this.salePolicy,
    this.rackLocation,
    this.reorderLevel,
    this.categoryId,
    this.name,
    this.genericName,
    this.manufacturer,
    this.strength,
    this.dosageForm,
    this.baseUnit,
    this.primaryPackType,
    this.primaryPackQuantity,
    this.requiresPrescription,
    this.listingMrp,
    this.listingSellingPrice,
  });

  final bool? isActive;
  final String? salePolicy;
  final String? rackLocation;
  final int? reorderLevel;
  final String? categoryId;
  final String? name;
  final String? genericName;
  final String? manufacturer;
  final String? strength;
  final String? dosageForm;
  final String? baseUnit;
  final String? primaryPackType;
  final int? primaryPackQuantity;
  final bool? requiresPrescription;
  final double? listingMrp;
  final double? listingSellingPrice;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (isActive != null) 'is_active': isActive,
      if (salePolicy != null) 'sale_policy': salePolicy,
      if (rackLocation != null) 'rack_location': rackLocation,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name!.trim(),
      if (genericName != null) 'generic_name': genericName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (strength != null) 'strength': strength,
      if (dosageForm != null) 'dosage_form': dosageForm,
      if (baseUnit != null) 'base_unit': baseUnit,
      if (primaryPackType != null) 'primary_pack_type': primaryPackType,
      if (primaryPackQuantity != null)
        'primary_pack_quantity': primaryPackQuantity,
      if (requiresPrescription != null)
        'requires_prescription': requiresPrescription,
      if (listingMrp != null) 'listing_mrp': listingMrp,
      if (listingSellingPrice != null)
        'listing_selling_price': listingSellingPrice,
    };
  }
}

enum BatchStatusTone { red, amber, green, slate }

class BatchStatus {
  const BatchStatus(this.label, this.tone);

  final String label;
  final BatchStatusTone tone;
}

BatchStatus batchStatus(InventoryBatch batch, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  if (batch.availableQuantity <= 0) {
    return const BatchStatus('0', BatchStatusTone.slate);
  }
  final expires = batch.expiresAt;
  if (expires != null && expires.isNotEmpty) {
    final expiry = DateTime.tryParse(expires);
    if (expiry != null) {
      final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
      if (expiryDay.isBefore(day)) {
        return const BatchStatus('Expired', BatchStatusTone.red);
      }
      final days = expiryDay.difference(day).inDays;
      if (days <= 30) {
        return const BatchStatus('Expiring soon', BatchStatusTone.amber);
      }
    }
  }
  return const BatchStatus('Active', BatchStatusTone.green);
}
