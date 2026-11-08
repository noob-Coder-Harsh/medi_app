import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/models/dashboard_counts.dart';
import 'package:medi_app/data/models/dashboard_summary.dart';
import 'package:medi_app/features/staff/today/today_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeToday extends TodayController {
  _FakeToday(this.summary);

  final DashboardSummary summary;

  @override
  Future<DashboardSummary> build() async => summary;
}

class _FixedRange extends TodayRangeController {
  _FixedRange(this.range);

  final DashboardRange range;

  @override
  DashboardRange build() => range;
}

DashboardSummary _sampleSummary({
  double products = 10,
  double salesOrderCount = 5,
}) {
  return DashboardSummary(
    range: DashboardRange.today,
    sales: DashboardSales(
      orderCount: 6,
      cancelledCount: 1,
      onlineOrderCount: 2,
      posOrderCount: 3,
      salesTotal: 1500,
      onlineSalesTotal: 400,
      posSalesTotal: 1100,
      salesOrderCount: salesOrderCount,
      prescriptionOrderCount: 2,
      statusCounts: const DashboardStatusCounts(
        delivered: 3,
        processing: 2,
        ready: 1,
        cancelled: 1,
        other: 0,
      ),
    ),
    catalogCounts: DashboardCatalogCounts(
      products: products,
      categories: 4,
      customers: 8,
    ),
    inventoryMetrics: const DashboardInventoryMetrics(
      totalSkus: 40,
      inStock: 30,
      lowStock: 5,
      outOfStock: 5,
    ),
    inventoryValue: const DashboardInventoryValue(
      atPurchase: 20000,
      atSelling: 28000,
      atMrp: 32000,
    ),
    alerts: const DashboardAlerts(
      expiring30: 3,
      expiring90: 7,
      lowStock: 5,
    ),
    openPoCount: 2,
    purchaseCount: 12,
    unpaidPoCount: 1,
    supplierDueTotal: 4500,
  );
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('parseDashboardCounts reads RPC snake_case fields', () {
    final counts = parseDashboardCounts(<String, Object?>{
      'today_sales': 1250.5,
      'today_cash': 800,
      'today_order_count': 4,
      'pending_online_orders': 2,
      'expiring_batches': 3,
      'low_stock': 1,
      'products': 40,
    });
    expect(counts.todaySales, 1250.5);
    expect(counts.todayCash, 800);
    expect(counts.todayOrderCount, 4);
    expect(counts.pendingOnlineOrders, 2);
    expect(counts.expiringBatches, 3);
  });

  test('parseDashboardSummary reads camelCase RPC payload', () {
    final summary = parseDashboardSummary(<String, Object?>{
      'range': '30d',
      'sales': <String, Object?>{
        'orderCount': 10,
        'cancelledCount': 1,
        'onlineOrderCount': 4,
        'posOrderCount': 6,
        'salesTotal': 5000,
        'onlineSalesTotal': 2000,
        'posSalesTotal': 3000,
        'salesOrderCount': 9,
        'prescriptionOrderCount': 3,
        'statusCounts': <String, Object?>{
          'delivered': 5,
          'processing': 2,
          'ready': 1,
          'cancelled': 1,
          'other': 1,
        },
      },
      'catalogCounts': <String, Object?>{
        'products': 40,
        'categories': 6,
        'customers': 12,
      },
      'inventoryMetrics': <String, Object?>{
        'totalSkus': 40,
        'inStock': 30,
        'lowStock': 7,
        'outOfStock': 3,
      },
      'inventoryValue': <String, Object?>{
        'atPurchase': 10000,
        'atSelling': 15000,
        'atMrp': 18000,
      },
      'alerts': <String, Object?>{
        'expiring30': 4,
        'expiring90': 9,
        'lowStock': 7,
      },
      'openPoCount': 2,
      'purchaseCount': 15,
      'unpaidPoCount': 3,
      'supplierDueTotal': 2500.5,
    });

    expect(summary.range, DashboardRange.d30);
    expect(summary.sales.salesTotal, 5000);
    expect(summary.sales.averageOrderValue, closeTo(5000 / 9, 0.001));
    expect(summary.sales.otcOrderCount, 6);
    expect(summary.sales.statusCounts.processing, 2);
    expect(summary.alerts.expiring30, 4);
    expect(summary.openPoCount, 2);
    expect(summary.supplierDueTotal, 2500.5);
  });

  test('DashboardRange.parse falls back to today', () {
    expect(DashboardRange.parse('7d'), DashboardRange.d7);
    expect(DashboardRange.parse('nope'), DashboardRange.today);
  });

  testWidgets('Today shows summary sections and navigates', (
    WidgetTester tester,
  ) async {
    final summary = _sampleSummary();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayDashboardProvider.overrideWith(() => _FakeToday(summary)),
          todayRangeProvider.overrideWith(
            () => _FixedRange(DashboardRange.today),
          ),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffToday),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('TODAY.TITLE')), findsWidgets);
    expect(find.text(t('TODAY.SALES')), findsWidgets);
    expect(find.text(t('TODAY.ORDERS')), findsWidgets);
    expect(find.text(t('TODAY.AOV')), findsOneWidget);
    expect(find.text(t('TODAY.RANGE_TODAY')), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final scrollable = find
        .descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text(t('TODAY.SALES_BREAKDOWN')),
      200,
      scrollable: scrollable,
    );
    expect(find.text(t('TODAY.SALES_BREAKDOWN')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(t('TODAY.PROCESSING')),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text(t('TODAY.PROCESSING')));
    await tester.pumpAndSettle();
    expect(find.text(t('NAV.ORDERS')), findsWidgets);
  });

  testWidgets('Today shows next-step CTA when catalog is empty', (
    WidgetTester tester,
  ) async {
    final summary = _sampleSummary(products: 0, salesOrderCount: 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayDashboardProvider.overrideWith(() => _FakeToday(summary)),
          todayRangeProvider.overrideWith(
            () => _FixedRange(DashboardRange.today),
          ),
        ],
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffToday),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('TODAY.NEXT_ADD_PRODUCTS')), findsOneWidget);
  });
}
