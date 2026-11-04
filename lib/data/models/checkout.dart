// Customer write-path DTOs — match docs/web-source/storefront.types.ts.

class RevalidateCartLineInput {
  const RevalidateCartLineInput({
    required this.storeProductId,
    required this.quantity,
  });

  final String storeProductId;
  final double quantity;

  Map<String, Object?> toJson() => <String, Object?>{
    'storeProductId': storeProductId,
    'quantity': quantity,
  };
}

class RevalidatedCartLine {
  const RevalidatedCartLine({
    required this.storeProductId,
    required this.quantity,
    required this.name,
    required this.unitPrice,
    required this.mrp,
    required this.stockCount,
    required this.isActive,
    required this.ok,
    this.message,
  });

  final String storeProductId;
  final double quantity;
  final String name;
  final double unitPrice;
  final double? mrp;
  final double stockCount;
  final bool isActive;
  final bool ok;
  final String? message;

  factory RevalidatedCartLine.fromJson(Map<Object?, Object?> row) {
    return RevalidatedCartLine(
      storeProductId: '${row['storeProductId'] ?? ''}',
      quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
      name: '${row['name'] ?? ''}',
      unitPrice: (row['unitPrice'] as num?)?.toDouble() ?? 0,
      mrp: (row['mrp'] as num?)?.toDouble(),
      stockCount: (row['stockCount'] as num?)?.toDouble() ?? 0,
      isActive: row['isActive'] == true,
      ok: row['ok'] != false,
      message: row['message']?.toString(),
    );
  }
}

class RevalidateCartResult {
  const RevalidateCartResult({
    required this.storeId,
    required this.lines,
    required this.subtotal,
    required this.ok,
    required this.messages,
  });

  final String storeId;
  final List<RevalidatedCartLine> lines;
  final double subtotal;
  final bool ok;
  final List<String> messages;

  factory RevalidateCartResult.fromJson(Map<Object?, Object?> row) {
    final rawLines = row['lines'];
    final lines = <RevalidatedCartLine>[];
    if (rawLines is List) {
      for (final entry in rawLines) {
        if (entry is Map) {
          lines.add(RevalidatedCartLine.fromJson(Map<Object?, Object?>.from(entry)));
        }
      }
    }
    final rawMessages = row['messages'];
    final messages = <String>[];
    if (rawMessages is List) {
      for (final entry in rawMessages) {
        messages.add('$entry');
      }
    }
    return RevalidateCartResult(
      storeId: '${row['storeId'] ?? ''}',
      lines: lines,
      subtotal: (row['subtotal'] as num?)?.toDouble() ?? 0,
      ok: row['ok'] != false,
      messages: messages,
    );
  }
}

class CheckoutAddress {
  const CheckoutAddress({
    this.label,
    required this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
  });

  final String? label;
  final String addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'address_line_1': addressLine1,
    'address_line_2': addressLine2,
    'city': city,
    'state': state,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class PlaceOnlineOrderInput {
  const PlaceOnlineOrderInput({
    required this.storeId,
    required this.items,
    required this.fulfillmentType,
    required this.paymentMethod,
    this.addressId,
    this.address,
    this.saveAddress = false,
    this.notes,
  });

  final String storeId;
  final List<RevalidateCartLineInput> items;
  final String fulfillmentType; // pickup | delivery
  final String paymentMethod; // cod | upi
  final String? addressId;
  final CheckoutAddress? address;
  final bool saveAddress;
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'storeId': storeId,
    'items': items.map((RevalidateCartLineInput i) => i.toJson()).toList(),
    'addressId': addressId,
    'address': address?.toJson(),
    'saveAddress': saveAddress,
    'fulfillmentType': fulfillmentType,
    'paymentMethod': paymentMethod,
    'notes': notes,
  };
}

class PlaceOnlineOrderResult {
  const PlaceOnlineOrderResult({
    required this.orderId,
    required this.storeId,
    required this.orderNumber,
    required this.totalAmount,
  });

  final String orderId;
  final String storeId;
  final int? orderNumber;
  final double totalAmount;

  factory PlaceOnlineOrderResult.fromJson(Map<Object?, Object?> row) {
    final number = row['orderNumber'];
    return PlaceOnlineOrderResult(
      orderId: '${row['orderId'] ?? ''}',
      storeId: '${row['storeId'] ?? ''}',
      orderNumber: number is num ? number.toInt() : int.tryParse('$number'),
      totalAmount: (row['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.customerId,
    required this.phone,
    this.name,
  });

  final String customerId;
  final String phone;
  final String? name;

  factory CustomerProfile.fromJson(Map<Object?, Object?> row) {
    return CustomerProfile(
      customerId: '${row['customerId'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      name: row['name']?.toString(),
    );
  }
}
