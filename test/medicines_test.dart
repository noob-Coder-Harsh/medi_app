import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/packaging.dart';
import 'package:medi_app/core/packaging_constants.dart';
import 'package:medi_app/data/models/catalog_product.dart';
import 'package:medi_app/data/models/inventory_batch.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/models/staff_store.dart';
import 'package:medi_app/features/staff/inventory/inventory_controller.dart';
import 'package:medi_app/features/staff/medicines/medicines_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

ListingCard _card({
  String id = 'sp-1',
  String name = 'Adhair 2% Solution',
  double qty = 45,
}) {
  return ListingCard(
    id: id,
    storeId: 'store-1',
    productId: 'mp-1',
    slug: 'adhair-2',
    name: name,
    genericName: null,
    manufacturer: 'Torrent Pharmaceuticals Ltd',
    composition: null,
    description: null,
    thumb: null,
    imageUrl: null,
    packLabel: 'Bottle',
    baseUnit: 'ml',
    primaryPackType: 'bottle',
    primaryPackQuantity: 60,
    secondaryPackType: null,
    secondaryPackQuantity: null,
    dosageForm: 'Lotion',
    strength: '2% w/v',
    mrp: 240,
    sellingPrice: 220,
    unit: 'bottle',
    inStock: qty > 0,
    availableQuantity: qty,
    onHandQuantity: qty,
    reservedQuantity: 0,
    reorderLevel: 10,
    rackLocation: 'A1',
    salePolicy: 'loose_allowed',
    schedule: 'none',
    kind: 'other',
    categoryId: 'c1',
    categoryName: 'Medicines',
    categorySlug: 'medicines',
    isFeatured: false,
    isActive: true,
    requiresPrescription: false,
    gstRate: 12,
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

  test('CatalogProduct.fromRow maps join + Rx schedule', () {
    final product = CatalogProduct.fromRow(
      <String, Object?>{
        'id': 'p1',
        'name': 'Dolo 650',
        'category_id': 'c1',
        'generic_name': 'Paracetamol',
        'manufacturer': 'Micro',
        'strength': '650 mg',
        'dosage_form': 'tablet',
        'drug_schedule': 'h',
        'categories': <String, Object?>{'name': 'Fever'},
      },
      isInStore: false,
    );

    expect(product.name, 'Dolo 650');
    expect(product.categoryName, 'Fever');
    expect(product.requiresPrescription, isTrue);
    expect(product.subtitle, contains('tablet'));
  });

  test('CatalogWriteResult parses nested store_product / product', () {
    final result = CatalogWriteResult.fromJson(<Object?, Object?>{
      'store_product': <Object?, Object?>{
        'id': 'sp-9',
        'product_id': 'mp-9',
      },
      'product': <Object?, Object?>{
        'id': 'mp-9',
        'name': 'Custom Syrup',
      },
    });

    expect(result.storeProductId, 'sp-9');
    expect(result.productId, 'mp-9');
    expect(result.name, 'Custom Syrup');
  });

  test('CreateCustomProductInput omits empty optional fields', () {
    final json = const CreateCustomProductInput(
      categoryId: '11111111-1111-1111-1111-111111111111',
      name: '  My Syrup  ',
      genericName: '  ',
      manufacturer: 'Acme',
      requiresPrescription: true,
      openingBatch: OpeningBatchInput(
        batchNo: 'B001',
        mrp: 0,
        sellingPrice: 0,
        quantity: 1,
        purchasePrice: 0,
      ),
    ).toJson();

    expect(json['name'], 'My Syrup');
    expect(json['generic_name'], isNull);
    expect(json['manufacturer'], 'Acme');
    expect(json['requires_prescription'], isTrue);
    expect(json['opening_batch'], isA<Map<String, Object?>>());
    expect((json['opening_batch'] as Map)['batch_no'], 'B001');
  });

  test('CreateCustomProductInput includes packaging and opening batch', () {
    final json = const CreateCustomProductInput(
      categoryId: '11111111-1111-1111-1111-111111111111',
      name: 'Dolo 650',
      dosageForm: 'tablet',
      baseUnit: 'tablet',
      primaryPackType: 'strip',
      primaryPackQuantity: 10,
      openingBatch: OpeningBatchInput(
        batchNo: 'B010',
        mrp: 40,
        sellingPrice: 36,
        quantity: 150,
        purchasePrice: 30,
        manufacturedAt: '2025-01-01',
        expiresAt: '2027-01-01',
      ),
    ).toJson();

    expect(json['dosage_form'], 'tablet');
    expect(json['base_unit'], 'tablet');
    expect(json['primary_pack_type'], 'strip');
    expect(json['primary_pack_quantity'], 10);
    final batch = json['opening_batch'] as Map<String, Object?>;
    expect(batch['batch_no'], 'B010');
    expect(batch['quantity'], 150);
    expect(batch['mrp'], 40);
    expect(batch['selling_price'], 36);
    expect(batch['purchase_price'], 30);
    expect(batch['manufactured_at'], '2025-01-01');
    expect(batch['expires_at'], '2027-01-01');
  });

  test('packaging defaults map tablet syrup cream', () {
    final tablet = getPackagingDefaultsForDosageForm('tablet');
    expect(tablet.baseUnit, 'tablet');
    expect(tablet.primaryPackType, 'strip');
    expect(tablet.primaryPackQuantity, 10);
    expect(tablet.packQuantityEditable, isTrue);
    expect(tablet.allowedPackTypes, containsAll(<String>['strip', 'blister']));

    final syrup = getPackagingDefaultsForDosageForm('syrup');
    expect(syrup.baseUnit, 'bottle');
    expect(syrup.primaryPackType, 'bottle');
    expect(syrup.primaryPackQuantity, 1);
    expect(syrup.packQuantityEditable, isFalse);

    final cream = getPackagingDefaultsForDosageForm('cream');
    expect(cream.baseUnit, 'tube');
    expect(cream.primaryPackType, 'tube');
    expect(cream.packQuantityEditable, isFalse);
  });

  test('isPackQuantityEditable respects base unit and dosage', () {
    expect(isPackQuantityEditable('tablet', 'tablet'), isTrue);
    expect(isPackQuantityEditable('syrup', 'bottle'), isFalse);
    expect(isPackQuantityEditable('powder', 'piece'), isTrue);
  });

  test('formatPackLabel covers strip bottle and tube', () {
    expect(
      formatPackLabel(
        const PackagingInfo(
          baseUnit: 'tablet',
          primaryPackType: 'strip',
          primaryPackQuantity: 10,
        ),
      ),
      'Strip of 10 Tablets',
    );
    expect(
      formatPackLabel(
        const PackagingInfo(
          baseUnit: 'bottle',
          primaryPackType: 'bottle',
          primaryPackQuantity: 1,
        ),
      ),
      'Bottle',
    );
    expect(
      formatPackLabel(
        const PackagingInfo(
          baseUnit: 'tube',
          primaryPackType: 'tube',
          primaryPackQuantity: 1,
        ),
      ),
      'Tube',
    );
  });

  testWidgets('catalog page shows store products without tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryListProvider.overrideWith(_IdleInventoryController.new),
        ],
        child: const MaterialApp(
          home: MedicinesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.MEDICINES_TITLE')), findsOneWidget);
    expect(find.text(t('STORE_FORM.MEDICINES_PAGE_DESC')), findsNothing);
    expect(
      find.text(t('STORE_FORM.CATALOG_SEARCH_PLACEHOLDER')),
      findsOneWidget,
    );
    expect(find.text(t('STORE_FORM.ADD_PRODUCT')), findsWidgets);
    expect(find.text(t('STORE_FORM.QUICK_ADD_CATALOG')), findsNothing);
    expect(find.text(t('STORE_FORM.PRODUCTS_STORE_TAB')), findsNothing);
    expect(find.text(t('STORE_FORM.CATALOG_STAT_TOTAL')), findsOneWidget);
    expect(find.text('Adhair 2% Solution'), findsOneWidget);
    expect(find.text('Torrent Pharmaceuticals Ltd'), findsOneWidget);
    expect(find.textContaining('220'), findsOneWidget);
  });
}

class _IdleInventoryController extends InventoryListController {
  @override
  InventoryListState build() {
    return InventoryListState(
      items: <ListingCard>[_card()],
      total: 1,
      offset: 1,
      stats: const InventoryStats(
        total: 542,
        inStock: 498,
        lowStock: 32,
        outOfStock: 12,
      ),
      categories: const <StaffCategory>[
        StaffCategory(
          id: 'c1',
          name: 'Medicines',
          slug: 'medicines',
          isSystem: true,
          isActive: true,
          attached: true,
        ),
      ],
    );
  }
}
