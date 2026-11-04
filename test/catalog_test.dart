import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/features/storefront/catalog_controller.dart';
import 'package:medi_app/features/storefront/product_card.dart';

import 'nearby_fixtures.dart';

ListingCard card(Map<String, Object?> row) => parseListingCard(row)!;

class FakeCatalogSource implements CatalogSource {
  FakeCatalogSource({
    required this.shell,
    this.search = const <ListingCard>[],
    this.products = const <String, ListingCard>{},
  });

  StoreShellPayload shell;
  List<ListingCard> search;
  Map<String, ListingCard> products;
  int searchCalls = 0;
  String? lastQuery;
  String? lastCategoryId;
  int lastLimit = 0;
  String? lastProductSlug;

  @override
  Future<StoreShellPayload> getStoreShell({
    String? slug,
    String? storeId,
  }) async {
    return shell;
  }

  @override
  Future<List<ListingCard>> searchStoreCatalog({
    required String storeId,
    String query = '',
    String? categoryId,
    int limit = 20,
  }) async {
    searchCalls++;
    lastQuery = query;
    lastCategoryId = categoryId;
    lastLimit = limit;
    return search.take(limit).toList();
  }

  @override
  Future<ListingCard?> getStoreProduct({
    required String storeId,
    required String slug,
  }) async {
    lastProductSlug = slug;
    return products[slug];
  }

  @override
  Future<List<ListingCard>> getListingCards({
    required String storeId,
    required List<String> ids,
  }) async {
    return const <ListingCard>[];
  }
}

