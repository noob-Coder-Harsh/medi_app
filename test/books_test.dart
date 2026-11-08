import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/models/staff_books.dart';
import 'package:medi_app/features/staff/customers/customers_controller.dart';
import 'package:medi_app/features/staff/customers/customers_page.dart';
import 'package:medi_app/features/staff/payments/payments_controller.dart';
import 'package:medi_app/features/staff/payments/payments_page.dart';
import 'package:medi_app/features/staff/suppliers/suppliers_controller.dart';
import 'package:medi_app/features/staff/suppliers/suppliers_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('StaffCustomer.fromJoin maps khata balance', () {
    final customer = StaffCustomer.fromJoin(<String, Object?>{
      'id': 'sc-1',
      'customer_id': 'c-1',
      'current_balance': 120.5,
      'loyalty_points': 3,
      'total_orders': 2,
      'total_spent': 500,
      'notes': 'VIP',
      'customers': <String, Object?>{
        'phone': '+919876543210',
        'name': 'Ravi',
        'is_active': true,
      },
    });

    expect(customer.displayName, 'Ravi');
    expect(customer.currentBalance, 120.5);
    expect(customer.customerId, 'c-1');
  });

  test('settlement payloads use global customer_id', () {
    final json = const CustomerSettlementInput(
      customerId: 'cust-1',
      amount: 50,
      method: 'cash',
    ).toJson();
    expect(json['customer_id'], 'cust-1');
    expect(json['amount'], 50);
  });

  testWidgets('customers page lists rows', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersProvider.overrideWith(_IdleCustomersController.new),
        ],
        child: const MaterialApp(home: CustomersPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.CUSTOMERS_TITLE')), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text(t('STORE_FORM.ADD_CUSTOMER')), findsWidgets);
  });

  testWidgets('suppliers route replaces stub', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppliersProvider.overrideWith(_IdleSuppliersController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffSuppliers),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SuppliersPage), findsOneWidget);
    expect(find.text('Local Wholesaler'), findsOneWidget);
  });

  testWidgets('payments route replaces stub', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentsProvider.overrideWith(_IdlePaymentsController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffPayments),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaymentsPage), findsOneWidget);
    expect(find.textContaining('₹100'), findsOneWidget);
  });
}

class _IdleCustomersController extends CustomersController {
  @override
  CustomersState build() {
    return const CustomersState(
      items: <StaffCustomer>[
        StaffCustomer(
          id: 'sc-1',
          customerId: 'c-1',
          phone: '+919876543210',
          name: 'Ravi',
          currentBalance: 50,
        ),
      ],
    );
  }
}

class _IdleSuppliersController extends SuppliersController {
  @override
  SuppliersState build() {
    return const SuppliersState(
      items: <StaffSupplier>[
        StaffSupplier(
          id: 's-1',
          name: 'Local Wholesaler',
          currentBalance: 200,
          phone: '9999999999',
        ),
      ],
    );
  }
}

class _IdlePaymentsController extends PaymentsController {
  @override
  PaymentsState build() {
    return const PaymentsState(
      items: <StaffPayment>[
        StaffPayment(
          id: 'p-1',
          amount: 100,
          paymentDirection: 'inflow',
          paymentType: 'sale',
          method: 'cash',
          status: 'paid',
          customerName: 'Ravi',
        ),
      ],
    );
  }
}
