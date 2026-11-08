/// Path helpers. Staff URLs are never linked from customer chrome.
abstract final class Routes {
  static const location = '/location';
  static const shopRoot = '/shop';
  static const search = '/search';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const account = '/account';
  static const addresses = '/account/addresses';
  static const prescription = '/prescription';

  static String shop(String slug) => '/shop/$slug';
  static String category(String slug, String cat) =>
      '/shop/$slug/category/$cat';
  static String product(String slug, String product) =>
      '/shop/$slug/product/$product';
  static String shopInfo(String slug) => '/shop/$slug/info';
  static String order(String id) => '/orders/$id';

  static const staffLogin = '/staff/login';
  static const staffSignup = '/staff/signup';
  static const staffOnboarding = '/staff/onboarding';
  static const staffPos = '/staff/pos';
  static const staffPosCheckout = '/staff/pos/checkout';
  static const staffToday = '/staff/today';
  static const staffMedicines = '/staff/medicines';
  static const staffMedicinesCreate = '/staff/medicines/create';
  static String staffMedicinesProduct(String storeProductId) =>
      '/staff/medicines/$storeProductId';
  static String staffMedicinesProductEdit(String storeProductId) =>
      '/staff/medicines/$storeProductId/edit';
  static const staffOrders = '/staff/orders';
  static String staffOrder(String id) => '/staff/orders/$id';
  static String staffOrderEdit(String id) => '/staff/orders/$id/edit';
  /// Legacy inventory hub — redirects to Catalog.
  static const staffInventory = '/staff/inventory';
  static String staffInventoryProduct(String storeProductId) =>
      '/staff/inventory/$storeProductId';
  static const staffPurchases = '/staff/purchases';
  static const staffPurchaseNew = '/staff/purchases/new';
  static String staffPurchase(String id) => '/staff/purchases/$id';
  static const staffPayments = '/staff/payments';
  static const staffCustomers = '/staff/customers';
  static const staffSuppliers = '/staff/suppliers';
  static const staffReturns = '/staff/returns';
  static const staffReturnNew = '/staff/returns/new';
  static String staffReturn(String id) => '/staff/returns/$id';
  static const staffMore = '/staff/more';
  static const staffStore = '/staff/store';
  static const staffStoreEdit = '/staff/store/edit';
  static const staffProfile = '/staff/profile';
  static const staffProfileEdit = '/staff/profile/edit';
  static const staffCategories = '/staff/categories';
  static const staffLegalPrivacy = '/staff/legal/privacy';
  static const staffLegalTerms = '/staff/legal/terms';
  static const staffLegalData = '/staff/legal/data';
}
