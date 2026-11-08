import 'listing.dart';

/// Range arg for `get_store_dashboard_summary(p_range)`.
enum DashboardRange {
  today('today'),
  d7('7d'),
  d30('30d'),
  d90('90d'),
  all('all');

  const DashboardRange(this.apiValue);

  final String apiValue;

  static DashboardRange parse(Object? value) {
    final raw = asString(value, 'today');
    for (final range in DashboardRange.values) {
      if (range.apiValue == raw) return range;
    }
    return DashboardRange.today;
  }
}

class DashboardStatusCounts {
  const DashboardStatusCounts({
    required this.delivered,
    required this.processing,
    required this.ready,
    required this.cancelled,
    required this.other,
  });

  const DashboardStatusCounts.empty()
    : delivered = 0,
      processing = 0,
      ready = 0,
      cancelled = 0,
      other = 0;

  final double delivered;
  final double processing;
  final double ready;
  final double cancelled;
  final double other;
}

class DashboardSales {
  const DashboardSales({
    required this.orderCount,
    required this.cancelledCount,
    required this.onlineOrderCount,
    required this.posOrderCount,
    required this.salesTotal,
    required this.onlineSalesTotal,
    required this.posSalesTotal,
    required this.salesOrderCount,
    required this.prescriptionOrderCount,
    required this.statusCounts,
  });

  const DashboardSales.empty()
    : orderCount = 0,
      cancelledCount = 0,
      onlineOrderCount = 0,
      posOrderCount = 0,
      salesTotal = 0,
      onlineSalesTotal = 0,
      posSalesTotal = 0,
      salesOrderCount = 0,
      prescriptionOrderCount = 0,
      statusCounts = const DashboardStatusCounts.empty();

  final double orderCount;
  final double cancelledCount;
  final double onlineOrderCount;
  final double posOrderCount;
  final double salesTotal;
  final double onlineSalesTotal;
  final double posSalesTotal;
  final double salesOrderCount;
  final double prescriptionOrderCount;
  final DashboardStatusCounts statusCounts;

  double get averageOrderValue =>
      salesOrderCount > 0 ? salesTotal / salesOrderCount : 0;

  double get otcOrderCount {
    final otc = salesOrderCount - prescriptionOrderCount;
    return otc < 0 ? 0 : otc;
  }
}

class DashboardCatalogCounts {
  const DashboardCatalogCounts({
    required this.products,
    required this.categories,
    required this.customers,
  });

  const DashboardCatalogCounts.empty()
    : products = 0,
      categories = 0,
      customers = 0;

  final double products;
  final double categories;
  final double customers;
}

class DashboardInventoryMetrics {
  const DashboardInventoryMetrics({
    required this.totalSkus,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
  });

  const DashboardInventoryMetrics.empty()
    : totalSkus = 0,
      inStock = 0,
      lowStock = 0,
      outOfStock = 0;

  final double totalSkus;
  final double inStock;
  final double lowStock;
  final double outOfStock;
}

class DashboardInventoryValue {
  const DashboardInventoryValue({
    required this.atPurchase,
    required this.atSelling,
    required this.atMrp,
  });

  const DashboardInventoryValue.empty()
    : atPurchase = 0,
      atSelling = 0,
      atMrp = 0;

  final double atPurchase;
  final double atSelling;
  final double atMrp;
}

class DashboardAlerts {
  const DashboardAlerts({
    required this.expiring30,
    required this.expiring90,
    required this.lowStock,
  });

  const DashboardAlerts.empty()
    : expiring30 = 0,
      expiring90 = 0,
      lowStock = 0;

  final double expiring30;
  final double expiring90;
  final double lowStock;
}

/// Payload from `get_store_dashboard_summary` (camelCase JSON).
class DashboardSummary {
  const DashboardSummary({
    required this.range,
    required this.sales,
    required this.catalogCounts,
    required this.inventoryMetrics,
    required this.inventoryValue,
    required this.alerts,
    required this.openPoCount,
    required this.purchaseCount,
    required this.unpaidPoCount,
    required this.supplierDueTotal,
  });

