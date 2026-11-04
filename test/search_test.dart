import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/features/location/store_resolver.dart';
import 'package:medi_app/features/storefront/catalog_controller.dart';
import 'package:medi_app/features/storefront/product_card.dart';

import 'nearby_fixtures.dart';

ListingCard _card(Map<String, Object?> row) => parseListingCard(row)!;

class RecordingCatalog implements CatalogSource {
  RecordingCatalog({
    this.shell = StoreShellPayload.empty,
    this.hits = const <ListingCard>[],
    this.products = const <String, ListingCard>{},
  });

  StoreShellPayload shell;
  List<ListingCard> hits;
  Map<String, ListingCard> products;
  final List<({String query, String? categoryId, int limit})> calls =
      <({String query, String? categoryId, int limit})>[];

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
    calls.add((query: query, categoryId: categoryId, limit: limit));
    return hits;
  }

  @override
  Future<ListingCard?> getStoreProduct({
    required String storeId,
    required String slug,
  }) async {
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

class SeededActiveShop extends ActiveShopController {
  SeededActiveShop(this.initial);

  final ActiveShop? initial;

  @override
  ActiveShop? build() => initial;
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  final dolo = _card(<String, Object?>{
    'id': 'sp-1',
    'slug': 'dolo-650',
    'name': 'Dolo 650',
    'generic_name': 'Paracetamol',
    'pack_label': 'Strip of 15',
    'selling_price': 34,
    'mrp': 40,
    'schedule': 'h',
    'category_id': 'c1',
    'available_quantity': 12,
  });

  final shell = StoreShellPayload(
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

  Future<void> pumpSearch(
    WidgetTester tester, {
    required RecordingCatalog catalog,
    ActiveShop? shop,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogSourceProvider.overrideWithValue(catalog),
          activeShopProvider.overrideWith(() => SeededActiveShop(shop)),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: '/search'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('search constants', () {
    expect(kSearchDebounce, const Duration(milliseconds: 250));
    expect(kSearchMinChars, 2);
    expect(kSearchLimit, 20);
    expect(
      searchQueryKey(storeId: 'a', query: 'dolo', categoryId: null),
      <Object?>['search', 'a', 'dolo', null],
    );
  });

  testWidgets('empty query shows hint and does not call RPC', (
    WidgetTester tester,
  ) async {
    final catalog = RecordingCatalog(shell: shell, hits: <ListingCard>[dolo]);
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha', name: 'Alpha'),
    );

    expect(find.widgetWithText(AppBar, 'Search'), findsOneWidget);
    expect(find.text(t('STOREFRONT.SEARCH_START')), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
    expect(catalog.calls, isEmpty);
    expect(find.textContaining('Sign in'), findsNothing);
  });

  testWidgets('one character after debounce still does not search', (
    WidgetTester tester,
  ) async {
    final catalog = RecordingCatalog(shell: shell, hits: <ListingCard>[dolo]);
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha'),
    );

    await tester.enterText(find.byKey(const Key('shop-search-field')), 'd');
    await tester.pump(kSearchDebounce);
    await tester.pump();

    expect(find.text(t('STOREFRONT.SEARCH_START')), findsOneWidget);
    expect(catalog.calls, isEmpty);
  });

  testWidgets('debounce 250ms then new RPC, 1-column results', (
    WidgetTester tester,
  ) async {
    final catalog = RecordingCatalog(shell: shell, hits: <ListingCard>[dolo]);
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha'),
    );

    await tester.enterText(find.byKey(const Key('shop-search-field')), 'd');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('shop-search-field')), 'do');
    await tester.pump(kSearchDebounce);
    await tester.pumpAndSettle();

    expect(catalog.calls.length, 1);
    expect(catalog.calls.single.query, 'do');
    expect(catalog.calls.single.categoryId, isNull);
    expect(catalog.calls.single.limit, 20);
    expect(find.byKey(const Key('search-results')), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text(t('STOREFRONT.REQUIRES_RX')), findsOneWidget);
  });

  testWidgets('RPC hits are shown even if they do not match the typed letters', (
    WidgetTester tester,
  ) async {
    final catalog = RecordingCatalog(shell: shell, hits: <ListingCard>[dolo]);
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha'),
    );

    await tester.enterText(find.byKey(const Key('shop-search-field')), 'zz');
    await tester.pump(kSearchDebounce);
    await tester.pumpAndSettle();

    expect(catalog.calls.single.query, 'zz');
    expect(find.text('Dolo 650'), findsOneWidget);
  });

  testWidgets('empty RPC result shows empty copy', (WidgetTester tester) async {
    final catalog = RecordingCatalog(shell: shell);
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha'),
    );

    await tester.enterText(find.byKey(const Key('shop-search-field')), 'xy');
    await tester.pump(kSearchDebounce);
    await tester.pumpAndSettle();

    expect(find.text(t('STOREFRONT.SEARCH_EMPTY')), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('no resolved shop does not dump a catalog', (
    WidgetTester tester,
  ) async {
    final catalog = RecordingCatalog(hits: <ListingCard>[dolo]);
    await pumpSearch(tester, catalog: catalog);

    expect(
      find.text(t('STOREFRONT.MARKETPLACE_SEARCH_NEED_LOCATION')),
      findsOneWidget,
    );
    expect(catalog.calls, isEmpty);
  });

  testWidgets('category chip with empty query is a server search', (
    WidgetTester tester,
  ) async {
    final catalog = RecordingCatalog(shell: shell, hits: <ListingCard>[dolo]);
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha'),
    );

    await tester.tap(find.text('Tablets'));
    await tester.pumpAndSettle();

    expect(catalog.calls, isNotEmpty);
    expect(catalog.calls.last.query, '');
    expect(catalog.calls.last.categoryId, 'c1');
    expect(find.text('Dolo 650'), findsOneWidget);
  });

  testWidgets('tap result opens PDP', (WidgetTester tester) async {
    final catalog = RecordingCatalog(
      shell: shell,
      hits: <ListingCard>[dolo],
      products: <String, ListingCard>{'dolo-650': dolo},
    );
    await pumpSearch(
      tester,
      catalog: catalog,
      shop: const ActiveShop(storeId: 'a', slug: 'alpha'),
    );

    await tester.enterText(find.byKey(const Key('shop-search-field')), 'do');
    await tester.pump(kSearchDebounce);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dolo 650'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-page')), findsOneWidget);
    expect(find.textContaining('Paracetamol'), findsWidgets);
  });

}
