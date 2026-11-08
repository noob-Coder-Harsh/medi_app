import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customers/customers_controller.dart';
import 'inventory/inventory_controller.dart';
import 'medicines/medicines_controller.dart';
import 'orders/orders_controller.dart';
import 'payments/payments_controller.dart';
import 'pos/pos_cart_controller.dart';
import 'pos/pos_catalog_controller.dart';
import 'pos/pos_recent_sales.dart';
import 'purchases/purchases_controller.dart';
import 'returns/returns_controller.dart';
import 'store_settings/categories_controller.dart';
import 'store_settings/store_settings_controller.dart';
import 'suppliers/suppliers_controller.dart';
import 'today/today_controller.dart';

/// Clears in-memory staff catalog / books state on logout (DATA_PLANE hygiene).
/// Does **not** touch customer Firebase session or local customer cart.
void clearStaffWorkspace(WidgetRef ref) {
  ref.invalidate(posCatalogProvider);
  ref.invalidate(posCartProvider);
  ref.invalidate(posRecentSalesProvider);
  ref.invalidate(medicinesProvider);
  ref.invalidate(todayDashboardProvider);
  ref.invalidate(ordersListProvider);
  ref.invalidate(returnsListProvider);
  ref.invalidate(purchasesListProvider);
  ref.invalidate(paymentsProvider);
  ref.invalidate(customersProvider);
  ref.invalidate(suppliersProvider);
  ref.invalidate(inventoryListProvider);
  ref.invalidate(storeSettingsProvider);
  ref.invalidate(categoriesSettingsProvider);
}
