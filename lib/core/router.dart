import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/supabase_client.dart';
import '../features/account/account_page.dart';
import '../features/cart/cart_page.dart';
import '../features/checkout/checkout_page.dart';
import '../features/location/location_screen.dart';
import '../features/orders/order_detail_page.dart';
import '../features/orders/orders_page.dart';
import '../features/staff/auth/staff_login_page.dart';
import '../features/staff/auth/staff_signup_page.dart';
import '../features/staff/onboarding/staff_onboarding_page.dart';
import '../features/staff/medicines/catalog_product_edit_sheet.dart';
import '../features/staff/medicines/catalog_product_page.dart';
import '../features/staff/medicines/medicines_create_page.dart';
import '../features/staff/medicines/medicines_page.dart';
import '../features/staff/pos/pos_checkout_page.dart';
import '../features/staff/pos/pos_page.dart';
import '../features/staff/customers/customers_page.dart';
import '../features/staff/orders/order_detail_page.dart';
import '../features/staff/orders/order_edit_page.dart';
import '../features/staff/orders/orders_page.dart';
import '../features/staff/payments/payments_page.dart';
import '../features/staff/purchases/purchase_detail_page.dart';
import '../features/staff/purchases/purchase_form_page.dart';
import '../features/staff/purchases/purchases_page.dart';
import '../features/staff/returns/return_detail_page.dart';
import '../features/staff/returns/return_form_page.dart';
import '../features/staff/returns/returns_page.dart';
import '../features/staff/more/more_page.dart';
import '../features/staff/more/staff_web_page.dart';
import '../features/staff/shell/staff_pop_scope.dart';
import '../features/staff/shell/staff_shell.dart';
import '../features/staff/store_settings/categories_page.dart';
import '../features/staff/store_settings/profile_edit_page.dart';
import '../features/staff/store_settings/profile_page.dart';
import '../features/staff/store_settings/store_detail_page.dart';
import '../features/staff/store_settings/store_settings_page.dart';
import '../features/staff/suppliers/suppliers_page.dart';
import '../features/staff/today/today_page.dart';
import '../features/storefront/category_page.dart';
import '../features/storefront/customer_shell.dart';
import '../features/storefront/prescription_page.dart';
import '../features/storefront/product_page.dart';
import '../features/storefront/search_page.dart';
import '../features/storefront/shop_home_page.dart';
import '../features/storefront/shop_info_page.dart';
import 'brand.dart';
import 'i18n.dart';
import 'placeholder_page.dart';
import 'routes.dart';

bool _isStaffAuthPath(String path) {
  return path == Routes.staffLogin ||
      path == Routes.staffSignup ||
      path == Routes.staffOnboarding;
}

bool _isStaffAppPath(String path) {
  return path.startsWith('/staff/') && !_isStaffAuthPath(path);
}

Widget _staffOffShell(Widget child) => StaffPopToHome(child: child);

