import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/brand.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/core/theme.dart';

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('launches staff login as MediSync', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: MediApp(router: createAppRouter())),
    );
    await tester.pumpAndSettle();

    expect(find.text(Brand.appName), findsOneWidget);
    expect(find.text('Store Owner Login'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('theme uses teal and canvas', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MediApp(router: createAppRouter())),
    );
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, Brand.themeColor);
    expect(app.theme!.scaffoldBackgroundColor, Colors.transparent);

    final ThemeData theme = AppTheme.light();
    expect(theme.colorScheme.primary, const Color(0xFF0F766E));
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
    expect(AppTheme.pageBackgroundAsset, 'assets/images/app_bg.png');
    expect(AppTheme.appBarBackgroundAsset, 'assets/images/appbar.png');
    expect(AppTheme.charge.minimumSize!.resolve({}), const Size(48, 56));
  });

  testWidgets('deep path /shop/foo builds customer tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(router: createAppRouter(initialLocation: '/shop/foo')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('foo'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('POS'), findsNothing);
    expect(find.text('Staff'), findsNothing);
  });

  testWidgets('customer tabs switch dummy pages', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(router: createAppRouter(initialLocation: '/shop/foo')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Cart'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('foo'), findsOneWidget);
  });

  testWidgets('staff paths exist outside customer nav', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: '/staff/login'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Store Owner Login'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Staff'), findsNothing);
  });

  testWidgets('staff pos shell has no customer Home tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(router: createAppRouter(initialLocation: '/staff/pos')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('POS'), findsWidgets);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
