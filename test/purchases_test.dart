import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/models/purchase.dart';
import 'package:medi_app/features/staff/purchases/purchases_controller.dart';
import 'package:medi_app/features/staff/purchases/purchases_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('calculatePurchaseTotals matches line net + tax', () {
    final totals = calculatePurchaseTotals(
      items: const <PurchaseItemInput>[
        PurchaseItemInput(
          storeProductId: 'sp-1',
          batchNumber: 'B1',
          quantity: 10,
          purchasePrice: 5,
          mrp: 8,
          sellingPrice: 7,
          taxPercent: 10,
        ),
      ],
      discountAmount: 5,
    );

    expect(totals.subtotal, 50);
    expect(totals.taxAmount, 5);
    expect(totals.grandTotal, 50);
  });

  test('SavePurchaseInput serializes completed payload', () {
    final json = SavePurchaseInput(
      supplierId: '11111111-1111-1111-1111-111111111111',
      invoiceNumber: 'INV-1',
      invoiceDate: '2026-11-05',
      items: const <PurchaseItemInput>[
        PurchaseItemInput(
          storeProductId: '22222222-2222-2222-2222-222222222222',
          batchNumber: 'B1',
          quantity: 150,
          purchasePrice: 2,
          mrp: 3,
          sellingPrice: 2.8,
        ),
      ],
      subtotal: 300,
      grandTotal: 300,
      paymentStatus: 'paid',
      paidAmount: 300,
      dueAmount: 0,
      status: 'completed',
      paymentMethod: 'cash',
    ).toJson();

    expect(json['status'], 'completed');
    expect(json['items'], hasLength(1));
    expect((json['items'] as List).first['quantity'], 150);
  });

  testWidgets('purchases page lists invoices', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchasesListProvider.overrideWith(_IdlePurchasesController.new),
        ],
        child: const MaterialApp(home: PurchasesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.PURCHASES_TITLE')), findsOneWidget);
    expect(find.text('INV-100'), findsOneWidget);
    expect(find.text(t('STORE_FORM.ADD_PURCHASE')), findsWidgets);
  });

  testWidgets('purchases route replaces stub', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchasesListProvider.overrideWith(_IdlePurchasesController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffPurchases),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PurchasesPage), findsOneWidget);
  });
}

class _IdlePurchasesController extends PurchasesListController {
  @override
  PurchasesListState build() {
    return const PurchasesListState(
      items: <PurchaseListItem>[
        PurchaseListItem(
          id: 'po-1',
          supplierId: 's1',
          supplierName: 'Local Wholesaler',
          invoiceNumber: 'INV-100',
          invoiceDate: '2026-11-05',
          grandTotal: 300,
          status: 'completed',
          paymentStatus: 'paid',
          itemCount: 1,
        ),
      ],
    );
  }
}
