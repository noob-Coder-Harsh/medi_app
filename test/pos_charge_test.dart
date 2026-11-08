import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/data/models/catalog_product.dart';
import 'package:medi_app/data/models/inventory_batch.dart';
import 'package:medi_app/data/models/pos_checkout.dart';
import 'package:medi_app/data/models/purchase.dart';
import 'package:medi_app/data/models/staff_books.dart';
import 'package:medi_app/data/models/staff_order.dart';
import 'package:medi_app/data/models/staff_return.dart';
import 'package:medi_app/data/models/staff_store.dart';
import 'package:medi_app/data/staff_api_client.dart';
import 'package:medi_app/features/staff/pos/pos_cart_controller.dart';
import 'package:medi_app/features/staff/pos/pos_charge_sheet.dart';
import 'package:medi_app/features/staff/pos/pos_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

PosProduct _tablet({double stock = 100}) {
  return PosProduct(
    storeProductId: '11111111-1111-1111-1111-111111111111',
    name: 'Dolo 650',
    stockCount: stock,
    unitPrice: 2,
    salePolicy: 'loose_allowed',
    baseUnit: 'tablet',
    primaryPackType: 'strip',
    primaryPackQuantity: 15,
  );
}

class _FakeStaffApi implements StaffWriteApi {
  int ensureCalls = 0;
  int checkoutCalls = 0;

  @override
  Future<PosCheckoutResult> checkout({
    required String accessToken,
    required PosCheckoutInput input,
  }) async {
    checkoutCalls += 1;
    return const PosCheckoutResult(
      orderId: 'ord-1',
      orderNumber: 7,
      totalAmount: 30,
      paymentMethod: 'cash',
      customerPhone: '+919876543210',
    );
  }

  @override
  Future<PosCustomerCard> ensureCustomer({
    required String accessToken,
    required String phone,
  }) async {
    ensureCalls += 1;
    return PosCustomerCard(customerId: 'cust-1', phone: phone);
  }

  @override
  Future<PosCustomerCard?> lookupCustomer({
    required String accessToken,
    required String phone,
  }) async {
    return null;
  }

  @override
  Future<List<PosRecentSale>> recentSales({required String accessToken}) async {
    return const <PosRecentSale>[];
  }

  @override
  Future<CatalogWriteResult> addCatalogProduct({
    required String accessToken,
    required String productId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CatalogWriteResult> createCustomCatalogProduct({
    required String accessToken,
    required CreateCustomProductInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateStoreProduct({
    required String accessToken,
    required String storeProductId,
    required UpdateStoreProductInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InventoryBatch> addProductBatch({
    required String accessToken,
    required String storeProductId,
    required OpeningBatchInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InventoryBatch> updateProductBatch({
    required String accessToken,
    required String storeProductId,
    required String batchId,
    required Map<String, Object?> patch,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SupplierOption> createSupplier({
    required String accessToken,
    required String name,
    String? phone,
    String? contactPerson,
    String? notes,
    double? openingBalance,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffSupplier> updateSupplier({
    required String accessToken,
    required String supplierId,
    required SaveSupplierInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffSupplier> setSupplierActive({
    required String accessToken,
    required String supplierId,
    required bool isActive,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseDetail> createPurchase({
    required String accessToken,
    required SavePurchaseInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffCustomer> ensureStoreCustomer({
    required String accessToken,
    required String phone,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffCustomer> updateStoreCustomer({
    required String accessToken,
    required String storeCustomerId,
    String? notes,
    int? loyaltyPoints,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffPayment> settleCustomerPayment({
    required String accessToken,
    required CustomerSettlementInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffPayment> settleSupplierPayment({
    required String accessToken,
    required SupplierSettlementInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffOrderDetail> updateOrderStatus({
    required String accessToken,
    required String orderId,
    required String toStatus,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffReturnDetail> createReturn({
    required String accessToken,
    required CreateReturnInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffReturnDetail> approveReturn({
    required String accessToken,
    required String returnId,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffReturnDetail> rejectReturn({
    required String accessToken,
    required String returnId,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffStore> updateStore({
    required String accessToken,
    required UpdateStoreInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StoreImageUploadResult> uploadStoreImage({
    required String accessToken,
    required String kind,
    required List<int> bytes,
    required String filename,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile({
    required String accessToken,
    required UpdateProfileInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> attachCategories({
    required String accessToken,
    required List<String> categoryIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> detachCategories({
    required String accessToken,
    required List<String> categoryIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffCategory> createCategory({
    required String accessToken,
    required String name,
    String? slug,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StaffCategory> updateCategory({
    required String accessToken,
    required String categoryId,
    String? name,
    bool? isActive,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('PosCheckoutResult parses nested order detail', () {
    final result = PosCheckoutResult.fromJson(<Object?, Object?>{
      'order': <Object?, Object?>{
        'order': <Object?, Object?>{
          'id': 'o1',
          'order_number': 12,
          'total_amount': 99.5,
          'payment_method': 'upi',
          'customer_snapshot': <Object?, Object?>{'phone': '+9198'},
          'placed_at': '2026-01-01T10:00:00Z',
        },
      },
    });
    expect(result.orderId, 'o1');
    expect(result.orderNumber, 12);
    expect(result.totalAmount, 99.5);
    expect(result.paymentMethod, 'upi');
    expect(result.customerPhone, '+9198');
  });

  testWidgets('charge validates empty cart in red', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  onPressed: () => showPosChargeSheet(context),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining(t('CHROME.CHARGE')).last);
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.POS_VALIDATION_CART')), findsOneWidget);
  });

  testWidgets('charge validates missing phone in red', (WidgetTester tester) async {
    final api = _FakeStaffApi();
    final container = ProviderContainer(
      overrides: [staffWriteApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    container.read(posCartProvider.notifier).addProduct(_tablet());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  onPressed: () => showPosChargeSheet(context),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining(t('CHROME.CHARGE')).last);
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.POS_VALIDATION_CUSTOMER')), findsOneWidget);
    expect(api.ensureCalls, 0);
    expect(api.checkoutCalls, 0);
  });

  testWidgets('charge validates oversell stock in red', (WidgetTester tester) async {
    final api = _FakeStaffApi();
    final container = ProviderContainer(
      overrides: [staffWriteApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    // Pack add = 15; stock only 10 → oversell.
    container.read(posCartProvider.notifier).addProduct(_tablet(stock: 10));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  onPressed: () => showPosChargeSheet(context),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pos-checkout-phone')),
      '9876543210',
    );
    await tester.pump();
    await tester.tap(find.textContaining(t('CHROME.CHARGE')).last);
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.POS_VALIDATION_STOCK')), findsOneWidget);
    expect(api.checkoutCalls, 0);
  });
}
