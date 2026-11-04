import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/data/api_client.dart';
import 'package:medi_app/data/local/auth_token_store.dart';
import 'package:medi_app/data/models/checkout.dart';
import 'package:medi_app/data/models/listing.dart';
import 'package:medi_app/data/rpc/listing_rpc.dart';
import 'package:medi_app/data/models/local_cart.dart';
import 'package:medi_app/features/account/customer_auth.dart';
import 'package:medi_app/features/cart/cart_controller.dart';
import 'package:medi_app/features/location/store_resolver.dart';
import 'package:medi_app/features/storefront/store_home_controller.dart';

import 'nearby_fixtures.dart';

class SeededCart extends CartController {
  SeededCart(this.seed);

  final LocalCart seed;

  @override
  LocalCart build() {
    return seed;
  }

  @override
  bool get isReady => true;
}

class MemoryTokenStore extends AuthTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

class FakeAuth implements CustomerAuth {
  @override
  Future<void> sendOtp(String phoneE164) async {}

  @override
  Future<String> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    return 'fake-id-token';
  }
}

class FakeWriteApi implements AppWriteApi {
  int revalidateCalls = 0;
  int placeCalls = 0;
  PlaceOnlineOrderInput? lastOrder;

  @override
  Future<CustomerProfile> ensureSession({required String idToken}) async {
    return const CustomerProfile(
      customerId: 'cust-1',
      phone: '9876543210',
      name: 'Guest',
    );
  }

  @override
  Future<RevalidateCartResult> revalidateCart({
    required String idToken,
    required String storeId,
    required List<RevalidateCartLineInput> items,
  }) async {
    revalidateCalls++;
    return RevalidateCartResult(
      storeId: storeId,
      lines: items
          .map(
            (RevalidateCartLineInput item) => RevalidatedCartLine(
              storeProductId: item.storeProductId,
              quantity: item.quantity,
              name: 'Dolo 650',
              unitPrice: 34,
              mrp: 40,
              stockCount: 12,
              isActive: true,
              ok: true,
            ),
          )
          .toList(),
      subtotal: 68,
      ok: true,
      messages: const <String>[],
    );
  }

  @override
  Future<PlaceOnlineOrderResult> placeOrder({
    required String idToken,
    required PlaceOnlineOrderInput input,
  }) async {
    placeCalls++;
    lastOrder = input;
    return const PlaceOnlineOrderResult(
      orderId: 'ord-1',
      storeId: 'a',
      orderNumber: 42,
      totalAmount: 68,
    );
  }
}

class FakeStoreHomeSource implements StoreHomeSource {
  FakeStoreHomeSource(this.payload);

  final StoreHomePayload payload;

  @override
  Future<StoreHomePayload> getStoreHome(String slug) async => payload;
}

class SeededNearbyShops extends NearbyShops {
  SeededNearbyShops(this.seed);

  final List<NearbyStore> seed;

  @override
  List<NearbyStore> build() => seed;
}

class SeededActiveShop extends ActiveShopController {
  SeededActiveShop(this.seed);

  final ActiveShop? seed;

  @override
  ActiveShop? build() => seed;
}

StoreHomePayload _home(NearbyStore shop) {
  return StoreHomePayload(
    status: StoreShellStatus.ok,
    store: shop.store,
    categories: const <Category>[],
    featured: const <ListingCard>[],
    products: const <ListingCard>[],
  );
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('guest place order: OTP then revalidate then order', (
    WidgetTester tester,
  ) async {
    final api = FakeWriteApi();
    final tokens = MemoryTokenStore();
    final shop = nearbyShop(
      id: 'a',
      slug: 'alpha',
      name: 'Alpha',
      whatsappNumber: '9876543210',
    );
    const cart = LocalCart(
      storeId: 'a',
      items: <CartLine>[
        CartLine(storeProductId: 'sp-1', quantity: 2),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appWriteApiProvider.overrideWithValue(api),
          customerAuthProvider.overrideWithValue(FakeAuth()),
          authTokenStoreProvider.overrideWithValue(tokens),
          cartProvider.overrideWith(() => SeededCart(cart)),
          storeHomeSourceProvider.overrideWithValue(
            FakeStoreHomeSource(_home(shop)),
          ),
          nearbyShopsProvider.overrideWith(
            () => SeededNearbyShops(<NearbyStore>[shop]),
          ),
          activeShopProvider.overrideWith(
            () => SeededActiveShop(
              const ActiveShop(storeId: 'a', slug: 'alpha', name: 'Alpha'),
            ),
          ),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: '/checkout'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, t('CUSTOMER_CHECKOUT')), findsOneWidget);
    expect(find.byKey(const Key('checkout-place-order')), findsOneWidget);
    expect(find.text(t('STOREFRONT.PAYMENT_COD')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('checkout-address')), '12 Road');
    await tester.enterText(find.byKey(const Key('checkout-city')), 'Delhi');
    await tester.enterText(find.byKey(const Key('checkout-state')), 'DL');
    await tester.enterText(find.byKey(const Key('checkout-pincode')), '110001');

    await tester.tap(find.byKey(const Key('checkout-place-order')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('otp-stub-title')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('otp-phone')), '9876543210');
    await tester.tap(find.byKey(const Key('otp-send')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('otp-code')), '123456');
    await tester.tap(find.byKey(const Key('otp-verify')));
    await tester.pumpAndSettle();

    expect(api.revalidateCalls, 1);
    expect(api.placeCalls, 1);
    expect(api.lastOrder?.fulfillmentType, 'delivery');
    expect(api.lastOrder?.paymentMethod, 'cod');
    expect(api.lastOrder?.storeId, 'a');
    expect(find.byKey(const Key('checkout-success')), findsOneWidget);
    expect(find.text(t('STOREFRONT.ORDER_PLACED')), findsWidgets);

    expect(await tokens.read(), 'fake-id-token');
  });

  testWidgets('empty cart checkout copy', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(router: createAppRouter(initialLocation: '/checkout')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-empty')), findsOneWidget);
    expect(find.text(t('STOREFRONT.PLACE_ORDER')), findsNothing);
  });
}
