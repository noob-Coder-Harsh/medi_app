import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/packaging.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/features/staff/pos/pos_cart_controller.dart';
import 'package:medi_app/features/staff/pos/pos_catalog_controller.dart';
import 'package:medi_app/features/staff/pos/pos_catalog_filter.dart';
import 'package:medi_app/features/staff/pos/pos_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

PosProduct _tablet({
  String id = 'p1',
  double stock = 100,
  double unitPrice = 2,
  double packQty = 15,
  bool requiresPrescription = false,
  String? categoryName,
}) {
  return PosProduct(
    storeProductId: id,
    name: 'Dolo 650',
    stockCount: stock,
    unitPrice: unitPrice,
    salePolicy: 'loose_allowed',
    baseUnit: 'tablet',
    primaryPackType: 'strip',
    primaryPackQuantity: packQty,
    requiresPrescription: requiresPrescription,
    categoryName: categoryName,
  );
}

PosProduct _syrup({String id = 's1', double stock = 20}) {
  return PosProduct(
    storeProductId: id,
    name: 'Cough Syrup',
    stockCount: stock,
    unitPrice: 1.5,
    salePolicy: 'inherit',
    baseUnit: 'ml',
    primaryPackType: 'bottle',
    primaryPackQuantity: 100,
  );
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('getPosAddQuantity adds a full strip for tablets', () {
    final packaging = PackagingInfo(
      baseUnit: 'tablet',
      primaryPackType: 'strip',
      primaryPackQuantity: 15,
    );
    expect(getPosAddQuantity(packaging), 15);
    expect(calculatePackPrice(2, packaging), 30);
    expect(formatPosPackMeta(packaging), '15 Tablets');
  });

  test('syrup sale step is whole bottle', () {
    final packaging = PackagingInfo(
      baseUnit: 'ml',
      primaryPackType: 'bottle',
      primaryPackQuantity: 100,
    );
    expect(getSaleStepQuantity('inherit', packaging), 100);
    expect(getPosAddQuantity(packaging), 100);
    expect(
      convertBaseToPackDisplay(200, packaging).display,
      contains('2'),
    );
  });

  test('pos cart accumulates pack qty and subtotal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(posCartProvider.notifier);

    cart.addProduct(_tablet());
    cart.addProduct(_tablet());
    expect(container.read(posCartProvider).single.quantity, 30);
    expect(cart.subtotal, 60);

    cart.bump('p1', increase: false);
    expect(container.read(posCartProvider).single.quantity, 29);

    cart.addProduct(_syrup());
    expect(container.read(posCartProvider), hasLength(2));
    expect(cart.quantityOf('s1'), 100);
  });

  test('zero stock products are not added', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(posCartProvider.notifier);
    cart.addProduct(_tablet(stock: 0));
    expect(container.read(posCartProvider), isEmpty);
  });

  test('putProduct sets absolute quantity', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(posCartProvider.notifier);
    cart.putProduct(_tablet(), 30);
    expect(container.read(posCartProvider).single.quantity, 30);
    cart.putProduct(_tablet(), 15);
    expect(container.read(posCartProvider).single.quantity, 15);
  });

  test('filterPosProducts applies All / Rx / OTC / category', () {
    final products = <PosProduct>[
      _tablet(id: 'rx1', requiresPrescription: true, categoryName: 'Health'),
      _tablet(id: 'otc1', requiresPrescription: false, categoryName: 'Health'),
      _tablet(id: 'otc2', requiresPrescription: false, categoryName: 'Wellness'),
    ];

    expect(filterPosProducts(products, PosCatalogFilter.all), hasLength(3));
    expect(
      filterPosProducts(products, PosCatalogFilter.rx).single.storeProductId,
      'rx1',
    );
    expect(filterPosProducts(products, PosCatalogFilter.otc), hasLength(2));
    expect(
      filterPosProducts(products, PosCatalogFilter.category('Health')),
      hasLength(2),
    );
    expect(
      posCategoryChipNames(products),
      <String>['Health', 'Wellness'],
    );
  });

  testWidgets('POS page shows filters; cart bar appears after add', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posCatalogProvider.overrideWith(_FakePosCatalog.new),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffPos),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.POS_TITLE')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<PosCatalogFilter>), findsOneWidget);
    expect(find.text(t('STORE_FORM.POS_FILTER_ALL')), findsOneWidget);
    expect(find.text(t('STORE_FORM.POS_CHECKOUT')), findsNothing);
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.text('Zero Stock Med'), findsOneWidget);
    expect(find.text('Out of Stock'), findsNothing);

    await tester.tap(find.text('Dolo 650'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('5'), findsWidgets);
    expect(find.text('10'), findsWidgets);
    expect(
      find.textContaining('${t('STORE_FORM.POS_ADD_TO_SALE')} ('),
      findsOneWidget,
    );

    await tester.tap(
      find.textContaining('${t('STORE_FORM.POS_ADD_TO_SALE')} ('),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(t('STORE_FORM.POS_CHECKOUT')), findsOneWidget);
    expect(find.textContaining(t('STORE_FORM.POS_ITEMS')), findsOneWidget);

    await tester.tap(find.textContaining(t('STORE_FORM.POS_CHECKOUT')));
    await tester.pumpAndSettle();
    expect(find.text(t('STORE_FORM.POS_TOTAL_AMOUNT')), findsWidgets);
    expect(find.text(t('STORE_FORM.POS_PAYABLE')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining(t('STORE_FORM.POS_ITEMS')));
    await tester.pumpAndSettle();
    expect(find.text(t('STORE_FORM.POS_CART')), findsWidgets);
    expect(find.text(t('STORE_FORM.POS_CLEAR_CART')), findsOneWidget);
  });

  testWidgets('POS category dropdown filters prescription products', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posCatalogProvider.overrideWith(_FakePosCatalog.new),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffPos),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<PosCatalogFilter>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('STORE_FORM.POS_FILTER_RX')).last);
    await tester.pumpAndSettle();
    expect(find.text('Rx Only Med'), findsOneWidget);
    expect(find.text('Dolo 650'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<PosCatalogFilter>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('STORE_FORM.POS_FILTER_OTC')).last);
    await tester.pumpAndSettle();
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.text('Rx Only Med'), findsNothing);
  });

  testWidgets('POS search bar is always visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posCatalogProvider.overrideWith(_FakePosCatalog.new),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffPos),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text(t('STORE_FORM.POS_SEARCH_PLACEHOLDER')),
      findsOneWidget,
    );
  });
}

class _FakePosCatalog extends PosCatalogController {
  @override
  PosCatalogState build() {
    return PosCatalogState(
      products: <PosProduct>[
        _tablet(categoryName: 'Health'),
        const PosProduct(
          storeProductId: 'rx1',
          name: 'Rx Only Med',
          stockCount: 40,
          unitPrice: 5,
          salePolicy: 'loose_allowed',
          requiresPrescription: true,
          categoryName: 'Health',
        ),
        const PosProduct(
          storeProductId: 'p0',
          name: 'Zero Stock Med',
          stockCount: 0,
          unitPrice: 1,
          salePolicy: 'loose_allowed',
        ),
      ],
    );
  }

  @override
  void setQuery(String raw) {
    state = state.copyWith(query: raw);
  }

  @override
  Future<void> loadHome() async {}

  @override
  Future<void> search(String query) async {}
}
