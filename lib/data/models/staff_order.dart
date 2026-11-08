import '../../core/packaging.dart';
import 'listing.dart';

/// Allowed next statuses — mirror web `ORDER_STATUS_TRANSITIONS`.
const Map<String, List<String>> kOrderStatusTransitions =
    <String, List<String>>{
      'draft': <String>['pending', 'cancelled'],
      'pending': <String>['confirmed', 'delivered', 'cancelled'],
      'confirmed': <String>['processing', 'cancelled'],
      'processing': <String>['ready', 'cancelled'],
      'ready': <String>['out_for_delivery', 'delivered', 'cancelled'],
      'out_for_delivery': <String>['delivered', 'cancelled'],
      'delivered': <String>['refunded'],
      'cancelled': <String>[],
      'refunded': <String>[],
    };

List<String> nextOrderStatuses(String status) {
  return List<String>.unmodifiable(
    kOrderStatusTransitions[status] ?? const <String>[],
  );
}

String staffOrderStatusLabelKey(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized.isEmpty) return status;
  return 'STORE_FORM.STATUS_$normalized';
}

String staffOrderSourceLabelKey(String source) {
  final normalized = source.trim().toUpperCase();
  if (normalized.isEmpty) return source;
  return 'STORE_FORM.SOURCE_$normalized';
}

String? _orderItemImageUrl(
  Map<String, Object?> snapshot, [
  Map<String, Object?>? row,
]) {
  final fromSnap = asNullableString(snapshot['image_url']) ??
      asNullableString(snapshot['thumb']) ??
      asNullableString(snapshot['imageUrl']);
  if (fromSnap != null && fromSnap.trim().isNotEmpty) return fromSnap.trim();

  final storeProduct = asRecord(row?['store_products']);
  final master = asRecord(storeProduct?['master_products']);
  final fromMaster = asNullableString(master?['image_url']) ??
      asNullableString(master?['thumb']);
  if (fromMaster != null && fromMaster.trim().isNotEmpty) {
    return fromMaster.trim();
  }
  return null;
}

String? _firstOrderItemImage(Object? items) {
  if (items is! List) return null;
  for (final item in items) {
    final record = asRecord(item);
    if (record == null) continue;
    final snapshot =
        asRecord(record['product_snapshot']) ?? const <String, Object?>{};
    final url = _orderItemImageUrl(snapshot, record);
    if (url != null) return url;
  }
  return null;
}

String? _firstOrderItemName(Object? items) {
  if (items is! List) return null;
  for (final item in items) {
    final record = asRecord(item);
    if (record == null) continue;
    final snapshot =
        asRecord(record['product_snapshot']) ?? const <String, Object?>{};
    final name = asString(snapshot['name'] ?? record['name']).trim();
    if (name.isNotEmpty) return name;
  }
  return null;
}

class StaffOrderListItem {
  const StaffOrderListItem({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.itemCount,
    required this.totalAmount,
    required this.source,
    required this.status,
    required this.placedAt,
    this.fulfillmentType,
    this.paymentMethod,
    this.paymentStatus,
    this.firstItemImageUrl,
    this.firstItemName,
  });

  final String id;
  final int orderNumber;
  final String customerId;
  final String? customerName;
  final String customerPhone;
  final int itemCount;
  final double totalAmount;
  final String source;
  final String status;
  final String placedAt;
  final String? fulfillmentType;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? firstItemImageUrl;
  final String? firstItemName;

  String get displayCustomer {
    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (customerPhone.isNotEmpty) return customerPhone;
    return '—';
  }

  factory StaffOrderListItem.fromJoin(Map<String, Object?> row) {
    final snapshot = asRecord(row['customer_snapshot']) ?? const <String, Object?>{};
    final items = row['order_items'];
    final itemCount = items is List
        ? items.length
        : asNumber(row['item_count']).round();
    final number = row['order_number'];
    return StaffOrderListItem(
      id: asString(row['id']),
      orderNumber: number is num
          ? number.toInt()
          : int.tryParse('$number') ?? 0,
      customerId: asString(row['customer_id']),
      customerName: asNullableString(snapshot['name']),
      customerPhone: asString(snapshot['phone'] ?? row['customer_phone']),
      itemCount: itemCount,
      totalAmount: asNumber(row['total_amount']),
      source: asString(row['source'], 'pos'),
      status: asString(row['status'], 'pending'),
      placedAt: asString(row['placed_at'] ?? row['created_at']),
      fulfillmentType: asNullableString(row['fulfillment_type']),
      paymentMethod: asNullableString(row['payment_method']),
      paymentStatus: asNullableString(row['payment_status']),
      firstItemImageUrl: _firstOrderItemImage(items),
      firstItemName: _firstOrderItemName(items),
    );
  }
}

class StaffOrderLine {
  const StaffOrderLine({
    required this.id,
    required this.storeProductId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.batchNo,
    this.imageUrl,
    this.mrp,
    this.manufacturer,
    this.packLabel,
    this.baseUnitLabel,
  });

  final String id;
  final String storeProductId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? batchNo;
  final String? imageUrl;
  final double? mrp;
  final String? manufacturer;
  final String? packLabel;
  final String? baseUnitLabel;

