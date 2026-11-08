import 'inventory_batch.dart';
import 'listing.dart';

/// Master catalogue row for staff medicines browse / search.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.genericName,
    this.manufacturer,
    this.strength,
    this.dosageForm,
    this.drugSchedule = 'none',
    this.imageUrl,
    this.isSystem = true,
    this.isInStore = false,
    this.baseUnit,
    this.primaryPackType,
    this.primaryPackQuantity,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String? genericName;
  final String? manufacturer;
  final String? strength;
  final String? dosageForm;
  final String drugSchedule;
  final String? imageUrl;
  final bool isSystem;
  final bool isInStore;
  final String? baseUnit;
  final String? primaryPackType;
  final double? primaryPackQuantity;

  bool get requiresPrescription => isPrescriptionRequired(drugSchedule);

  String get subtitle {
    final parts = <String>[
      if (dosageForm != null && dosageForm!.trim().isNotEmpty) dosageForm!,
      if (strength != null && strength!.trim().isNotEmpty) strength!,
      if (manufacturer != null && manufacturer!.trim().isNotEmpty) manufacturer!,
    ];
    return parts.join(' · ');
  }

  CatalogProduct copyWith({bool? isInStore}) {
    return CatalogProduct(
      id: id,
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      genericName: genericName,
      manufacturer: manufacturer,
      strength: strength,
      dosageForm: dosageForm,
      drugSchedule: drugSchedule,
      imageUrl: imageUrl,
      isSystem: isSystem,
      isInStore: isInStore ?? this.isInStore,
      baseUnit: baseUnit,
      primaryPackType: primaryPackType,
      primaryPackQuantity: primaryPackQuantity,
    );
  }

  factory CatalogProduct.fromRow(
    Map<String, Object?> row, {
    bool? isInStore,
  }) {
    final categories = asRecord(row['categories']);
    return CatalogProduct(
      id: asString(row['id']),
      name: asString(row['name']),
      categoryId: asNullableString(row['category_id']),
      categoryName: asNullableString(categories?['name']),
      genericName: asNullableString(row['generic_name']),
      manufacturer: asNullableString(row['manufacturer']),
      strength: asNullableString(row['strength']),
      dosageForm: asNullableString(row['dosage_form']),
      drugSchedule: asString(row['drug_schedule'], 'none'),
      imageUrl: asNullableString(row['image_url']),
      isSystem: asBoolean(row['is_system'], true),
      isInStore: isInStore ?? asBoolean(row['is_in_store']),
      baseUnit: asNullableString(row['base_unit']),
      primaryPackType: asNullableString(row['primary_pack_type']),
      primaryPackQuantity: asNullableNumber(row['primary_pack_quantity']),
    );
  }
}

/// Store SKU already linked from catalogue / custom create.
class StoreCatalogProduct {
  const StoreCatalogProduct({
    required this.storeProductId,
    required this.productId,
    required this.name,
    this.categoryName,
    this.genericName,
    this.manufacturer,
    this.strength,
    this.dosageForm,
    this.drugSchedule = 'none',
    this.imageUrl,
    this.isSystem = false,
    this.isActive = true,
  });

  final String storeProductId;
  final String productId;
  final String name;
  final String? categoryName;
  final String? genericName;
  final String? manufacturer;
  final String? strength;
  final String? dosageForm;
  final String drugSchedule;
  final String? imageUrl;
  final bool isSystem;
  final bool isActive;

  bool get requiresPrescription => isPrescriptionRequired(drugSchedule);

  String get subtitle {
    final parts = <String>[
      if (dosageForm != null && dosageForm!.trim().isNotEmpty) dosageForm!,
      if (strength != null && strength!.trim().isNotEmpty) strength!,
      if (manufacturer != null && manufacturer!.trim().isNotEmpty) manufacturer!,
    ];
    return parts.join(' · ');
  }

  factory StoreCatalogProduct.fromJoin(Map<String, Object?> row) {
    final master = asRecord(row['master_products']) ?? const <String, Object?>{};
    final categories = asRecord(master['categories']);
    final productId = asNullableString(row['product_id']) ??
        asNullableString(master['id']) ??
        '';
    return StoreCatalogProduct(
      storeProductId: asString(row['id']),
      productId: productId,
      name: asString(master['name']),
      categoryName: asNullableString(categories?['name']),
      genericName: asNullableString(master['generic_name']),
      manufacturer: asNullableString(master['manufacturer']),
      strength: asNullableString(master['strength']),
      dosageForm: asNullableString(master['dosage_form']),
      drugSchedule: asString(master['drug_schedule'], 'none'),
      imageUrl: asNullableString(master['image_url']),
      isSystem: asBoolean(master['is_system']),
      isActive: asBoolean(row['is_active'], true),
    );
  }
}

/// Payload for custom product create (matches web ProductCreateForm + opening batch).
class CreateCustomProductInput {
  const CreateCustomProductInput({
    required this.categoryId,
    required this.name,
    required this.openingBatch,
    this.genericName,
    this.manufacturer,
    this.strength,
    this.dosageForm,
    this.baseUnit,
    this.primaryPackType,
    this.primaryPackQuantity,
    this.requiresPrescription = false,
    this.description,
  });

  final String categoryId;
  final String name;
  final OpeningBatchInput openingBatch;
  final String? genericName;
  final String? manufacturer;
  final String? strength;
  final String? dosageForm;
  final String? baseUnit;
  final String? primaryPackType;
  final int? primaryPackQuantity;
  final bool requiresPrescription;
  final String? description;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'category_id': categoryId,
      'name': name.trim(),
      'generic_name': _emptyToNull(genericName),
      'manufacturer': _emptyToNull(manufacturer),
      'strength': _emptyToNull(strength),
      'dosage_form': _emptyToNull(dosageForm),
      'base_unit': _emptyToNull(baseUnit),
      'primary_pack_type': _emptyToNull(primaryPackType),
      'primary_pack_quantity': primaryPackQuantity,
      'requires_prescription': requiresPrescription,
      'description': _emptyToNull(description),
      'opening_batch': openingBatch.toJson(),
    };
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class CatalogWriteResult {
  const CatalogWriteResult({
    required this.storeProductId,
    required this.productId,
    required this.name,
  });

  final String storeProductId;
  final String productId;
  final String name;

  factory CatalogWriteResult.fromJson(Map<Object?, Object?> json) {
    final storeProduct = _asMap(json['store_product']);
    final product = _asMap(json['product']);
    return CatalogWriteResult(
      storeProductId: _string(
        storeProduct?['id'] ?? json['storeProductId'] ?? json['store_product_id'],
      ),
      productId: _string(
        product?['id'] ??
            storeProduct?['product_id'] ??
            json['productId'] ??
            json['product_id'],
      ),
      name: _string(product?['name'] ?? json['name']),
    );
  }

  static Map<Object?, Object?>? _asMap(Object? value) {
    if (value is Map) return Map<Object?, Object?>.from(value);
    return null;
  }

  static String _string(Object? value) {
    if (value == null) return '';
    return '$value';
  }
}

const List<String> kDosageFormValues = <String>[
  'tablet',
  'capsule',
  'syrup',
  'injection',
  'cream',
  'ointment',
  'drops',
  'inhaler',
  'powder',
  'suspension',
  'gel',
  'spray',
];
