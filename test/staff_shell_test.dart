import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/core/slug.dart';
import 'package:medi_app/features/staff/medicines/medicines_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('toSlug matches web-style pharmacy names', () {
    expect(toSlug('Sharma Medical Store'), 'sharma-medical-store');
    expect(isReservedStoreSlug('admin'), isTrue);
    expect(isReservedStoreSlug('sharma-medical'), isFalse);
  });

  testWidgets('staff More tab opens account screen not sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffMore),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('more-profile-card')), findsOneWidget);
    expect(find.byKey(const Key('more-store-card')), findsOneWidget);
    expect(find.byKey(const Key('more-privacy-card')), findsOneWidget);
    expect(find.byKey(const Key('more-legal-card')), findsOneWidget);
    expect(find.byKey(const Key('more-data-card')), findsOneWidget);
    expect(find.text(t('NAV.MORE')), findsWidgets);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('onboarding form renders without marketing chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffOnboarding),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_PANEL_ONBOARDING_TITLE')), findsOneWidget);
    expect(find.text(t('STAFF.PHARMACY_NAME')), findsOneWidget);
    expect(find.text(t('STAFF.ONBOARDING_SUBMIT')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('legacy inventory path redirects to catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffInventory),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MedicinesPage), findsOneWidget);
    expect(find.text(t('STORE_FORM.MEDICINES_TITLE')), findsWidgets);
  });
}
