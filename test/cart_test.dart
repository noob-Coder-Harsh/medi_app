import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/format.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/data/local/cart_store.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/features/cart/cart_controller.dart';
import 'package:medi_app/features/cart/cart_hydrate.dart';
import 'package:medi_app/features/storefront/catalog_controller.dart';
import 'package:medi_app/features/storefront/product_card.dart';

ListingCard _card(Map<String, Object?> row) => parseListingCard(row)!;

ListingCard dolo({
  String id = 'sp-1',
  String storeId = 'a',
  double available = 12,
  String salePolicy = 'inherit',
  double? pack,
  String name = 'Dolo 650',
  double price = 34,
}) {
  return _card(<String, Object?>{
    'id': id,
    'store_id': storeId,
    'name': name,
    'available_quantity': available,
    'sale_policy': salePolicy,
    if (pack != null) 'primary_pack_quantity': pack,
    'kind': 'tablet_capsule',
    'selling_price': price,
    'pack_label': 'Strip of 15',
  });
}

class HydrateCatalog implements CatalogSource {
  HydrateCatalog(this.cards);

  List<ListingCard> cards;
  int calls = 0;
  List<String> lastIds = const <String>[];

  @override
  Future<StoreShellPayload> getStoreShell({
    String? slug,
    String? storeId,
  }) async {
    return StoreShellPayload.empty;
  }

  @override
  Future<List<ListingCard>> searchStoreCatalog({
    required String storeId,
    String query = '',
    String? categoryId,
    int limit = 20,
  }) async {
    return const <ListingCard>[];
  }

  @override
  Future<ListingCard?> getStoreProduct({
    required String storeId,
    required String slug,
  }) async {
    return null;
  }

  @override
  Future<List<ListingCard>> getListingCards({
    required String storeId,
    required List<String> ids,
  }) async {
    calls++;
    lastIds = List<String>.from(ids);
    return cards
        .where((ListingCard card) => ids.contains(card.id))
        .toList();
  }
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('cartStep follows sale policy', () {
    expect(cartStep(dolo()), 1);
    expect(
      cartStep(dolo(salePolicy: 'pack_only', pack: 15)),
      15,
    );
  });

