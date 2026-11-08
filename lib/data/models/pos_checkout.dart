class PosCustomerCard {
  const PosCustomerCard({
    required this.customerId,
    required this.phone,
    this.name,
    this.totalOrders = 0,
    this.loyaltyPoints = 0,
  });

  final String customerId;
  final String phone;
  final String? name;
  final int totalOrders;
  final int loyaltyPoints;

  factory PosCustomerCard.fromJson(Map<Object?, Object?> json) {
    return PosCustomerCard(
      customerId: _str(json, const <String>['customerId', 'customer_id']),
      phone: _str(json, const <String>['phone']),
      name: _nullableStr(json, const <String>['name']),
      totalOrders: _int(json, const <String>['totalOrders', 'total_orders']),
      loyaltyPoints: _int(json, const <String>['loyaltyPoints', 'loyalty_points']),
    );
  }
}

enum PosPaymentMethod { cash, upi, card, credit, mixed }

extension PosPaymentMethodApi on PosPaymentMethod {
  String get apiValue => name;
}

class PosCheckoutLineInput {
  const PosCheckoutLineInput({
    required this.storeProductId,
    required this.quantity,
    required this.unitPrice,
    this.unitMrp,
  });

  final String storeProductId;
  final int quantity;
  final double unitPrice;
  final double? unitMrp;

  Map<String, Object?> toJson() => <String, Object?>{
    'store_product_id': storeProductId,
    'quantity': quantity,
    'unit_price': unitPrice,
    if (unitMrp != null) 'unit_mrp': unitMrp,
  };
}

class PosCheckoutInput {
  const PosCheckoutInput({
    required this.customerId,
    required this.items,
    required this.paymentMethod,
    required this.paidAmount,
    this.discountType = 'none',
    this.discountValue = 0,
    this.taxAmount = 0,
    this.notes,
  });

  final String customerId;
  final List<PosCheckoutLineInput> items;
  final PosPaymentMethod paymentMethod;
  final double paidAmount;
  final String discountType;
  final double discountValue;
  final double taxAmount;
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'customer_id': customerId,
    'items': items.map((PosCheckoutLineInput i) => i.toJson()).toList(),
    'payment_method': paymentMethod.apiValue,
    'paid_amount': paidAmount,
    'discount_type': discountType,
    'discount_value': discountValue,
    'tax_amount': taxAmount,
    'notes': notes,
  };
}

class PosCheckoutResult {
  const PosCheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.paymentMethod,
    this.customerPhone,
    this.placedAt,
  });

  final String orderId;
  final int orderNumber;
  final double totalAmount;
  final String paymentMethod;
  final String? customerPhone;
  final String? placedAt;

  factory PosCheckoutResult.fromJson(Map<Object?, Object?> json) {
    final order = json['order'];
    final Map<Object?, Object?> root;
    if (order is Map) {
      final nested = Map<Object?, Object?>.from(order);
      final inner = nested['order'];
      root = inner is Map
          ? Map<Object?, Object?>.from(inner)
          : nested;
    } else {
      root = json;
    }

    final snapshot = root['customer_snapshot'];
    String? phone;
    if (snapshot is Map) {
      phone = _nullableStr(
        Map<Object?, Object?>.from(snapshot),
        const <String>['phone'],
      );
    }

    return PosCheckoutResult(
      orderId: _str(root, const <String>['orderId', 'id', 'order_id']),
      orderNumber: _int(root, const <String>['orderNumber', 'order_number']),
      totalAmount: _num(
        root,
        const <String>['totalAmount', 'total_amount', 'grand_total'],
      ),
      paymentMethod: _str(
        root,
        const <String>['paymentMethod', 'payment_method'],
        fallback: 'cash',
      ),
      customerPhone:
          phone ??
          _nullableStr(json, const <String>['customerPhone', 'customer_phone']),
      placedAt: _nullableStr(root, const <String>['placedAt', 'placed_at']),
    );
  }
}

class PosRecentSale {
  const PosRecentSale({
    required this.id,
    required this.orderNumber,
    required this.customerPhone,
    required this.totalAmount,
    required this.placedAt,
    this.customerName,
    this.itemCount = 0,
    this.status = '',
    this.source = 'pos',
  });

  final String id;
  final int orderNumber;
  final String customerPhone;
  final String? customerName;
  final int itemCount;
  final double totalAmount;
  final String placedAt;
  final String status;
  final String source;

  factory PosRecentSale.fromJson(Map<Object?, Object?> json) {
    return PosRecentSale(
      id: _str(json, const <String>['id']),
      orderNumber: _int(json, const <String>['orderNumber', 'order_number']),
      customerPhone: _str(json, const <String>['customerPhone', 'customer_phone']),
      customerName: _nullableStr(json, const <String>['customerName', 'customer_name']),
      itemCount: _int(json, const <String>['itemCount', 'item_count']),
      totalAmount: _num(json, const <String>['totalAmount', 'total_amount']),
      placedAt: _str(json, const <String>['placedAt', 'placed_at']),
      status: _str(json, const <String>['status']),
      source: _str(json, const <String>['source'], fallback: 'pos'),
    );
  }
}

List<PosRecentSale> parsePosRecentSales(Object? raw) {
  if (raw is Map && raw['sales'] is List) {
    raw = raw['sales'];
  }
  if (raw is! List) return const <PosRecentSale>[];
  return raw
      .whereType<Map>()
      .map(
        (Map row) => PosRecentSale.fromJson(Map<Object?, Object?>.from(row)),
      )
      .toList(growable: false);
}

String _str(
  Map<Object?, Object?> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && '$value'.isNotEmpty) return '$value';
  }
  return fallback;
}

String? _nullableStr(Map<Object?, Object?> json, List<String> keys) {
  final value = _str(json, keys);
  return value.isEmpty ? null : value;
}

int _int(Map<Object?, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

double _num(Map<Object?, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}
