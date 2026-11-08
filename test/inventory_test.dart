import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/models/inventory_batch.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/features/staff/inventory/inventory_controller.dart';
import 'package:medi_app/features/staff/inventory/inventory_page.dart';
import 'package:medi_app/features/staff/medicines/medicines_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

ListingCard _card({
  String id = 'sp-1',
  String name = 'Dolo 650',
  double qty = 30,
}) {
  return ListingCard(
    id: id,
    storeId: 'store-1',
    productId: 'mp-1',
    slug: 'dolo-650',
    name: name,
    genericName: 'Paracetamol',
    manufacturer: 'Micro',
    composition: null,
    description: null,
    thumb: null,
    imageUrl: null,
    packLabel: 'Strip',
    baseUnit: 'tablet',
    primaryPackType: 'strip',
    primaryPackQuantity: 15,
    secondaryPackType: null,
    secondaryPackQuantity: null,
    dosageForm: 'tablet',
    strength: '650 mg',
    mrp: 30,
    sellingPrice: 28,
    unit: 'tablet',
    inStock: qty > 0,
    availableQuantity: qty,
    onHandQuantity: qty,
    reservedQuantity: 0,
    reorderLevel: 5,
    rackLocation: 'A1',
    salePolicy: 'loose_allowed',
    schedule: 'none',
    kind: 'tablet_capsule',
    categoryId: 'c1',
    categoryName: 'Fever',
    categorySlug: 'fever',
    isFeatured: false,
    isActive: true,
    requiresPrescription: false,
    gstRate: 5,
    hsnCode: null,
    trackBatch: true,
    storage: 'ambient',
    isSystem: true,
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('parseInventoryPage reads items + total', () {
    final page = parseInventoryPage(<Object?, Object?>{
      'items': <Object?>[
        <Object?, Object?>{
          'id': 'sp-1',
          'store_id': 's1',
          'product_id': 'p1',
          'slug': 'dolo',
          'name': 'Dolo 650',
          'available_quantity': 12,
          'on_hand_quantity': 12,
          'reserved_quantity': 0,
          'reorder_level': 0,
          'sale_policy': 'inherit',
          'schedule': 'none',
          'kind': 'tablet_capsule',
          'is_active': true,
          'is_featured': false,
          'requires_prescription': false,
          'track_batch': true,
          'storage': 'ambient',
          'is_system': true,
          'created_at': '',
          'updated_at': '',
          'pack_label': 'Unit',
        },
      ],
      'total': 1,
    });

    expect(page.total, 1);
    expect(page.items, hasLength(1));
    expect(page.items.first.name, 'Dolo 650');
  });

  test('OpeningBatchInput serializes base-unit quantity', () {
    final json = const OpeningBatchInput(
      batchNo: 'OPEN-1',
      mrp: 30,
      sellingPrice: 28,
      quantity: 150,
      purchasePrice: 20,
      expiresAt: '2027-01-31',
    ).toJson();

    expect(json['quantity'], 150);
    expect(json['batch_no'], 'OPEN-1');
    expect(json['expires_at'], '2027-01-31');
  });

  test('batchStatus marks near-expiry and zero stock', () {
    final now = DateTime(2026, 11, 5);
    final empty = InventoryBatch(
      id: 'b1',
      storeProductId: 'sp',
      mrp: 10,
      sellingPrice: 9,
      quantity: 10,
      availableQuantity: 0,
    );
    final soon = InventoryBatch(
      id: 'b2',
      storeProductId: 'sp',
      mrp: 10,
      sellingPrice: 9,
      quantity: 10,
      availableQuantity: 5,
      expiresAt: '2026-11-20',
    );

    expect(batchStatus(empty, now: now).tone, BatchStatusTone.slate);
    expect(batchStatus(soon, now: now).tone, BatchStatusTone.amber);
  });

  testWidgets('inventory page lists products from controller', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryListProvider.overrideWith(_IdleInventoryController.new),
        ],
        child: const MaterialApp(home: InventoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.PRODUCTS_TITLE')), findsOneWidget);
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.textContaining('In stock: 30'), findsOneWidget);
  });

  testWidgets('inventory route redirects to catalog', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryListProvider.overrideWith(_IdleInventoryController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffInventory),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MedicinesPage), findsOneWidget);
    expect(find.byType(InventoryPage), findsNothing);
  });
}

class _IdleInventoryController extends InventoryListController {
  @override
  InventoryListState build() {
    return InventoryListState(
      items: <ListingCard>[_card()],
      total: 1,
      offset: 1,
    );
  }
}
