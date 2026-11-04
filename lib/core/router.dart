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
import '../features/staff/shell/staff_shell.dart';
import '../features/storefront/category_page.dart';
import '../features/storefront/customer_shell.dart';
import '../features/storefront/prescription_page.dart';
import '../features/storefront/product_page.dart';
import '../features/storefront/search_page.dart';
import '../features/storefront/shop_home_page.dart';
import '../features/storefront/shop_info_page.dart';
import 'placeholder_page.dart';
import 'routes.dart';

bool _isStaffAuthPath(String path) {
  return path == Routes.staffLogin || path == Routes.staffSignup;
}

bool _isStaffAppPath(String path) {
  return path.startsWith('/staff/') && !_isStaffAuthPath(path);
}

GoRouter createAppRouter({String initialLocation = Routes.location}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;
      if (path == '/') {
        return Routes.location;
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
          return const PlaceholderPage(
            titleKey: 'STORE_PANEL_ONBOARDING_TITLE',
          );
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
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffPos,
                builder: (BuildContext context, GoRouterState state) {
                  return const PlaceholderPage(titleKey: 'NAV.POS');
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffToday,
                builder: (BuildContext context, GoRouterState state) {
                  return const PlaceholderPage(titleKey: 'NAV.TODAY');
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffMedicines,
                builder: (BuildContext context, GoRouterState state) {
                  return const PlaceholderPage(titleKey: 'NAV.MEDICINES');
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.staffOrders,
                builder: (BuildContext context, GoRouterState state) {
                  return const PlaceholderPage(titleKey: 'NAV.ORDERS');
                },
              ),
            ],
          ),
        ],
      ),
      _staffPage(Routes.staffInventory),
      _staffPage(Routes.staffPurchases),
      _staffPage(Routes.staffPayments),
      _staffPage(Routes.staffCustomers),
      _staffPage(Routes.staffSuppliers),
      _staffPage(Routes.staffReturns),
      _staffPage(Routes.staffStore),
      _staffPage(Routes.staffProfile),
      _staffPage(Routes.staffCategories),
    ],
  );
}

GoRoute _staffPage(String path) {
  return GoRoute(
    path: path,
    builder: (BuildContext context, GoRouterState state) {
      return PlaceholderPage(title: 'Staff', detail: path);
    },
  );
}

final GoRouter appRouter = createAppRouter();