  const DashboardSummary.empty()
    : range = DashboardRange.today,
      sales = const DashboardSales.empty(),
      catalogCounts = const DashboardCatalogCounts.empty(),
      inventoryMetrics = const DashboardInventoryMetrics.empty(),
      inventoryValue = const DashboardInventoryValue.empty(),
      alerts = const DashboardAlerts.empty(),
      openPoCount = 0,
      purchaseCount = 0,
      unpaidPoCount = 0,
      supplierDueTotal = 0;

  final DashboardRange range;
  final DashboardSales sales;
  final DashboardCatalogCounts catalogCounts;
  final DashboardInventoryMetrics inventoryMetrics;
  final DashboardInventoryValue inventoryValue;
  final DashboardAlerts alerts;
  final double openPoCount;
  final double purchaseCount;
  final double unpaidPoCount;
  final double supplierDueTotal;

  factory DashboardSummary.fromJson(Map<String, Object?> json) {
    final sales = asRecord(json['sales']);
    final status = asRecord(sales?['statusCounts']);
    final catalog = asRecord(json['catalogCounts']);
    final metrics = asRecord(json['inventoryMetrics']);
    final inventoryValue = asRecord(json['inventoryValue']);
    final alerts = asRecord(json['alerts']);

    return DashboardSummary(
      range: DashboardRange.parse(json['range']),
      sales: DashboardSales(
        orderCount: asNumber(sales?['orderCount']),
        cancelledCount: asNumber(sales?['cancelledCount']),
        onlineOrderCount: asNumber(sales?['onlineOrderCount']),
        posOrderCount: asNumber(sales?['posOrderCount']),
        salesTotal: asNumber(sales?['salesTotal']),
        onlineSalesTotal: asNumber(sales?['onlineSalesTotal']),
        posSalesTotal: asNumber(sales?['posSalesTotal']),
        salesOrderCount: asNumber(sales?['salesOrderCount']),
        prescriptionOrderCount: asNumber(sales?['prescriptionOrderCount']),
        statusCounts: DashboardStatusCounts(
          delivered: asNumber(status?['delivered']),
          processing: asNumber(status?['processing']),
          ready: asNumber(status?['ready']),
          cancelled: asNumber(status?['cancelled']),
          other: asNumber(status?['other']),
        ),
      ),
      catalogCounts: DashboardCatalogCounts(
        products: asNumber(catalog?['products']),
        categories: asNumber(catalog?['categories']),
        customers: asNumber(catalog?['customers']),
      ),
      inventoryMetrics: DashboardInventoryMetrics(
        totalSkus: asNumber(metrics?['totalSkus']),
        inStock: asNumber(metrics?['inStock']),
        lowStock: asNumber(metrics?['lowStock']),
        outOfStock: asNumber(metrics?['outOfStock']),
      ),
      inventoryValue: DashboardInventoryValue(
        atPurchase: asNumber(inventoryValue?['atPurchase']),
        atSelling: asNumber(inventoryValue?['atSelling']),
        atMrp: asNumber(inventoryValue?['atMrp']),
      ),
      alerts: DashboardAlerts(
        expiring30: asNumber(alerts?['expiring30']),
        expiring90: asNumber(alerts?['expiring90']),
        lowStock: asNumber(alerts?['lowStock']),
      ),
      openPoCount: asNumber(json['openPoCount']),
      purchaseCount: asNumber(json['purchaseCount']),
      unpaidPoCount: asNumber(json['unpaidPoCount']),
      supplierDueTotal: asNumber(json['supplierDueTotal']),
    );
  }
}

DashboardSummary parseDashboardSummary(Object? raw) {
  final row = asRecord(raw);
  if (row == null) return const DashboardSummary.empty();
  return DashboardSummary.fromJson(row);
}