StoreShellPayload alphaShell() {
  return StoreShellPayload(
    status: StoreShellStatus.ok,
    store: nearbyShop(id: 'a', slug: 'alpha', name: 'Alpha').store,
    categories: const <Category>[
      Category(
        id: 'c1',
        name: 'Tablets',
        slug: 'tablets',
        iconUrl: null,
        sortOrder: 0,
        isSystem: true,
        isActive: true,
        createdAt: '',
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('search and product query keys', () {
    expect(
      searchQueryKey(storeId: 'a', query: '', categoryId: 'c1'),
      <Object?>['search', 'a', '', 'c1'],
    );
    expect(productQueryKey('a', 'dolo-650'), <Object>['product', 'a', 'dolo-650']);
    expect(kCategoryPageSize, 24);
    expect(kRelatedLimit, 8);
  });

  Future<void> pumpPath(
    WidgetTester tester, {
    required String location,
    required FakeCatalogSource catalog,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogSourceProvider.overrideWithValue(catalog),
        ],
        child: MediApp(router: createAppRouter(initialLocation: location)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('category grid uses search_store_catalog, not a home dump', (
    WidgetTester tester,
  ) async {
    final catalog = FakeCatalogSource(
      shell: alphaShell(),
      search: <ListingCard>[
        card(<String, Object?>{
          'id': 'sp-2',
          'slug': 'crocin',
          'name': 'Crocin',
          'generic_name': 'Paracetamol',
          'pack_label': 'Strip of 10',
          'selling_price': 20,
          'mrp': 25,
          'category_id': 'c1',
          'available_quantity': 4,
        }),
        card(<String, Object?>{
          'id': 'sp-3',
          'slug': 'cetirizine',
          'name': 'Cetirizine',
          'generic_name': 'Cetirizine HCl',
          'pack_label': 'Strip of 10',
          'selling_price': 12,
          'category_id': 'c1',
          'available_quantity': 0,
        }),
      ],
    );

    await pumpPath(
      tester,
      location: '/shop/alpha/category/tablets',
      catalog: catalog,
    );

    expect(find.text('Tablets'), findsWidgets);
    expect(find.byKey(const Key('category-grid')), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(find.text('Crocin'), findsOneWidget);
    expect(find.text('Cetirizine'), findsWidgets);
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.textContaining('Strip of 10'), findsWidgets);
    expect(find.text(t('STOREFRONT.REQUIRES_RX')), findsNothing);
    expect(find.text(t('STOREFRONT.OUT_OF_STOCK')), findsNothing);
    expect(find.text('0'), findsWidgets);
    expect(find.textContaining('47'), findsNothing);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(catalog.searchCalls, greaterThan(0));
    expect(catalog.lastQuery, '');
    expect(catalog.lastCategoryId, 'c1');
    expect(catalog.lastLimit, 24);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });

  testWidgets('empty aisle copy', (WidgetTester tester) async {
    await pumpPath(
      tester,
      location: '/shop/alpha/category/tablets',
      catalog: FakeCatalogSource(shell: alphaShell()),
    );

    expect(find.text(t('STOREFRONT.EMPTY_CATEGORY')), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('guest can open PDP from category', (WidgetTester tester) async {
    final dolo = card(<String, Object?>{
      'id': 'sp-1',
      'slug': 'dolo-650',
      'name': 'Dolo 650',
      'generic_name': 'Paracetamol',
      'description': 'For fever and pain',
      'pack_label': 'Strip of 15',
      'selling_price': 34,
      'mrp': 40,
      'schedule': 'h',
      'manufacturer': 'Micro Labs',
      'strength': '650 mg',
      'dosage_form': 'Tablet',
      'category_id': 'c1',
      'available_quantity': 12,
    });
    final related = card(<String, Object?>{
      'id': 'sp-2',
      'slug': 'crocin',
      'name': 'Crocin',
      'generic_name': 'Paracetamol',
      'pack_label': 'Strip of 10',
      'selling_price': 20,
      'category_id': 'c1',
      'available_quantity': 4,
    });

    final catalog = FakeCatalogSource(
      shell: alphaShell(),
      search: <ListingCard>[dolo, related],
      products: <String, ListingCard>{'dolo-650': dolo},
    );

    await pumpPath(
      tester,
      location: '/shop/alpha/category/tablets',
      catalog: catalog,
    );

    await tester.tap(find.text('Dolo 650'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-page')), findsOneWidget);
    expect(find.text('Dolo 650'), findsWidgets);
    expect(find.textContaining('Paracetamol'), findsWidgets);
    expect(find.textContaining('Strip of 15'), findsOneWidget);
    expect(find.textContaining('650 mg'), findsOneWidget);
    expect(find.text(t('STOREFRONT.REQUIRES_RX')), findsWidgets);
    expect(find.text('For fever and pain'), findsOneWidget);
    expect(find.textContaining('Micro Labs'), findsOneWidget);
    expect(find.text(t('STOREFRONT.RELATED')), findsOneWidget);
    expect(find.text('Crocin'), findsOneWidget);
    expect(catalog.lastProductSlug, 'dolo-650');
    expect(find.textContaining('Sign in'), findsNothing);
    expect(find.text(t('STOREFRONT.OUT_OF_STOCK')), findsNothing);
    expect(find.textContaining('on_hand'), findsNothing);
    expect(find.textContaining('HSN'), findsNothing);
  });

  testWidgets('PDP related drops self', (WidgetTester tester) async {
    final dolo = card(<String, Object?>{
      'id': 'sp-1',
      'slug': 'dolo-650',
      'name': 'Dolo 650',
      'category_id': 'c1',
      'selling_price': 34,
      'available_quantity': 3,
    });

    final catalog = FakeCatalogSource(
      shell: alphaShell(),
      search: <ListingCard>[dolo],
      products: <String, ListingCard>{'dolo-650': dolo},
    );

    await pumpPath(
      tester,
      location: '/shop/alpha/product/dolo-650',
      catalog: catalog,
    );

    expect(find.byKey(const Key('product-page')), findsOneWidget);
    expect(find.text(t('STOREFRONT.RELATED')), findsNothing);
    expect(find.text('Dolo 650'), findsWidgets);
  });
}
