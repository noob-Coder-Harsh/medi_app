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
  static const staffToday = '/staff/today';
  static const staffMedicines = '/staff/medicines';
  static const staffOrders = '/staff/orders';
  static const staffInventory = '/staff/inventory';
  static const staffPurchases = '/staff/purchases';
  static const staffPayments = '/staff/payments';
  static const staffCustomers = '/staff/customers';
  static const staffSuppliers = '/staff/suppliers';
  static const staffReturns = '/staff/returns';
  static const staffStore = '/staff/store';
  static const staffProfile = '/staff/profile';
  static const staffCategories = '/staff/categories';
}
