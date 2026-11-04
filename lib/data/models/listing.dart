// Dart port of docs/web-source/listing.ts (customer listing only).

Map<String, Object?>? asRecord(Object? value) {
  if (value is Map) {
    return value.map((Object? key, Object? v) => MapEntry(key.toString(), v));
  }
  return null;
}

String asString(Object? value, [String fallback = '']) {
  return value is String ? value : fallback;
}

String? asNullableString(Object? value) {
  return value is String ? value : null;
}

double asNumber(Object? value, [double fallback = 0]) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return fallback;
}

double? asNullableNumber(Object? value) {
  if (value == null || value == '') return null;
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return null;
}

bool asBoolean(Object? value, [bool fallback = false]) {
  return value is bool ? value : fallback;
}

bool isPrescriptionRequired(String? schedule) {
  return schedule == 'h' ||
      schedule == 'h1' ||
      schedule == 'x' ||
      schedule == 'c';
}

class ListingCard {
  const ListingCard({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.slug,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.composition,
    required this.description,
    required this.thumb,
    required this.imageUrl,
    required this.packLabel,
    required this.baseUnit,
    required this.primaryPackType,
    required this.primaryPackQuantity,
    required this.secondaryPackType,
    required this.secondaryPackQuantity,
    required this.dosageForm,
    required this.strength,
    required this.mrp,
    required this.sellingPrice,
    required this.unit,
    required this.inStock,
    required this.availableQuantity,
    required this.onHandQuantity,
    required this.reservedQuantity,
    required this.reorderLevel,
    required this.rackLocation,
    required this.salePolicy,
    required this.schedule,
    required this.kind,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.isFeatured,
    required this.isActive,
    required this.requiresPrescription,
    required this.gstRate,
    required this.hsnCode,
    required this.trackBatch,
    required this.storage,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
    this.storeName,
    this.storeSlug,
  });

  final String id;
  final String storeId;
  final String productId;
  final String slug;
  final String name;
  final String? genericName;
  final String? manufacturer;
  final String? composition;
  final String? description;
  final String? thumb;
  final String? imageUrl;
  final String packLabel;
  final String? baseUnit;
  final String? primaryPackType;
  final double? primaryPackQuantity;
  final String? secondaryPackType;
  final double? secondaryPackQuantity;
  final String? dosageForm;
  final String? strength;
  final double? mrp;
  final double? sellingPrice;
  final String? unit;
  final bool inStock;
  final double availableQuantity;
  final double onHandQuantity;
  final double reservedQuantity;
  final double reorderLevel;
  final String? rackLocation;
  final String salePolicy;
  final String schedule;
  final String kind;
  final String? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final bool isFeatured;
  final bool isActive;
  final bool requiresPrescription;
  final double? gstRate;
  final String? hsnCode;
  final bool trackBatch;
  final String storage;
  final bool isSystem;
  final String createdAt;
  final String updatedAt;
  final String? storeName;
  final String? storeSlug;
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconUrl,
    required this.sortOrder,
    required this.isSystem,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final double sortOrder;
  final bool isSystem;
  final bool isActive;
  final String createdAt;
}

class PublicStore {
  const PublicStore({
    required this.id,
    required this.name,
    required this.slug,
    required this.phone,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.logoUrl,
    required this.bannerUrl,
    required this.whatsappNumber,
    required this.openingTime,
    required this.closingTime,
    required this.serviceRadiusKm,
    required this.minimumOrderAmount,
    required this.deliveryCharge,
    required this.freeDeliveryAbove,
    required this.allowCod,
    required this.allowManualUpi,
    required this.allowPrescriptionUpload,
    required this.modulePickup,
    required this.moduleDelivery,
    required this.upiId,
    required this.upiQrUrl,
    required this.isOpen,
    required this.acceptsOnlineOrders,
    required this.salePolicy,
  });

  final String id;
  final String name;
  final String slug;
  final String? phone;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? bannerUrl;
  final String? whatsappNumber;
  final String? openingTime;
  final String? closingTime;
  final double serviceRadiusKm;
  final double minimumOrderAmount;
  final double deliveryCharge;
  final double? freeDeliveryAbove;
  final bool allowCod;
  final bool allowManualUpi;
  final bool allowPrescriptionUpload;
  final bool modulePickup;
  final bool moduleDelivery;
  final String? upiId;
  final String? upiQrUrl;
  final bool isOpen;
  final bool acceptsOnlineOrders;
  final String salePolicy;
}

class NearbyStore {
  const NearbyStore({required this.store, required this.distanceKm});

  final PublicStore store;
  final double distanceKm;
}

