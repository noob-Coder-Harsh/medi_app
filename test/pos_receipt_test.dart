import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/data/models/staff_store.dart';
import 'package:medi_app/features/staff/pos/pos_product.dart';
import 'package:medi_app/features/staff/pos/pos_receipt.dart';
import 'package:medi_app/features/staff/pos/pos_receipt_document.dart';

PosProduct _product({
  String name = 'Dolo 650',
  double unitPrice = 2,
  double? mrp = 3,
}) {
  return PosProduct(
    storeProductId: '11111111-1111-1111-1111-111111111111',
    name: name,
    stockCount: 100,
    unitPrice: unitPrice,
    mrp: mrp,
    salePolicy: 'loose_allowed',
    baseUnit: 'tablet',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await I18n.load();
  });

  test('snapshot totals, discount and MRP savings', () {
    final receipt = PosReceiptSnapshot.fromCheckout(
      store: const StaffStore(
        id: 's1',
        name: 'City Medicos',
        slug: 'city-medicos',
        address: '12 MG Road',
        city: 'Pune',
        state: 'MH',
        pincode: '411001',
        gstNumber: '27AAAAA0000A1Z5',
        drugLicenseNumber: 'MH-DL-123',
      ),
      billNumber: 42,
      placedAt: DateTime.utc(2026, 3, 15, 10, 30),
      paymentMethod: 'Cash',
      items: <PosCartItem>[
        PosCartItem(product: _product(), quantity: 10),
        PosCartItem(
          product: _product(name: 'Crocin', unitPrice: 5, mrp: 5),
          quantity: 2,
        ),
      ],
      discount: 5,
      totalPayable: 25,
      customerPhone: '+919876543210',
      customerName: 'Asha',
    );

    expect(receipt.storeName, 'City Medicos');
    expect(receipt.gstin, '27AAAAA0000A1Z5');
    expect(receipt.drugLicense, 'MH-DL-123');
    expect(receipt.storeAddressLines, <String>['12 MG Road', 'Pune, MH, 411001']);
    expect(receipt.subtotal, 30);
    expect(receipt.discount, 5);
    expect(receipt.totalPayable, 25);
    // 10 * (3-2) = 10; Crocin mrp==price so 0
    expect(receipt.mrpSavings, 10);
    expect(receipt.lines, hasLength(2));
    expect(receipt.lines.first.lineTotal, 20);
  });

  test('buildPdf returns non-empty thermal PDF bytes', () async {
    final receipt = PosReceiptSnapshot.fromCheckout(
      store: const StaffStore(
        id: 's1',
        name: 'City Medicos',
        slug: 'city-medicos',
        gstNumber: '27AAAAA0000A1Z5',
        drugLicenseNumber: 'MH-DL-123',
      ),
      billNumber: 7,
      placedAt: DateTime.utc(2026, 3, 15, 10, 30),
      paymentMethod: 'UPI',
      items: <PosCartItem>[
        PosCartItem(product: _product(), quantity: 4),
      ],
      discount: 0,
      totalPayable: 8,
      customerPhone: '9876543210',
    );

    final bytes = await PosReceiptDocument.buildPdf(receipt);
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
