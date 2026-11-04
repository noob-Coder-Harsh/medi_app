import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medi_app/app.dart';
import 'package:medi_app/core/i18n.dart';
import 'package:medi_app/core/router.dart';
import 'package:medi_app/data/api_client.dart';
import 'package:medi_app/data/local/auth_token_store.dart';
import 'package:medi_app/data/models/checkout.dart';
import 'package:medi_app/data/models/customer_order.dart';
import 'package:medi_app/features/account/customer_auth.dart';

class MemoryTokenStore extends AuthTokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

class FakeAuth implements CustomerAuth {
  String? lastPhone;
  String? lastCode;

  @override
  Future<void> sendOtp(String phoneE164) async {
    lastPhone = phoneE164;
  }

  @override
  Future<String> verifyOtp({
    required String phoneE164,
    required String code,
  }) async {
    lastCode = code;
    return 'id-token-$phoneE164';
  }
}

class FakeWriteApi implements AppWriteApi {
  String? lastToken;

  @override
  Future<CustomerProfile> ensureSession({required String idToken}) async {
    lastToken = idToken;
    return const CustomerProfile(
      customerId: 'cust-9',
      phone: '9876543210',
      name: null,
    );
  }

  @override
  Future<RevalidateCartResult> revalidateCart({
    required String idToken,
    required String storeId,
    required List<RevalidateCartLineInput> items,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PlaceOnlineOrderResult> placeOrder({
    required String idToken,
    required PlaceOnlineOrderInput input,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerOrderListItem>> listOrders({
    required String idToken,
  }) async {
    return const <CustomerOrderListItem>[];
  }

  @override
  Future<CustomerOrderDetail> getOrder({
    required String idToken,
    required String orderId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CustomerOrderDetail> cancelOrder({
    required String idToken,
    required String orderId,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  setUpAll(() async {
    await I18n.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('normalizeIndianMobile forces +91', () {
    expect(normalizeIndianMobile('9876543210'), '+919876543210');
    expect(normalizeIndianMobile('+91 98765 43210'), '+919876543210');
    expect(normalizeIndianMobile('09876543210'), '+919876543210');
    expect(normalizeIndianMobile('123'), isNull);
    expect(isValidOtpCode('123456'), isTrue);
    expect(isValidOtpCode('12a456'), isFalse);
  });

  testWidgets('OTP sheet verifies then posts session and pops success', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuth();
    final api = FakeWriteApi();
    final tokens = MemoryTokenStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerAuthProvider.overrideWithValue(auth),
          appWriteApiProvider.overrideWithValue(api),
          authTokenStoreProvider.overrideWithValue(tokens),
        ],
        child: MediApp(router: createAppRouter(initialLocation: '/account')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account-guest')), findsOneWidget);
    expect(find.textContaining('Sign in'), findsWidgets);

    await tester.tap(find.byKey(const Key('account-sign-in')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp-phone')), '9876543210');
    await tester.tap(find.byKey(const Key('otp-send')));
    await tester.pumpAndSettle();
    expect(auth.lastPhone, '+919876543210');

    await tester.enterText(find.byKey(const Key('otp-code')), '654321');
    await tester.tap(find.byKey(const Key('otp-verify')));
    await tester.pumpAndSettle();

    expect(api.lastToken, 'id-token-+919876543210');
    expect(await tokens.read(), 'id-token-+919876543210');
    expect(find.byKey(const Key('account-signed-in')), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.byKey(const Key('otp-stub-title')), findsNothing);
  });

  testWidgets('guest browse still has no login wall on home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediApp(
          router: createAppRouter(initialLocation: '/shop/foo'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('otp-stub-title')), findsNothing);
    expect(find.textContaining('Sign in'), findsNothing);
  });
}
