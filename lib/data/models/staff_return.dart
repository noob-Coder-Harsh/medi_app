import 'listing.dart';
import 'staff_order.dart';

String staffReturnStatusLabelKey(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized.isEmpty) return status;
  return 'STORE_FORM.RETURN_STATUS_$normalized';
}

String staffRefundStatusLabelKey(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized.isEmpty) return status;
  return 'STORE_FORM.RETURN_REFUND_$normalized';
}

class StaffReturnListItem {
  const StaffReturnListItem({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.itemCount,
    required this.refundAmount,
    required this.status,
    required this.refundStatus,
    required this.createdAt,
  });

  final String id;
  final String? orderId;
  final int? orderNumber;
  final String? customerName;
  final String customerPhone;
  final int itemCount;
  final double refundAmount;
  final String status;
  final String refundStatus;
  final String createdAt;

  String get displayCustomer {
    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (customerPhone.isNotEmpty) return customerPhone;
    return '—';
  }

  String get shortId {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  factory StaffReturnListItem.fromJoin(Map<String, Object?> row) {
    final order = asRecord(row['orders']);
    final customer = asRecord(row['customers']);
    final snapshot = asRecord(order?['customer_snapshot']);
    final items = row['return_items'];
    final itemCount = items is List
        ? items.length
        : asNumber(row['item_count']).round();
    final number = order?['order_number'];
    return StaffReturnListItem(
      id: asString(row['id']),
      orderId: asNullableString(row['order_id']),
      orderNumber: number is num
          ? number.toInt()
          : int.tryParse('$number'),
      customerName: asNullableString(
        customer?['name'] ?? snapshot?['name'],
      ),
      customerPhone: asString(
        customer?['phone'] ?? snapshot?['phone'],
      ),
      itemCount: itemCount,
      refundAmount: asNumber(row['refund_amount']),
      status: asString(row['status'], 'pending'),
      refundStatus: asString(row['refund_status'], 'none'),
      createdAt: asString(row['created_at']),
    );
  }
}

class StaffReturnLine {
  const StaffReturnLine({
    required this.id,
    required this.orderItemId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.refundAmount,
    required this.condition,
    required this.restockAction,
  });

  final String id;
  final String? orderItemId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double refundAmount;
  final String condition;
  final String restockAction;

  factory StaffReturnLine.fromJson(Map<String, Object?> row) {
    final orderItem = asRecord(row['order_items']);
    final snapshot = asRecord(orderItem?['product_snapshot']);
    return StaffReturnLine(
      id: asString(row['id']),
      orderItemId: asNullableString(row['order_item_id']),
      productName: asString(
        snapshot?['name'] ?? row['product_name'],
        'Product',
      ),
      quantity: asNumber(row['quantity']).round(),
      unitPrice: asNumber(row['unit_price']),
      refundAmount: asNumber(row['refund_amount']),
      condition: asString(row['condition'], 'sealed'),
      restockAction: asString(row['restock_action'], 'restock'),
    );
  }
}

class StaffReturnDetail {
  const StaffReturnDetail({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.refundStatus,
    required this.subtotal,
    required this.refundAmount,
    required this.createdAt,
    required this.items,
    this.reason,
    this.notes,
  });

  final String id;
  final String? orderId;
  final int? orderNumber;
  final String? customerName;
  final String customerPhone;
  final String status;
  final String refundStatus;
  final double subtotal;
  final double refundAmount;
  final String createdAt;
  final List<StaffReturnLine> items;
  final String? reason;
  final String? notes;

  bool get canApprove => status == 'pending';
  bool get canReject => status == 'pending';

  factory StaffReturnDetail.fromJoin(Map<String, Object?> row) {
    final order = asRecord(row['orders']);
    final customer = asRecord(row['customers']);
    final snapshot = asRecord(order?['customer_snapshot']);
    final itemRows = row['return_items'];
    final items = <StaffReturnLine>[];
    if (itemRows is List) {
      for (final item in itemRows) {
        final record = asRecord(item);
        if (record == null) continue;
        items.add(StaffReturnLine.fromJson(record));
      }
    }
    final number = order?['order_number'];
    return StaffReturnDetail(
      id: asString(row['id']),
      orderId: asNullableString(row['order_id']),
      orderNumber: number is num
          ? number.toInt()
          : int.tryParse('$number'),
      customerName: asNullableString(
        customer?['name'] ?? snapshot?['name'],
      ),
      customerPhone: asString(
        customer?['phone'] ?? snapshot?['phone'],
      ),
      status: asString(row['status'], 'pending'),
      refundStatus: asString(row['refund_status'], 'none'),
      subtotal: asNumber(row['subtotal']),
      refundAmount: asNumber(row['refund_amount']),
      createdAt: asString(row['created_at']),
      items: items,
      reason: asNullableString(row['reason']),
      notes: asNullableString(row['notes']),
    );
  }

  factory StaffReturnDetail.fromApi(Map<Object?, Object?> map) {
    final nested = map['return'];
    final source = nested is Map
        ? nested.map((Object? k, Object? v) => MapEntry('$k', v))
        : map.map((Object? k, Object? v) => MapEntry('$k', v));
    final itemsRaw = map['items'] ?? source['return_items'];
    if (itemsRaw != null) {
      source['return_items'] = itemsRaw;
    }
    return StaffReturnDetail.fromJoin(source);
  }
}

class CreateReturnItemInput {
  const CreateReturnItemInput({
    required this.orderItemId,
    required this.quantity,
    this.condition = 'sealed',
    this.restockAction = 'restock',
  });

  final String orderItemId;
  final int quantity;
  final String condition;
  final String restockAction;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'order_item_id': orderItemId,
      'quantity': quantity,
      'condition': condition,
      'restock_action': restockAction,
    };
  }
}

class CreateReturnInput {
  const CreateReturnInput({
    required this.orderId,
    required this.items,
    this.reason,
    this.notes,
  });

  final String orderId;
  final List<CreateReturnItemInput> items;
  final String? reason;
  final String? notes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'order_id': orderId,
      'reason': reason,
      'notes': notes,
      'items': items
          .map((CreateReturnItemInput item) => item.toJson())
          .toList(growable: false),
    };
  }
}

/// Delivered order option for the return form picker.
class ReturnableOrderOption {
  const ReturnableOrderOption({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.placedAt,
    required this.items,
  });

  final String id;
  final int orderNumber;
  final String? customerName;
  final String customerPhone;
  final double totalAmount;
  final String placedAt;
  final List<StaffOrderLine> items;

  String get displayCustomer {
    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (customerPhone.isNotEmpty) return customerPhone;
    return '—';
  }

  factory ReturnableOrderOption.fromDetail(StaffOrderDetail detail) {
    return ReturnableOrderOption(
      id: detail.id,
      orderNumber: detail.orderNumber,
      customerName: detail.customerName,
      customerPhone: detail.customerPhone,
      totalAmount: detail.totalAmount,
      placedAt: detail.placedAt,
      items: detail.items,
    );
  }
}
