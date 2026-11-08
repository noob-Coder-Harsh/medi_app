import '../../../core/packaging.dart';
import '../../../data/models/staff_order.dart';
import '../../../data/models/staff_store.dart';
import 'pos_product.dart';

class PosReceiptLine {
  const PosReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.mrp,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final double? mrp;

  double get mrpLine {
    final unitMrp = mrp;
    if (unitMrp == null || unitMrp <= 0) return lineTotal;
    return roundMoney(unitMrp * quantity);
  }
}

class PosReceiptSnapshot {
  const PosReceiptSnapshot({
    required this.storeName,
    required this.billNumber,
    required this.placedAt,
    required this.paymentMethod,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.totalPayable,
    this.storeAddressLines = const <String>[],
    this.gstin,
    this.drugLicense,
    this.customerPhone,
    this.customerName,
  });

  final String storeName;
  final List<String> storeAddressLines;
  final String? gstin;
  final String? drugLicense;
  final int billNumber;
  final DateTime placedAt;
  final String? customerPhone;
  final String? customerName;
  final String paymentMethod;
  final List<PosReceiptLine> lines;
  final double subtotal;
  final double discount;
  final double totalPayable;

  double get mrpSavings {
    var saved = 0.0;
    for (final line in lines) {
      final diff = roundMoney(line.mrpLine - line.lineTotal);
      if (diff > 0) saved += diff;
    }
    return roundMoney(saved);
  }

  static PosReceiptSnapshot fromCheckout({
    required StaffStore? store,
    required int billNumber,
    required DateTime placedAt,
    required String paymentMethod,
    required List<PosCartItem> items,
    required double discount,
    required double totalPayable,
    String? customerPhone,
    String? customerName,
  }) {
    final lines = items
        .map(
          (PosCartItem item) => PosReceiptLine(
            name: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.unitPrice,
            lineTotal: lineAmount(item.product.unitPrice, item.quantity),
            mrp: item.product.mrp,
          ),
        )
        .toList(growable: false);

    final subtotal = roundMoney(
      lines.fold<double>(0, (double sum, PosReceiptLine line) => sum + line.lineTotal),
    );

    return PosReceiptSnapshot(
      storeName: store?.name.trim().isNotEmpty == true
          ? store!.name.trim()
          : 'MediSync Store',
      storeAddressLines: _addressLines(store),
      gstin: _nullIfEmpty(store?.gstNumber),
      drugLicense: _nullIfEmpty(store?.drugLicenseNumber),
      billNumber: billNumber,
      placedAt: placedAt,
      customerPhone: customerPhone,
      customerName: customerName,
      paymentMethod: paymentMethod,
      lines: lines,
      subtotal: subtotal,
      discount: roundMoney(discount),
      totalPayable: roundMoney(totalPayable),
    );
  }

  static PosReceiptSnapshot fromOrder({
    required StaffStore? store,
    required StaffOrderDetail order,
  }) {
    final placed =
        DateTime.tryParse(order.placedAt)?.toLocal() ?? DateTime.now();
    final lines = order.items
        .map(
          (StaffOrderLine item) => PosReceiptLine(
            name: item.productName,
            quantity: item.quantity.toDouble(),
            unitPrice: item.unitPrice,
            lineTotal: item.totalPrice,
            mrp: item.mrp,
          ),
        )
        .toList(growable: false);

    return PosReceiptSnapshot(
      storeName: store?.name.trim().isNotEmpty == true
          ? store!.name.trim()
          : 'MediSync Store',
      storeAddressLines: _addressLines(store),
      gstin: _nullIfEmpty(store?.gstNumber),
      drugLicense: _nullIfEmpty(store?.drugLicenseNumber),
      billNumber: order.orderNumber,
      placedAt: placed,
      customerPhone: order.customerPhone.isEmpty ? null : order.customerPhone,
      customerName: order.customerName,
      paymentMethod: (order.paymentMethod ?? '').trim().isEmpty
          ? '—'
          : order.paymentMethod!.trim(),
      lines: lines,
      subtotal: roundMoney(order.subtotal),
      discount: roundMoney(order.discountAmount),
      totalPayable: roundMoney(order.totalAmount),
    );
  }

  static List<String> _addressLines(StaffStore? store) {
    if (store == null) return const <String>[];
    final lines = <String>[];
    final street = store.address?.trim();
    if (street != null && street.isNotEmpty) lines.add(street);

    final locality = <String>[
      if ((store.city ?? '').trim().isNotEmpty) store.city!.trim(),
      if ((store.state ?? '').trim().isNotEmpty) store.state!.trim(),
      if ((store.pincode ?? '').trim().isNotEmpty) store.pincode!.trim(),
    ];
    if (locality.isNotEmpty) lines.add(locality.join(', '));
    return lines;
  }

  static String? _nullIfEmpty(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
