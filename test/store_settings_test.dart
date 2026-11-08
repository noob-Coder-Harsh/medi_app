import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/data/models/staff_store.dart';
import 'package:medi_app/features/staff/store_settings/categories_controller.dart';
import 'package:medi_app/features/staff/store_settings/categories_page.dart';
import 'package:medi_app/features/staff/store_settings/store_detail_page.dart';
import 'package:medi_app/features/staff/store_settings/store_settings_controller.dart';
import 'package:medi_app/features/staff/store_settings/store_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('StaffStore maps accepts_online_orders from modules', () {
    final store = StaffStore.fromJson(<String, Object?>{
      'id': 's1',
      'name': 'City Pharmacy',
      'slug': 'city',
      'module_pickup': false,
      'module_delivery': true,
      'accepts_online_orders': true,
      'sale_policy': 'pack_only',
      'service_radius_km': 3,
    });

    expect(store.moduleDelivery, isTrue);
    expect(store.acceptsOnlineOrders, isTrue);
    expect(store.salePolicy, 'pack_only');
  });

  test('UpdateStoreInput serializes delivery module for Done criterion', () {
    final json = const UpdateStoreInput(
      moduleDelivery: true,
      modulePickup: false,
      allowCod: true,
      salePolicy: 'loose_allowed',
      openingTime: '09:00',
      closingTime: '21:00',
    ).toJson();

    expect(json['module_delivery'], isTrue);
    expect(json.containsKey('accepts_online_orders'), isFalse);
    expect(json['opening_time'], '09:00');
    expect(json['sale_policy'], 'loose_allowed');
  });

  testWidgets('my store page shows sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeSettingsProvider.overrideWith(_IdleStoreSettingsController.new),
        ],
        child: const MaterialApp(home: StoreSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('MORE.EDIT_STORE')), findsOneWidget);
    expect(find.text(t('STORE_FORM.SECTION_PROFILE')), findsOneWidget);
    expect(find.text('City Pharmacy'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(t('STORE_FORM.MODULE_DELIVERY')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(t('STORE_FORM.MODULE_DELIVERY')), findsOneWidget);
  });

  testWidgets('store route opens detail, edit route opens form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeSettingsProvider.overrideWith(_IdleStoreSettingsController.new),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: Routes.staffStore),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StoreDetailPage), findsOneWidget);
    expect(find.byType(StoreSettingsPage), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeSettingsProvider.overrideWith(_IdleStoreSettingsController.new),
        ],
        child: MaterialApp.router(
          routerConfig:
              createAppRouter(initialLocation: Routes.staffStoreEdit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StoreSettingsPage), findsOneWidget);
  });

  testWidgets('categories page lists selected', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesSettingsProvider
              .overrideWith(_IdleCategoriesController.new),
        ],
        child: const MaterialApp(home: CategoriesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_FORM.CATEGORIES_TITLE')), findsOneWidget);
    expect(find.text('Fever'), findsOneWidget);
    expect(find.text(t('STORE_FORM.ADD_CATEGORY')), findsWidgets);
  });

  testWidgets('categories route replaces stub', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesSettingsProvider
              .overrideWith(_IdleCategoriesController.new),
        ],
        child: MaterialApp.router(
          routerConfig:
              createAppRouter(initialLocation: Routes.staffCategories),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesPage), findsOneWidget);
  });
}

class _IdleStoreSettingsController extends StoreSettingsController {
  @override
  StoreSettingsState build() {
    return const StoreSettingsState(
      loading: false,
      store: StaffStore(
        id: 's1',
        name: 'City Pharmacy',
        slug: 'city',
        moduleDelivery: false,
        acceptsOnlineOrders: false,
      ),
    );
  }
}

class _IdleCategoriesController extends CategoriesSettingsController {
  @override
  CategoriesSettingsState build() {
    return const CategoriesSettingsState(
      loading: false,
      selected: <StaffCategory>[
        StaffCategory(
          id: 'c1',
          name: 'Fever',
          slug: 'fever',
          isSystem: true,
          isActive: true,
          attached: true,
        ),
      ],
    );
  }
}
