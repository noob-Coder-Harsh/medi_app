// Customer order DTOs — match docs/web-source/storefront.types.ts.

class CustomerOrderListItem {
  const CustomerOrderListItem({
    required this.id,
    required this.orderNumber,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
    required this.itemCount,
    required this.totalAmount,
    required this.status,
    required this.placedAt,
    required this.canCancel,
  });

  final String id;
  final int orderNumber;
  final String storeId;
  final String storeName;
  final String? storeSlug;
  final int itemCount;
  final double totalAmount;
  final String status;
  final String placedAt;
  final bool canCancel;

  factory CustomerOrderListItem.fromJson(Map<Object?, Object?> row) {
    final number = row['orderNumber'] ?? row['order_number'];
    return CustomerOrderListItem(
      id: '${row['id'] ?? ''}',
      orderNumber: number is num ? number.toInt() : int.tryParse('$number') ?? 0,
      storeId: '${row['storeId'] ?? row['store_id'] ?? ''}',
      storeName: '${row['storeName'] ?? row['store_name'] ?? ''}',
      storeSlug: (row['storeSlug'] ?? row['store_slug'])?.toString(),
      itemCount: (row['itemCount'] as num?)?.toInt() ??
          (row['item_count'] as num?)?.toInt() ??
          0,
      totalAmount: (row['totalAmount'] as num?)?.toDouble() ??
          (row['total_amount'] as num?)?.toDouble() ??
          0,
      status: '${row['status'] ?? ''}',
      placedAt: '${row['placedAt'] ?? row['placed_at'] ?? ''}',
      canCancel: row['canCancel'] == true || row['can_cancel'] == true,
    );
  }
}

class CustomerOrderLine {
  const CustomerOrderLine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  factory CustomerOrderLine.fromJson(Map<Object?, Object?> row) {
    final snapshot = row['product_snapshot'] ?? row['productSnapshot'];
    String name = '';
    if (snapshot is Map) {
      name = '${snapshot['name'] ?? ''}';
    }
    if (name.isEmpty) name = '${row['name'] ?? ''}';
    return CustomerOrderLine(
      id: '${row['id'] ?? ''}',
      name: name,
      quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (row['unit_price'] as num?)?.toDouble() ??
          (row['unitPrice'] as num?)?.toDouble() ??
          0,
      totalPrice: (row['total_price'] as num?)?.toDouble() ??
          (row['totalPrice'] as num?)?.toDouble() ??
          0,
    );
  }
}

class CustomerOrderDetail {
  const CustomerOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
    required this.status,
    required this.paymentMethod,
    required this.fulfillmentType,
    required this.totalAmount,
    required this.placedAt,
    required this.canCancel,
    required this.items,
  });

  final String id;
  final int orderNumber;
  final String storeId;
  final String storeName;
  final String? storeSlug;
  final String status;
  final String paymentMethod;
  final String? fulfillmentType;
  final double totalAmount;
  final String placedAt;
  final bool canCancel;
  final List<CustomerOrderLine> items;

  factory CustomerOrderDetail.fromJson(Map<Object?, Object?> row) {
    final orderRaw = row['order'];
    final order = orderRaw is Map
        ? Map<Object?, Object?>.from(orderRaw)
        : row;
    final number = order['order_number'] ?? order['orderNumber'];
    final itemsRaw = row['items'];
    final items = <CustomerOrderLine>[];
    if (itemsRaw is List) {
      for (final entry in itemsRaw) {
        if (entry is Map) {
          items.add(CustomerOrderLine.fromJson(Map<Object?, Object?>.from(entry)));
        }
      }
    }
    return CustomerOrderDetail(
      id: '${order['id'] ?? row['id'] ?? ''}',
      orderNumber: number is num ? number.toInt() : int.tryParse('$number') ?? 0,
      storeId: '${order['store_id'] ?? order['storeId'] ?? row['storeId'] ?? ''}',
      storeName: '${row['storeName'] ?? row['store_name'] ?? ''}',
      storeSlug: (row['storeSlug'] ?? row['store_slug'])?.toString(),
      status: '${order['status'] ?? ''}',
      paymentMethod:
          '${order['payment_method'] ?? order['paymentMethod'] ?? ''}',
      fulfillmentType:
          (order['fulfillment_type'] ?? order['fulfillmentType'])?.toString(),
      totalAmount: (order['total_amount'] as num?)?.toDouble() ??
          (order['totalAmount'] as num?)?.toDouble() ??
          0,
      placedAt: '${order['placed_at'] ?? order['placedAt'] ?? ''}',
      canCancel: row['canCancel'] == true || row['can_cancel'] == true,
      items: items,
    );
  }
}

List<CustomerOrderListItem> parseCustomerOrderList(Object? raw) {
  final list = <CustomerOrderListItem>[];
  Object? rows = raw;
  if (raw is Map) {
    rows = raw['orders'] ?? raw['items'] ?? raw['data'];
  }
  if (rows is! List) return list;
  for (final entry in rows) {
    if (entry is Map) {
      list.add(CustomerOrderListItem.fromJson(Map<Object?, Object?>.from(entry)));
    }
  }
  return list;
}