  factory StaffOrderLine.fromJson(Map<String, Object?> row) {
    final snapshot =
        asRecord(row['product_snapshot']) ?? const <String, Object?>{};
    final packaging = asRecord(snapshot['packaging']);
    final packInfo = PackagingInfo(
      baseUnit: asNullableString(packaging?['base_unit']),
      primaryPackType: asNullableString(packaging?['primary_pack_type']),
      primaryPackQuantity: asNullableNumber(packaging?['primary_pack_quantity']),
    );
    final packLabel = asNullableString(packaging?['label'])?.trim();
    final resolvedPack = (packLabel != null && packLabel.isNotEmpty)
        ? packLabel
        : formatPackLabel(packInfo);
    final unit = getBaseUnitLabel(packInfo.baseUnit);
    return StaffOrderLine(
      id: asString(row['id']),
      storeProductId: asString(
        row['store_product_id'] ?? snapshot['store_product_id'],
      ),
      productName: asString(snapshot['name'] ?? row['name'], 'Product'),
      quantity: asNumber(row['quantity']).round(),
      unitPrice: asNumber(row['unit_price']),
      totalPrice: asNumber(row['total_price']),
      batchNo: asNullableString(snapshot['batch_no']),
      imageUrl: _orderItemImageUrl(snapshot, row),
      mrp: asNullableNumber(snapshot['mrp']),
      manufacturer: asNullableString(snapshot['manufacturer']),
      packLabel: resolvedPack,
      baseUnitLabel: unit,
    );
  }
}

class StaffOrderStatusEvent {
  const StaffOrderStatusEvent({
    required this.id,
    required this.toStatus,
    required this.createdAt,
    this.fromStatus,
    this.notes,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? notes;
  final String createdAt;

  factory StaffOrderStatusEvent.fromJson(Map<String, Object?> row) {
    return StaffOrderStatusEvent(
      id: asString(row['id']),
      fromStatus: asNullableString(row['from_status']),
      toStatus: asString(row['to_status']),
      notes: asNullableString(row['notes']),
      createdAt: asString(row['created_at']),
    );
  }
}

class StaffOrderDetail {
  const StaffOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.source,
    required this.status,
    required this.totalAmount,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discountAmount,
    required this.placedAt,
    required this.items,
    required this.history,
    this.fulfillmentType,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
  });

  final String id;
  final int orderNumber;
  final String customerId;
  final String? customerName;
  final String customerPhone;
  final String source;
  final String status;
  final double totalAmount;
  final double subtotal;
  final double deliveryCharge;
  final double discountAmount;
  final String placedAt;
  final List<StaffOrderLine> items;
  final List<StaffOrderStatusEvent> history;
  final String? fulfillmentType;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? notes;

  String get displayCustomer {
    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (customerPhone.isNotEmpty) return customerPhone;
    return '—';
  }

  List<String> get nextStatuses => nextOrderStatuses(status);

  factory StaffOrderDetail.fromJoin(Map<String, Object?> row) {
    final snapshot = asRecord(row['customer_snapshot']) ?? const <String, Object?>{};
    final itemRows = row['order_items'];
    final items = <StaffOrderLine>[];
    if (itemRows is List) {
      for (final item in itemRows) {
        final record = asRecord(item);
        if (record == null) continue;
        items.add(StaffOrderLine.fromJson(record));
      }
    }
    final historyRows = row['order_status_history'];
    final history = <StaffOrderStatusEvent>[];
    if (historyRows is List) {
      for (final event in historyRows) {
        final record = asRecord(event);
        if (record == null) continue;
        history.add(StaffOrderStatusEvent.fromJson(record));
      }
      history.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    final number = row['order_number'];
    return StaffOrderDetail(
      id: asString(row['id']),
      orderNumber: number is num
          ? number.toInt()
          : int.tryParse('$number') ?? 0,
      customerId: asString(row['customer_id']),
      customerName: asNullableString(snapshot['name']),
      customerPhone: asString(snapshot['phone']),
      source: asString(row['source'], 'pos'),
      status: asString(row['status'], 'pending'),
      totalAmount: asNumber(row['total_amount']),
      subtotal: asNumber(row['subtotal']),
      deliveryCharge: asNumber(row['delivery_charge']),
      discountAmount: asNumber(row['discount_amount']),
      placedAt: asString(row['placed_at'] ?? row['created_at']),
      items: items,
      history: history,
      fulfillmentType: asNullableString(row['fulfillment_type']),
      paymentMethod: asNullableString(row['payment_method']),
      paymentStatus: asNullableString(row['payment_status']),
      notes: asNullableString(row['notes']),
    );
  }

  /// Parse staff API write response (`{ order, items, status_history }` or flat).
  factory StaffOrderDetail.fromApi(Map<Object?, Object?> map) {
    final nested = map['order'];
    final orderMap = nested is Map
        ? nested.map((Object? k, Object? v) => MapEntry('$k', v))
        : map.map((Object? k, Object? v) => MapEntry('$k', v));
    final itemsRaw = map['items'] ?? orderMap['order_items'];
    if (itemsRaw != null) {
      orderMap['order_items'] = itemsRaw;
    }
    final historyRaw =
        map['status_history'] ??
        map['order_status_history'] ??
        orderMap['order_status_history'];
    if (historyRaw != null) {
      orderMap['order_status_history'] = historyRaw;
    }
    return StaffOrderDetail.fromJoin(orderMap);
  }
}