  test('tryAdd writes prefs ids only and survives a new container', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    final result = await first.read(cartProvider.notifier).tryAdd(
      storeId: 'a',
      card: dolo(),
    );
    expect(result, CartAddResult.added);
    expect(first.read(cartProvider).storeId, 'a');
    expect(first.read(cartProvider).qtyOf('sp-1'), 1);
    expect(first.read(cartProvider).totalUnits, 1);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(CartStore.prefsKey);
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as Map;
    expect(decoded['storeId'], 'a');
    expect(decoded['items'], isA<List>());
    expect((decoded['items'] as List).single['storeProductId'], 'sp-1');
    expect(decoded.toString().contains('Dolo'), isFalse);

    final second = ProviderContainer();
    addTearDown(second.dispose);
    await second.read(cartProvider.notifier).tryAdd(
      storeId: 'a',
      card: dolo(),
    );
    expect(second.read(cartProvider).qtyOf('sp-1'), 2);
  });

  test('other shop needs confirm; replaceAndAdd swaps store', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(cartProvider.notifier).tryAdd(
      storeId: 'a',
      card: dolo(),
    );
    final blocked = await container.read(cartProvider.notifier).tryAdd(
      storeId: 'b',
      card: dolo(id: 'sp-2', storeId: 'b'),
    );
    expect(blocked, CartAddResult.needsConfirm);
    expect(container.read(cartProvider).storeId, 'a');

    await container.read(cartProvider.notifier).replaceAndAdd(
      storeId: 'b',
      card: dolo(id: 'sp-2', storeId: 'b'),
    );
    expect(container.read(cartProvider).storeId, 'b');
    expect(container.read(cartProvider).qtyOf('sp-1'), 0);
    expect(container.read(cartProvider).qtyOf('sp-2'), 1);
  });

  test('out of stock is blocked; pack step caps without advertising qty', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      await container.read(cartProvider.notifier).tryAdd(
        storeId: 'a',
        card: dolo(available: 0),
      ),
      CartAddResult.blocked,
    );

    await container.read(cartProvider.notifier).tryAdd(
      storeId: 'a',
      card: dolo(salePolicy: 'pack_only', pack: 10, available: 10),
    );
    expect(container.read(cartProvider).qtyOf('sp-1'), 10);
    await container.read(cartProvider.notifier).increase(
      dolo(salePolicy: 'pack_only', pack: 10, available: 10),
    );
    expect(container.read(cartProvider).qtyOf('sp-1'), 10);
  });

  testWidgets('Add shows stepper and cart badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProductCard(card: dolo(), storeId: 'a'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t('STOREFRONT.ADD_TO_CART')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qty-increase')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qty-increase')));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qty-decrease')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('adding from another shop asks to replace', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      CartStore.prefsKey: jsonEncode(<String, Object?>{
        'storeId': 'a',
        'items': <Object?>[
          <String, Object?>{'storeProductId': 'sp-1', 'quantity': 1},
        ],
      }),
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProductCard(
              card: dolo(id: 'sp-9', storeId: 'b'),
              storeId: 'b',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t('STOREFRONT.ADD_TO_CART')));
    await tester.pumpAndSettle();
    expect(find.text(t('STOREFRONT.MULTI_STORE_TITLE')), findsOneWidget);

    await tester.tap(find.text(t('STOREFRONT.MULTI_STORE_CANCEL')));
    await tester.pumpAndSettle();
    expect(
      jsonDecode((await SharedPreferences.getInstance()).getString(CartStore.prefsKey)!)
          as Map,
      containsPair('storeId', 'a'),
    );

    await tester.tap(find.text(t('STOREFRONT.ADD_TO_CART')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t('STOREFRONT.MULTI_STORE_CONFIRM')));
    await tester.pumpAndSettle();

    final decoded =
        jsonDecode((await SharedPreferences.getInstance()).getString(CartStore.prefsKey)!)
            as Map;
    expect(decoded['storeId'], 'b');
    expect((decoded['items'] as List).single['storeProductId'], 'sp-9');
  });

  testWidgets('cart tab badge survives a fresh shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      CartStore.prefsKey: jsonEncode(<String, Object?>{
        'storeId': 'a',
        'items': <Object?>[
          <String, Object?>{'storeProductId': 'sp-1', 'quantity': 3},
        ],
      }),
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: '/shop/foo'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Cart'), findsOneWidget);
  });

  test('cart cards query key sorts ids', () {
    expect(
      cartCardsQueryKey('a', <String>['sp-2', 'sp-1']),
      <Object>[
        'cart-cards',
        'a',
        <String>['sp-1', 'sp-2'],
      ],
    );
    expect(kCartCardsTtl, const Duration(seconds: 15));
  });

  testWidgets('empty cart copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(router: createAppRouter(initialLocation: '/cart')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Cart'), findsOneWidget);
    expect(find.text(t('STOREFRONT.CART_EMPTY')), findsOneWidget);
    expect(find.text(t('STOREFRONT.CART_EMPTY_HINT')), findsOneWidget);
    expect(find.byKey(const Key('cart-checkout')), findsNothing);
  });

  testWidgets('hydrated lines show name, qty, rupee; checkout is enabled', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      CartStore.prefsKey: jsonEncode(<String, Object?>{
        'storeId': 'a',
        'items': <Object?>[
          <String, Object?>{'storeProductId': 'sp-1', 'quantity': 2},
          <String, Object?>{'storeProductId': 'gone', 'quantity': 1},
        ],
      }),
    });
    final catalog = HydrateCatalog(<ListingCard>[
      dolo(price: 34, available: 12),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogSourceProvider.overrideWithValue(catalog),
        ],
        child: MediApp(router: createAppRouter(initialLocation: '/cart')),
      ),
    );
    await tester.pumpAndSettle();

    expect(catalog.calls, 1);
    expect(catalog.lastIds, <String>['gone', 'sp-1']);
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.text('Strip of 15'), findsOneWidget);
    expect(find.text(Format.stock(2)), findsOneWidget);
    expect(find.text(t('STOREFRONT.ITEM_UNAVAILABLE')), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal'))).data,
      Format.rupee(68),
    );
    expect(find.text(t('STOREFRONT.PLACE_ORDER')), findsNothing);
    expect(find.textContaining('Sign in'), findsNothing);

    await tester.tap(find.byKey(const Key('qty-increase')));
    await tester.pumpAndSettle();
    expect(catalog.calls, 1);
    expect(find.text(Format.stock(3)), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal'))).data,
      Format.rupee(102),
    );

    final checkout = tester.widget<FilledButton>(
      find.byKey(const Key('cart-checkout')),
    );
    expect(checkout.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('cart-checkout')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, t('CUSTOMER_CHECKOUT')), findsOneWidget);
  });

  test('cart card cache hits within 15s', () async {
    var calls = 0;
    final cache = CachedCartCards();
    Future<List<ListingCard>> fetch() async {
      calls++;
      return <ListingCard>[dolo()];
    }

    await cache.load(storeId: 'a', ids: <String>['sp-2', 'sp-1'], fetch: fetch);
    await cache.load(storeId: 'a', ids: <String>['sp-1', 'sp-2'], fetch: fetch);
    expect(calls, 1);
  });
}
