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
import 'package:medi_app/data/models/customer_order.dart';
import 'package:medi_app/features/account/customer_auth.dart';

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
    return 'orders-token';
  }
}

class OrdersApi implements AppWriteApi {
  OrdersApi(this.orders);

  List<CustomerOrderListItem> orders;
  CustomerOrderDetail? detail;
  int listCalls = 0;
  int cancelCalls = 0;

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
    throw UnimplementedError();
  }

  @override
  Future<PlaceOnlineOrderResult> placeOrder({
    required String idToken,
    required PlaceOnlineOrderInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerOrderListItem>> listOrders({
    required String idToken,
  }) async {
    listCalls++;
    return orders;
  }

  @override
  Future<CustomerOrderDetail> getOrder({
    required String idToken,
    required String orderId,
  }) async {
    return detail ??
        CustomerOrderDetail(
          id: orderId,
          orderNumber: 42,
          storeId: 'a',
          storeName: 'Alpha',
          storeSlug: 'alpha',
          status: 'pending',
          paymentMethod: 'cod',
          fulfillmentType: 'delivery',
          totalAmount: 68,
          placedAt: '2026-11-04T10:00:00.000Z',
          canCancel: true,
          items: const <CustomerOrderLine>[
            CustomerOrderLine(
              id: 'li-1',
              name: 'Dolo 650',
              quantity: 2,
              unitPrice: 34,
              totalPrice: 68,
            ),
          ],
        );
  }

  @override
  Future<CustomerOrderDetail> cancelOrder({
    required String idToken,
    required String orderId,
  }) async {
    cancelCalls++;
    final current = await getOrder(idToken: idToken, orderId: orderId);
    detail = CustomerOrderDetail(
      id: current.id,
      orderNumber: current.orderNumber,
      storeId: current.storeId,
      storeName: current.storeName,
      storeSlug: current.storeSlug,
      status: 'cancelled',
      paymentMethod: current.paymentMethod,
      fulfillmentType: current.fulfillmentType,
      totalAmount: current.totalAmount,
      placedAt: current.placedAt,
      canCancel: false,
      items: current.items,
    );
    orders = orders
        .map(
          (CustomerOrderListItem item) => item.id == orderId
              ? CustomerOrderListItem(
                  id: item.id,
                  orderNumber: item.orderNumber,
                  storeId: item.storeId,
                  storeName: item.storeName,
                  storeSlug: item.storeSlug,
                  itemCount: item.itemCount,
                  totalAmount: item.totalAmount,
                  status: 'cancelled',
                  placedAt: item.placedAt,
                  canCancel: false,
                )
              : item,
        )
        .toList();
    return detail!;
  }
}

class SeededSession extends CustomerSessionController {
  SeededSession(this.seed);

  final CustomerSessionState seed;

  @override
  CustomerSessionState build() => seed;
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('guest orders is empty until Sign in is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(router: createAppRouter(initialLocation: '/orders')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Orders'), findsOneWidget);
    expect(find.text(t('STOREFRONT.ORDERS_EMPTY')), findsOneWidget);
    expect(find.text(t('STOREFRONT.ORDERS_SIGN_IN')), findsOneWidget);
    expect(find.byKey(const Key('otp-stub-title')), findsNothing);

    await tester.tap(find.byKey(const Key('orders-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('otp-stub-title')), findsOneWidget);

    await tester.tap(find.text(t('STOREFRONT.CLOSE_DRAWER')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('orders-empty')), findsOneWidget);

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Cart'), findsOneWidget);
  });

  testWidgets('signed-in list, detail, and cancel', (WidgetTester tester) async {
    final api = OrdersApi(<CustomerOrderListItem>[
      const CustomerOrderListItem(
        id: 'ord-1',
        orderNumber: 42,
        storeId: 'a',
        storeName: 'Alpha',
        storeSlug: 'alpha',
        itemCount: 1,
        totalAmount: 68,
        status: 'pending',
        placedAt: '2026-11-04T10:00:00.000Z',
        canCancel: true,
      ),
    ]);
    final tokens = MemoryTokenStore();
    await tokens.write('orders-token');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appWriteApiProvider.overrideWithValue(api),
          customerAuthProvider.overrideWithValue(FakeAuth()),
          authTokenStoreProvider.overrideWithValue(tokens),
          customerSessionProvider.overrideWith(
            () => SeededSession(
              const CustomerSessionState(
                profile: CustomerProfile(
                  customerId: 'cust-1',
                  phone: '9876543210',
                ),
                idToken: 'orders-token',
              ),
            ),
          ),
        ],
        child: MediApp(router: createAppRouter(initialLocation: '/orders')),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.listCalls, 1);
    expect(find.byKey(const Key('orders-list')), findsOneWidget);
    expect(find.textContaining('#42'), findsOneWidget);
    expect(find.textContaining(t('STOREFRONT.STATUS_PENDING')), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-row-ord-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-detail-number')), findsOneWidget);
    expect(find.text('Dolo 650'), findsOneWidget);
    expect(find.byKey(const Key('order-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-cancel-confirm')));
    await tester.pumpAndSettle();

    expect(api.cancelCalls, 1);
    expect(find.text(t('STOREFRONT.ORDER_CANCELLED')), findsOneWidget);
    expect(find.byKey(const Key('order-cancel')), findsNothing);
    expect(find.textContaining(t('STOREFRONT.STATUS_CANCELLED')), findsOneWidget);
  });
}
