import 'listing.dart';

/// Payload from `get_store_dashboard_counts` (IST “today”).
class DashboardCounts {
  const DashboardCounts({
    required this.products,
    required this.categories,
    required this.customers,
    required this.orders,
    required this.inventoryUnits,
    required this.inventoryValue,
    required this.lowStock,
    required this.expiringBatches,
    required this.todaySales,
    required this.todayCash,
    required this.todayOrderCount,
    required this.pendingOnlineOrders,
  });

  const DashboardCounts.empty()
    : products = 0,
      categories = 0,
      customers = 0,
      orders = 0,
      inventoryUnits = 0,
      inventoryValue = 0,
      lowStock = 0,
      expiringBatches = 0,
      todaySales = 0,
      todayCash = 0,
      todayOrderCount = 0,
      pendingOnlineOrders = 0;

  final double products;
  final double categories;
  final double customers;
  final double orders;
  final double inventoryUnits;
  final double inventoryValue;
  final double lowStock;
  final double expiringBatches;
  final double todaySales;
  final double todayCash;
  final double todayOrderCount;
  final double pendingOnlineOrders;

  factory DashboardCounts.fromJson(Map<String, Object?> json) {
    return DashboardCounts(
      products: asNumber(json['products']),
      categories: asNumber(json['categories']),
      customers: asNumber(json['customers']),
      orders: asNumber(json['orders']),
      inventoryUnits: asNumber(json['inventory_units']),
      inventoryValue: asNumber(json['inventory_value']),
      lowStock: asNumber(json['low_stock']),
      expiringBatches: asNumber(json['expiring_batches']),
      todaySales: asNumber(json['today_sales']),
      todayCash: asNumber(json['today_cash']),
      todayOrderCount: asNumber(json['today_order_count']),
      pendingOnlineOrders: asNumber(json['pending_online_orders']),
    );
  }
}

DashboardCounts parseDashboardCounts(Object? raw) {
  final row = asRecord(raw);
  if (row == null) return const DashboardCounts.empty();
  return DashboardCounts.fromJson(row);
}
