import '../../../core/packaging.dart';
import '../../../data/models/listing.dart';

class PosProduct {
  const PosProduct({
    required this.storeProductId,
    required this.name,
    required this.stockCount,
    required this.unitPrice,
    required this.salePolicy,
    this.genericName,
    this.manufacturer,
    this.categoryName,
    this.requiresPrescription = false,
    this.reorderLevel = 0,
    this.mrp,
    this.imageUrl,
    this.baseUnit,
    this.primaryPackType,
    this.primaryPackQuantity,
  });

  final String storeProductId;
  final String name;
  final String? genericName;
  final String? manufacturer;
  final String? categoryName;
  final bool requiresPrescription;
  final double stockCount;
  final double reorderLevel;
  final double? mrp;
  final double unitPrice;
  final String? imageUrl;
  final String salePolicy;
  final String? baseUnit;
  final String? primaryPackType;
  final double? primaryPackQuantity;

  PackagingInfo get packaging => PackagingInfo(
    baseUnit: baseUnit,
    primaryPackType: primaryPackType,
    primaryPackQuantity: primaryPackQuantity,
  );

  bool get hasStock => stockCount > 0;

  factory PosProduct.fromListingCard(ListingCard card) {
    return PosProduct(
      storeProductId: card.id,
      name: card.name,
      genericName: card.genericName,
      manufacturer: card.manufacturer,
      categoryName: card.categoryName,
      requiresPrescription: card.requiresPrescription,
      stockCount: card.availableQuantity,
      reorderLevel: card.reorderLevel,
      mrp: card.mrp,
      unitPrice: card.sellingPrice ?? 0,
      imageUrl: card.imageUrl ?? card.thumb,
      salePolicy: card.salePolicy.isEmpty ? 'inherit' : card.salePolicy,
      baseUnit: card.baseUnit,
      primaryPackType: card.primaryPackType,
      primaryPackQuantity: card.primaryPackQuantity,
    );
  }
}

class PosCartItem {
  const PosCartItem({
    required this.product,
    required this.quantity,
  });

  final PosProduct product;
  final double quantity;

  String get storeProductId => product.storeProductId;

  PosCartItem copyWith({PosProduct? product, double? quantity}) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
