import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/routes.dart';
import 'package:medi_app/features/staff/auth/staff_session.dart';
import 'package:medi_app/features/staff/auth/staff_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('staffHomePath sends owners without store to onboarding', () {
    expect(staffHomePath(null), Routes.staffOnboarding);
    expect(
      staffHomePath(
        const StaffUser(id: 'u1', authUserId: 'a1'),
      ),
      Routes.staffOnboarding,
    );
    expect(
      staffHomePath(
        const StaffUser(id: 'u1', authUserId: 'a1', storeId: 's1'),
      ),
      Routes.staffToday,
    );
  });

  testWidgets('staff login shows branded form without Google', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffLogin),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MediSync'), findsOneWidget);
    expect(find.text(t('STORE_LOGIN_TAGLINE')), findsOneWidget);
    expect(find.text(t('STORE_LOGIN_TITLE')), findsOneWidget);
    expect(find.text(t('STORE_SIGN_IN')), findsOneWidget);
    expect(find.text(t('AUTH_FORGOT_PASSWORD')), findsOneWidget);
    expect(find.text(t('STORE_CREATE_ONE')), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('staff signup form is reachable from login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: Routes.staffLogin),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final createLink = find.text(t('STORE_CREATE_ONE'));
    await tester.ensureVisible(createLink);
    await tester.pumpAndSettle();
    await tester.tap(createLink);
    await tester.pumpAndSettle();

    expect(find.text(t('STORE_SIGNUP_TITLE')), findsOneWidget);
    expect(find.text(t('AUTH_FULL_NAME_LABEL')), findsOneWidget);
    expect(find.text(t('AUTH_CREATE_ACCOUNT')), findsOneWidget);
  });
}
