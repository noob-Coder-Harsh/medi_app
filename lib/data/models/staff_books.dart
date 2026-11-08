import 'listing.dart';

class StaffCustomer {
  const StaffCustomer({
    required this.id,
    required this.customerId,
    required this.phone,
    this.name,
    this.notes,
    this.currentBalance = 0,
    this.loyaltyPoints = 0,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.lastOrderAt,
    this.isActive = true,
  });

  final String id;
  final String customerId;
  final String phone;
  final String? name;
  final String? notes;
  final double currentBalance;
  final int loyaltyPoints;
  final int totalOrders;
  final double totalSpent;
  final String? lastOrderAt;
  final bool isActive;

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return phone;
  }

  factory StaffCustomer.fromJoin(Map<String, Object?> row) {
    final customer = asRecord(row['customers']) ?? const <String, Object?>{};
    return StaffCustomer(
      id: asString(row['id']),
      customerId: asString(row['customer_id']),
      phone: asString(customer['phone'] ?? row['phone']),
      name: asNullableString(customer['name'] ?? row['name']),
      notes: asNullableString(row['notes']),
      currentBalance: asNumber(row['current_balance']),
      loyaltyPoints: asNumber(row['loyalty_points']).round(),
      totalOrders: asNumber(row['total_orders']).round(),
      totalSpent: asNumber(row['total_spent']),
      lastOrderAt: asNullableString(row['last_order_at']),
      isActive: asBoolean(customer['is_active'], true),
    );
  }

  factory StaffCustomer.fromDetailJson(Map<Object?, Object?> json) {
    final storeCustomerRaw = json['storeCustomer'] ?? json['store_customer'];
    final customerRaw = json['customer'];
    final store = storeCustomerRaw is Map
        ? Map<Object?, Object?>.from(storeCustomerRaw)
        : json;
    final customer = customerRaw is Map
        ? Map<Object?, Object?>.from(customerRaw)
        : const <Object?, Object?>{};
    String str(Object? value, [String fallback = '']) {
      if (value == null) return fallback;
      final text = '$value';
      return text.isEmpty ? fallback : text;
    }

    double asNum(Object? value) {
      if (value is int || value is double) return (value as num).toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return StaffCustomer(
      id: str(store['id']),
      customerId: str(store['customer_id'] ?? customer['id']),
      phone: str(customer['phone'] ?? store['phone']),
      name: customer['name']?.toString(),
      notes: store['notes']?.toString(),
      currentBalance: asNum(store['current_balance']),
      loyaltyPoints: asNum(store['loyalty_points']).round(),
      totalOrders: asNum(store['total_orders']).round(),
      totalSpent: asNum(store['total_spent']),
      lastOrderAt: store['last_order_at']?.toString(),
      isActive: customer['is_active'] != false,
    );
  }
}

class StaffSupplier {
  const StaffSupplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.notes,
    this.currentBalance = 0,
    this.openingBalance = 0,
    this.paymentTermsDays = 0,
    this.totalPurchaseAmount = 0,
    this.lastPurchaseAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? notes;
  final double currentBalance;
  final double openingBalance;
  final int paymentTermsDays;
  final double totalPurchaseAmount;
  final String? lastPurchaseAt;
  final bool isActive;

  factory StaffSupplier.fromJson(Map<String, Object?> row) {
    return StaffSupplier(
      id: asString(row['id']),
      name: asString(row['name']),
      contactPerson: asNullableString(row['contact_person']),
      phone: asNullableString(row['phone']),
      email: asNullableString(row['email']),
      notes: asNullableString(row['notes']),
      currentBalance: asNumber(row['current_balance']),
      openingBalance: asNumber(row['opening_balance']),
      paymentTermsDays: asNumber(row['payment_terms_days']).round(),
      totalPurchaseAmount: asNumber(row['total_purchase_amount']),
      lastPurchaseAt: asNullableString(row['last_purchase_at']),
      isActive: asBoolean(row['is_active'], true),
    );
  }
}

class StaffPayment {
  const StaffPayment({
    required this.id,
    required this.amount,
    required this.paymentDirection,
    required this.paymentType,
    required this.method,
    required this.status,
    this.customerId,
    this.supplierId,
    this.customerName,
    this.supplierName,
    this.orderNo,
    this.purchaseInvoice,
    this.referenceNumber,
    this.notes,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final double amount;
  final String paymentDirection;
  final String paymentType;
  final String method;
  final String status;
  final String? customerId;
  final String? supplierId;
  final String? customerName;
  final String? supplierName;
  final String? orderNo;
  final String? purchaseInvoice;
  final String? referenceNumber;
  final String? notes;
  final String? paidAt;
  final String? createdAt;

  factory StaffPayment.fromJoin(Map<String, Object?> row) {
    final orders = asRecord(row['orders']);
    final suppliers = asRecord(row['suppliers']);
    final purchases = asRecord(row['purchase_orders']);
    final snapshot = asRecord(orders?['customer_snapshot']);
    final orderNumber = orders?['order_number'];
    return StaffPayment(
      id: asString(row['id']),
      amount: asNumber(row['amount']),
      paymentDirection: asString(row['payment_direction'], 'inflow'),
      paymentType: asString(row['payment_type'], 'sale'),
      method: asString(row['method'], 'cash'),
      status: asString(row['status'], 'pending'),
      customerId: asNullableString(row['customer_id']),
      supplierId: asNullableString(row['supplier_id']),
      customerName: asNullableString(snapshot?['name']),
      supplierName: asNullableString(suppliers?['name']),
      orderNo: orderNumber == null ? null : '#$orderNumber',
      purchaseInvoice: asNullableString(purchases?['invoice_number']),
      referenceNumber: asNullableString(row['reference_number']),
      notes: asNullableString(row['notes']),
      paidAt: asNullableString(row['paid_at']),
      createdAt: asNullableString(row['created_at']),
    );
  }

  factory StaffPayment.fromJson(Map<Object?, Object?> json) {
    final map = json.map((Object? k, Object? v) => MapEntry('$k', v));
    return StaffPayment.fromJoin(map);
  }
}

class CustomerSettlementInput {
  const CustomerSettlementInput({
    required this.customerId,
    required this.amount,
    required this.method,
    this.notes,
  });

  final String customerId;
  final double amount;
  final String method;
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
        'customer_id': customerId,
        'amount': amount,
        'method': method,
        'notes': notes,
      };
}

class SupplierSettlementInput {
  const SupplierSettlementInput({
    required this.supplierId,
    required this.amount,
    required this.method,
    this.notes,
    this.referenceNumber,
  });

  final String supplierId;
  final double amount;
  final String method;
  final String? notes;
  final String? referenceNumber;

  Map<String, Object?> toJson() => <String, Object?>{
        'supplier_id': supplierId,
        'amount': amount,
        'method': method,
        'notes': notes,
        'reference_number': referenceNumber,
      };
}

class SaveSupplierInput {
  const SaveSupplierInput({
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.notes,
    this.openingBalance,
    this.paymentTermsDays,
    this.isActive,
  });

  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? notes;
  final double? openingBalance;
  final int? paymentTermsDays;
  final bool? isActive;

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name.trim(),
        if (contactPerson != null) 'contact_person': contactPerson,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (notes != null) 'notes': notes,
        if (openingBalance != null) 'opening_balance': openingBalance,
        if (paymentTermsDays != null) 'payment_terms_days': paymentTermsDays,
        if (isActive != null) 'is_active': isActive,
      };
}
