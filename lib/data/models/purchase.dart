import 'listing.dart';

class SupplierOption {
  const SupplierOption({
    required this.id,
    required this.name,
    this.phone,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phone;
  final bool isActive;

  factory SupplierOption.fromJson(Map<String, Object?> row) {
    return SupplierOption(
      id: asString(row['id']),
      name: asString(row['name']),
      phone: asNullableString(row['phone']),
      isActive: asBoolean(row['is_active'], true),
    );
  }
}

class PurchaseListItem {
  const PurchaseListItem({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.grandTotal,
    required this.status,
    required this.paymentStatus,
    required this.itemCount,
    this.dueAmount = 0,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String invoiceNumber;
  final String invoiceDate;
  final double grandTotal;
  final String status;
  final String paymentStatus;
  final int itemCount;
  final double dueAmount;

  factory PurchaseListItem.fromJoin(Map<String, Object?> row) {
    final supplier = asRecord(row['suppliers']);
    final items = row['purchase_order_items'];
    final itemCount = items is List ? items.length : asNumber(row['item_count']).round();
    return PurchaseListItem(
      id: asString(row['id']),
      supplierId: asString(row['supplier_id']),
      supplierName: asString(supplier?['name'], '—'),
      invoiceNumber: asString(row['invoice_number']),
      invoiceDate: asString(row['invoice_date']),
      grandTotal: asNumber(row['grand_total']),
      status: asString(row['status'], 'draft'),
      paymentStatus: asString(row['payment_status'], 'pending'),
      itemCount: itemCount,
      dueAmount: asNumber(row['due_amount']),
    );
  }
}

class PurchaseLineItem {
  const PurchaseLineItem({
    required this.id,
    required this.storeProductId,
    required this.productName,
    required this.batchNumber,
    required this.quantity,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    this.taxPercent = 0,
    this.discountPercent = 0,
    this.manufacturedAt,
    this.expiresAt,
  });

  final String id;
  final String storeProductId;
  final String productName;
  final String batchNumber;
  final double quantity;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
  final double taxPercent;
  final double discountPercent;
  final String? manufacturedAt;
  final String? expiresAt;

  factory PurchaseLineItem.fromJson(Map<String, Object?> row) {
    final master = asRecord(row['store_products']);
    final product = asRecord(master?['master_products']);
    return PurchaseLineItem(
      id: asString(row['id']),
      storeProductId: asString(row['store_product_id']),
      productName: asString(
        product?['name'] ?? row['product_name'],
        'Product',
      ),
      batchNumber: asString(row['batch_number']),
      quantity: asNumber(row['quantity']),
      purchasePrice: asNumber(row['purchase_price']),
      mrp: asNumber(row['mrp']),
      sellingPrice: asNumber(row['selling_price']),
      taxPercent: asNumber(row['tax_percent']),
      discountPercent: asNumber(row['discount_percent']),
      manufacturedAt: asNullableString(row['manufactured_at']),
      expiresAt: asNullableString(row['expires_at']),
    );
  }
}

class PurchaseDetail {
  const PurchaseDetail({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.otherCharges,
    required this.roundOffAmount,
    required this.grandTotal,
    required this.paymentStatus,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    required this.items,
    this.paymentMethod,
    this.notes,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String invoiceNumber;
  final String invoiceDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double otherCharges;
  final double roundOffAmount;
  final double grandTotal;
  final String paymentStatus;
  final String? paymentMethod;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final String? notes;
  final List<PurchaseLineItem> items;
}

class PurchaseItemInput {
  const PurchaseItemInput({
    required this.storeProductId,
    required this.batchNumber,
    required this.quantity,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    this.taxPercent = 0,
    this.discountPercent = 0,
    this.manufacturedAt,
    this.expiresAt,
  });

  final String storeProductId;
  final String batchNumber;
  final int quantity;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
  final double taxPercent;
  final double discountPercent;
  final String? manufacturedAt;
  final String? expiresAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'store_product_id': storeProductId,
      'batch_number': batchNumber.trim(),
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'mrp': mrp,
      'selling_price': sellingPrice,
      'tax_percent': taxPercent,
      'discount_percent': discountPercent,
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

class SavePurchaseInput {
  const SavePurchaseInput({
    required this.supplierId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.items,
    required this.subtotal,
    required this.grandTotal,
    required this.paymentStatus,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.otherCharges = 0,
    this.roundOffAmount = 0,
    this.paymentMethod,
    this.notes,
  });

  final String supplierId;
  final String invoiceNumber;
  final String invoiceDate;
  final List<PurchaseItemInput> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double otherCharges;
  final double roundOffAmount;
  final double grandTotal;
  final String paymentStatus;
  final String? paymentMethod;
  final double paidAmount;
  final double dueAmount;
  final String? notes;
  final String status;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber.trim(),
      'invoice_date': invoiceDate,
      'items': items.map((PurchaseItemInput i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'other_charges': otherCharges,
      'round_off_amount': roundOffAmount,
      'grand_total': grandTotal,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'notes': notes,
      'status': status,
    };
  }
}

class PurchaseTotals {
  const PurchaseTotals({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.otherCharges,
    required this.roundOffAmount,
    required this.grandTotal,
  });

  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double otherCharges;
  final double roundOffAmount;
  final double grandTotal;
}

double purchaseLineNet({
  required int quantity,
  required double purchasePrice,
  double discountPercent = 0,
}) {
  final gross = quantity * purchasePrice;
  final discount = gross * (discountPercent / 100);
  return gross - discount;
}

PurchaseTotals calculatePurchaseTotals({
  required List<PurchaseItemInput> items,
  double discountAmount = 0,
  double otherCharges = 0,
  double roundOff = 0,
}) {
  var subtotal = 0.0;
  var tax = 0.0;
  for (final item in items) {
    final net = purchaseLineNet(
      quantity: item.quantity,
      purchasePrice: item.purchasePrice,
      discountPercent: item.discountPercent,
    );
    subtotal += net;
    tax += net * (item.taxPercent / 100);
  }
  final grand = subtotal - discountAmount + tax + otherCharges + roundOff;
  return PurchaseTotals(
    subtotal: _round2(subtotal),
    taxAmount: _round2(tax),
    discountAmount: _round2(discountAmount),
    otherCharges: _round2(otherCharges),
    roundOffAmount: _round2(roundOff),
    grandTotal: _round2(grand),
  );
}

double _round2(double value) => (value * 100).round() / 100;
