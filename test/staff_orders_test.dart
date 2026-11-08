import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/models/staff_order.dart';
import 'package:medi_app/data/models/staff_return.dart';
import 'package:medi_app/features/staff/orders/orders_controller.dart';
import 'package:medi_app/features/staff/orders/orders_page.dart';
import 'package:medi_app/features/staff/returns/returns_controller.dart';
import 'package:medi_app/features/staff/returns/returns_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('nextOrderStatuses allows ready and delivered paths', () {
    expect(nextOrderStatuses('pending'), containsAll(<String>['confirmed', 'delivered']));
    expect(nextOrderStatuses('processing'), contains('ready'));
    expect(nextOrderStatuses('ready'), containsAll(<String>['delivered', 'out_for_delivery']));
    expect(nextOrderStatuses('cancelled'), isEmpty);
  });

  test('StaffOrderListItem.fromJoin maps customer snapshot', () {
    final item = StaffOrderListItem.fromJoin(<String, Object?>{
      'id': 'o1',
      'customer_id': 'c1',
      'order_number': 42,
      'source': 'online',
      'status': 'pending',
      'total_amount': 150,
      'placed_at': '2026-11-05T10:00:00Z',
      'customer_snapshot': <String, Object?>{
        'name': 'Ravi',
        'phone': '+919999999999',
      },
      'order_items': <Object?>[
        <String, Object?>{
          'id': 'i1',
          'product_snapshot': <String, Object?>{
            'name': 'Paracetamol',
            'image_url': 'https://cdn.example/p.png',
          },
        },
      ],
    });

    expect(item.orderNumber, 42);
    expect(item.displayCustomer, 'Ravi');
    expect(item.itemCount, 1);
    expect(item.source, 'online');
    expect(item.firstItemName, 'Paracetamol');
    expect(item.firstItemImageUrl, 'https://cdn.example/p.png');
  });

  test('StaffOrderLine.fromJson resolves joined master image', () {
    final line = StaffOrderLine.fromJson(<String, Object?>{
      'id': 'li1',
      'store_product_id': 'sp1',
      'quantity': 2,
      'unit_price': 20,
      'total_price': 40,
      'product_snapshot': <String, Object?>{
        'name': 'Crocin',
        'batch_no': 'B1',
        'mrp': 25,
      },
      'store_products': <String, Object?>{
        'master_products': <String, Object?>{
          'image_url': 'https://cdn.example/c.png',
        },
      },
    });

    expect(line.productName, 'Crocin');
    expect(line.imageUrl, 'https://cdn.example/c.png');
    expect(line.mrp, 25);
  });

  test('CreateReturnInput serializes order items', () {
    final json = const CreateReturnInput(
      orderId: '11111111-1111-1111-1111-111111111111',
      reason: 'Damaged',
      items: <CreateReturnItemInput>[
        CreateReturnItemInput(
          orderItemId: '22222222-2222-2222-2222-222222222222',
          quantity: 2,
          condition: 'damaged',
          restockAction: 'dispose',
        ),
      ],
    ).toJson();

    expect(json['order_id'], '11111111-1111-1111-1111-111111111111');
    expect(json['items'], hasLength(1));
    expect((json['items'] as List).first['quantity'], 2);
  });

  testWidgets('orders page lists board rows', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersListProvider.overrideWith(_IdleOrdersController.new),
        ],
        child: const MaterialApp(home: StaffOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.ORDERS_TITLE')), findsOneWidget);
    expect(find.text('#101'), findsOneWidget);
    expect(find.textContaining('+919888877777'), findsOneWidget);
  });

  testWidgets('orders route replaces stub', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersListProvider.overrideWith(_IdleOrdersController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffOrders),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StaffOrdersPage), findsOneWidget);
  });

  testWidgets('returns page lists rows', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          returnsListProvider.overrideWith(_IdleReturnsController.new),
        ],
        child: const MaterialApp(home: ReturnsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.RETURNS_TITLE')), findsOneWidget);
    expect(find.textContaining('#55'), findsOneWidget);
    expect(find.text(t('STORE_FORM.ADD_RETURN')), findsWidgets);
  });

  testWidgets('returns route replaces stub', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          returnsListProvider.overrideWith(_IdleReturnsController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffReturns),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReturnsPage), findsOneWidget);
  });
}

class _IdleOrdersController extends OrdersListController {
  @override
  OrdersListState build() {
    return const OrdersListState(
      items: <StaffOrderListItem>[
        StaffOrderListItem(
          id: 'o-1',
          orderNumber: 101,
          customerId: 'c1',
          customerName: 'Asha',
          customerPhone: '+919888877777',
          itemCount: 2,
          totalAmount: 240,
          source: 'online',
          status: 'pending',
          placedAt: '2026-11-05T09:00:00Z',
        ),
      ],
    );
  }
}

class _IdleReturnsController extends ReturnsListController {
  @override
  ReturnsListState build() {
    return const ReturnsListState(
      items: <StaffReturnListItem>[
        StaffReturnListItem(
          id: 'r-1',
          orderId: 'o-2',
          orderNumber: 55,
          customerName: 'Kiran',
          customerPhone: '+919777766666',
          itemCount: 1,
          refundAmount: 80,
          status: 'pending',
          refundStatus: 'pending',
          createdAt: '2026-11-05T11:00:00Z',
        ),
      ],
    );
  }
}