Map<String, Object?> publicStoreToJson(PublicStore store) {
  return <String, Object?>{
    'id': store.id,
    'name': store.name,
    'slug': store.slug,
    'phone': store.phone,
    'description': store.description,
    'address': store.address,
    'city': store.city,
    'state': store.state,
    'pincode': store.pincode,
    'latitude': store.latitude,
    'longitude': store.longitude,
    'logo_url': store.logoUrl,
    'banner_url': store.bannerUrl,
    'whatsapp_number': store.whatsappNumber,
    'opening_time': store.openingTime,
    'closing_time': store.closingTime,
    'service_radius_km': store.serviceRadiusKm,
    'minimum_order_amount': store.minimumOrderAmount,
    'delivery_charge': store.deliveryCharge,
    'free_delivery_above': store.freeDeliveryAbove,
    'allow_cod': store.allowCod,
    'allow_manual_upi': store.allowManualUpi,
    'allow_prescription_upload': store.allowPrescriptionUpload,
    'module_pickup': store.modulePickup,
    'module_delivery': store.moduleDelivery,
    'upi_id': store.upiId,
    'upi_qr_url': store.upiQrUrl,
    'is_open': store.isOpen,
    'accepts_online_orders': store.acceptsOnlineOrders,
    'sale_policy': store.salePolicy,
  };
}

Map<String, Object?> nearbyStoreToJson(NearbyStore nearby) {
  return <String, Object?>{
    ...publicStoreToJson(nearby.store),
    'distance_km': nearby.distanceKm,
  };
}

enum StoreShellStatus { ok, notFound, unavailable }

class StoreShellPayload {
  const StoreShellPayload({
    required this.status,
    required this.store,
    required this.categories,
  });

  static const empty = StoreShellPayload(
    status: StoreShellStatus.notFound,
    store: null,
    categories: <Category>[],
  );

  final StoreShellStatus status;
  final PublicStore? store;
  final List<Category> categories;
}

class StoreHomePayload {
  const StoreHomePayload({
    required this.status,
    required this.store,
    required this.categories,
    required this.featured,
    required this.products,
  });

  static const empty = StoreHomePayload(
    status: StoreShellStatus.notFound,
    store: null,
    categories: <Category>[],
    featured: <ListingCard>[],
    products: <ListingCard>[],
  );

  final StoreShellStatus status;
  final PublicStore? store;
  final List<Category> categories;
  final List<ListingCard> featured;
  final List<ListingCard> products;
}

ListingCard? parseListingCard(Object? value) {
  final row = asRecord(value);
  if (row == null || row['id'] is! String) return null;

  final schedule = asString(row['schedule'], 'none');
  final available = asNumber(row['available_quantity']);

  return ListingCard(
    id: row['id']! as String,
    storeId: asString(row['store_id']),
    productId: asString(row['product_id']),
    slug: asString(row['slug']),
    name: asString(row['name']),
    genericName: asNullableString(row['generic_name']),
    manufacturer: asNullableString(row['manufacturer']),
    composition: asNullableString(row['composition']),
    description: asNullableString(row['description']),
    thumb: asNullableString(row['thumb']) ?? asNullableString(row['image_url']),
    imageUrl: asNullableString(row['image_url']) ?? asNullableString(row['thumb']),
    packLabel: asString(row['pack_label'], 'Unit'),
    baseUnit: asNullableString(row['base_unit']) ?? asNullableString(row['unit']),
    primaryPackType: asNullableString(row['primary_pack_type']),
    primaryPackQuantity: asNullableNumber(row['primary_pack_quantity']),
    secondaryPackType: asNullableString(row['secondary_pack_type']),
    secondaryPackQuantity: asNullableNumber(row['secondary_pack_quantity']),
    dosageForm: asNullableString(row['dosage_form']),
    strength: asNullableString(row['strength']),
    mrp: asNullableNumber(row['mrp']),
    sellingPrice: asNullableNumber(row['selling_price']),
    unit: asNullableString(row['unit']) ?? asNullableString(row['base_unit']),
    inStock: asBoolean(row['in_stock'], available > 0),
    availableQuantity: available,
    onHandQuantity: asNumber(row['on_hand_quantity'], available),
    reservedQuantity: asNumber(row['reserved_quantity']),
    reorderLevel: asNumber(row['reorder_level']),
    rackLocation: asNullableString(row['rack_location']),
    salePolicy: asString(row['sale_policy'], 'inherit'),
    schedule: schedule,
    kind: asString(row['kind'], 'tablet_capsule'),
    categoryId: asNullableString(row['category_id']),
    categoryName: asNullableString(row['category_name']),
    categorySlug: asNullableString(row['category_slug']),
    isFeatured: asBoolean(row['is_featured']),
    isActive: asBoolean(row['is_active'], true),
    requiresPrescription: asBoolean(
      row['requires_prescription'],
      isPrescriptionRequired(schedule),
    ),
    gstRate: asNullableNumber(row['gst_rate']),
    hsnCode: asNullableString(row['hsn_code']),
    trackBatch: asBoolean(row['track_batch'], true),
    storage: asString(row['storage'], 'ambient'),
    isSystem: asBoolean(row['is_system'], true),
    createdAt: asString(row['created_at']),
    updatedAt: asString(row['updated_at']),
    storeName: asNullableString(row['store_name']),
    storeSlug: asNullableString(row['store_slug']),
  );
}