GoRouter createAppRouter({String initialLocation = Routes.staffLogin}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;
      if (path == '/') {
        return Routes.staffLogin;
      }

      // Staff app routes need a Supabase session. Auth screens stay open.
      if (_isStaffAppPath(path) && AppSupabase.isReady) {
        final session = AppSupabase.client.auth.currentSession;
        if (session == null) {
          return Routes.staffLogin;
        }
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.location,
        builder: (BuildContext context, GoRouterState state) {
          return const LocationScreen();
        },
      ),
      GoRoute(
        path: Routes.checkout,
        builder: (BuildContext context, GoRouterState state) {
          return const CheckoutPage();
        },
      ),
      GoRoute(
        path: Routes.prescription,
        builder: (BuildContext context, GoRouterState state) {
          return const PrescriptionPage();
        },
      ),
      GoRoute(
        path: Routes.staffLogin,
        builder: (BuildContext context, GoRouterState state) {
          return const StaffLoginPage();
        },
      ),
      GoRoute(
        path: Routes.staffSignup,
        builder: (BuildContext context, GoRouterState state) {
          return const StaffSignupPage();
        },
      ),
      GoRoute(
        path: Routes.staffOnboarding,
        builder: (BuildContext context, GoRouterState state) {
          return const StaffOnboardingPage();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return CustomerShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.shopRoot,
                builder: (BuildContext context, GoRouterState state) {
                  return const PlaceholderPage(titleKey: 'NAV.HOME');
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':slug',
                    builder: (BuildContext context, GoRouterState state) {
                      return ShopHomePage(
                        slug: state.pathParameters['slug'] ?? '',
                      );
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'category/:cat',
                        builder: (BuildContext context, GoRouterState state) {
                          return CategoryPage(
                            slug: state.pathParameters['slug'] ?? '',
                            cat: state.pathParameters['cat'] ?? '',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'product/:product',
                        builder: (BuildContext context, GoRouterState state) {
                          return ProductPage(
                            shopSlug: state.pathParameters['slug'] ?? '',
                            productSlug: state.pathParameters['product'] ?? '',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'info',
                        builder: (BuildContext context, GoRouterState state) {
                          return ShopInfoPage(
                            slug: state.pathParameters['slug'] ?? '',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.search,
                builder: (BuildContext context, GoRouterState state) {
                  return const SearchPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.cart,
                builder: (BuildContext context, GoRouterState state) {
                  return const CartPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.orders,
                builder: (BuildContext context, GoRouterState state) {
                  return const OrdersPage();
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    builder: (BuildContext context, GoRouterState state) {
                      return OrderDetailPage(
                        orderId: state.pathParameters['id'] ?? '',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.account,
                builder: (BuildContext context, GoRouterState state) {
                  return const AccountPage();
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'addresses',
                    builder: (BuildContext context, GoRouterState state) {
                      return const PlaceholderPage(titleKey: 'NAV.ACCOUNT');
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return StaffShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          // Home / dashboard first so cold open does not mount POS.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffToday,
                builder: (BuildContext context, GoRouterState state) {
                  return const TodayPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffPos,
                builder: (BuildContext context, GoRouterState state) {
                  return const PosPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffMedicines,
                builder: (BuildContext context, GoRouterState state) {
                  return const MedicinesPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffOrders,
                builder: (BuildContext context, GoRouterState state) {
                  return const StaffOrdersPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffMore,
                builder: (BuildContext context, GoRouterState state) {
                  return const MorePage();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.staffInventory,
        redirect: (BuildContext context, GoRouterState state) {
          return Routes.staffMedicines;
        },
      ),
      GoRoute(
        path: '${Routes.staffInventory}/:storeProductId',
        redirect: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['storeProductId'] ?? '';
          if (id.isEmpty) return Routes.staffMedicines;
          return Routes.staffMedicinesProduct(id);
        },
      ),
      // Create before :storeProductId so "create" is not treated as an id.
      GoRoute(
        path: Routes.staffMedicinesCreate,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const MedicinesCreatePage());
        },
      ),
      // Product view/edit outside bottom bar.
      GoRoute(
        path: '${Routes.staffMedicines}/:storeProductId',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['storeProductId'] ?? '';
          return _staffOffShell(CatalogProductPage(storeProductId: id));
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['storeProductId'] ?? '';
              return _staffOffShell(
                CatalogProductEditPage(storeProductId: id),
              );
            },
          ),
        ],
      ),
      // Order view/edit outside bottom bar.
      GoRoute(
        path: '${Routes.staffOrders}/:orderId',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['orderId'] ?? '';
          return _staffOffShell(StaffOrderDetailPage(orderId: id));
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['orderId'] ?? '';
              return _staffOffShell(StaffOrderEditPage(orderId: id));
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.staffPosCheckout,
        builder: (BuildContext context, GoRouterState state) {
          return StaffPopToHome(
            fallback: Routes.staffPos,
            child: const PosCheckoutPage(),
          );
        },
      ),
      GoRoute(
        path: Routes.staffPurchases,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const PurchasesPage());
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (BuildContext context, GoRouterState state) {
              return _staffOffShell(const PurchaseFormPage());
            },
          ),
          GoRoute(
            path: ':purchaseOrderId',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['purchaseOrderId'] ?? '';
              return _staffOffShell(PurchaseDetailPage(purchaseOrderId: id));
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.staffPayments,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const PaymentsPage());
        },
      ),
      GoRoute(
        path: Routes.staffCustomers,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const CustomersPage());
        },
      ),
      GoRoute(
        path: Routes.staffSuppliers,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const SuppliersPage());
        },
      ),
      GoRoute(
        path: Routes.staffReturns,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const ReturnsPage());
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (BuildContext context, GoRouterState state) {
              final orderId = state.uri.queryParameters['orderId'];
              return _staffOffShell(ReturnFormPage(prefillOrderId: orderId));
            },
          ),
          GoRoute(
            path: ':returnId',
            builder: (BuildContext context, GoRouterState state) {
              final id = state.pathParameters['returnId'] ?? '';
              return _staffOffShell(ReturnDetailPage(returnId: id));
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.staffStore,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const StoreDetailPage());
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (BuildContext context, GoRouterState state) {
              return _staffOffShell(const StoreSettingsPage());
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.staffProfile,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const StaffProfilePage());
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (BuildContext context, GoRouterState state) {
              return _staffOffShell(const StaffProfileEditPage());
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.staffCategories,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(const CategoriesPage());
        },
      ),
      GoRoute(
        path: Routes.staffLegalPrivacy,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(
            StaffWebPage(
              title: t('MORE.PRIVACY'),
              url: Brand.urls.privacyPolicy,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.staffLegalTerms,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(
            StaffWebPage(
              title: t('MORE.LEGAL'),
              url: Brand.urls.termsOfService,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.staffLegalData,
        builder: (BuildContext context, GoRouterState state) {
          return _staffOffShell(
            StaffWebPage(
              title: t('MORE.DATA'),
              url: Brand.urls.contact,
            ),
          );
        },
      ),
    ],
  );
}

final GoRouter appRouter = createAppRouter();