List<ListingCard> parseListingCards(Object? value) {
  if (value is! List) return const <ListingCard>[];
  return value.map(parseListingCard).whereType<ListingCard>().toList();
}

Category? parseCategory(Object? value) {
  final row = asRecord(value);
  if (row == null || row['id'] is! String) return null;
  return Category(
    id: row['id']! as String,
    name: asString(row['name']),
    slug: asString(row['slug']),
    iconUrl: asNullableString(row['icon_url']),
    sortOrder: asNumber(row['sort_order']),
    isSystem: asBoolean(row['is_system'], true),
    isActive: asBoolean(row['is_active'], true),
    createdAt: asString(row['created_at']),
  );
}

List<Category> parseCategories(Object? value) {
  if (value is! List) return const <Category>[];
  return value.map(parseCategory).whereType<Category>().toList();
}

PublicStore? parsePublicStore(Object? value) {
  final row = asRecord(value);
  if (row == null || row['id'] is! String) return null;
  return PublicStore(
    id: row['id']! as String,
    name: asString(row['name']),
    slug: asString(row['slug']),
    phone: asNullableString(row['phone']),
    description: asNullableString(row['description']),
    address: asNullableString(row['address']),
    city: asNullableString(row['city']),
    state: asNullableString(row['state']),
    pincode: asNullableString(row['pincode']),
    latitude: asNullableNumber(row['latitude']),
    longitude: asNullableNumber(row['longitude']),
    logoUrl: asNullableString(row['logo_url']),
    bannerUrl: asNullableString(row['banner_url']),
    whatsappNumber: asNullableString(row['whatsapp_number']),
    openingTime: asNullableString(row['opening_time']),
    closingTime: asNullableString(row['closing_time']),
    serviceRadiusKm: asNumber(row['service_radius_km'], 5),
    minimumOrderAmount: asNumber(row['minimum_order_amount']),
    deliveryCharge: asNumber(row['delivery_charge']),
    freeDeliveryAbove: asNullableNumber(row['free_delivery_above']),
    allowCod: asBoolean(row['allow_cod'], true),
    allowManualUpi: asBoolean(row['allow_manual_upi'], true),
    allowPrescriptionUpload: asBoolean(row['allow_prescription_upload'], true),
    modulePickup: asBoolean(row['module_pickup']),
    moduleDelivery: asBoolean(row['module_delivery']),
    upiId: asNullableString(row['upi_id']),
    upiQrUrl: asNullableString(row['upi_qr_url']),
    isOpen: asBoolean(row['is_open'], true),
    acceptsOnlineOrders: asBoolean(row['accepts_online_orders']),
    salePolicy: asString(row['sale_policy'], 'loose_allowed'),
  );
}

List<NearbyStore> parseNearbyStores(Object? value) {
  if (value is! List) return const <NearbyStore>[];
  final out = <NearbyStore>[];
  for (final entry in value) {
    final store = parsePublicStore(entry);
    final row = asRecord(entry);
    if (store == null || row == null) continue;
    out.add(
      NearbyStore(store: store, distanceKm: asNumber(row['distance_km'])),
    );
  }
  return out;
}

StoreShellPayload parseStoreShell(Object? value) {
  final row = asRecord(value);
  final statusRaw = asString(row?['status'], 'not_found');
  final status = switch (statusRaw) {
    'ok' => StoreShellStatus.ok,
    'unavailable' => StoreShellStatus.unavailable,
    _ => StoreShellStatus.notFound,
  };
  return StoreShellPayload(
    status: status,
    store: parsePublicStore(row?['store']),
    categories: parseCategories(row?['categories']),
  );
}

StoreHomePayload parseStoreHome(Object? value) {
  final shell = parseStoreShell(value);
  final row = asRecord(value);
  return StoreHomePayload(
    status: shell.status,
    store: shell.store,
    categories: shell.categories,
    featured: parseListingCards(row?['featured']),
    products: parseListingCards(row?['products']),
  );
}
