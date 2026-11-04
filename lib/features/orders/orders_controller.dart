import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../../data/models/customer_order.dart';
import '../account/customer_auth.dart';

final myOrdersProvider =
    FutureProvider.autoDispose<List<CustomerOrderListItem>>((Ref ref) async {
  final session = ref.watch(customerSessionProvider);
  if (!session.isSignedIn) return const <CustomerOrderListItem>[];
  return ref.read(appWriteApiProvider).listOrders(idToken: session.idToken!);
});

final orderDetailProvider = FutureProvider.autoDispose
    .family<CustomerOrderDetail, String>((Ref ref, String orderId) async {
  final session = ref.watch(customerSessionProvider);
  if (!session.isSignedIn) {
    throw StateError('Sign in required');
  }
  return ref.read(appWriteApiProvider).getOrder(
    idToken: session.idToken!,
    orderId: orderId,
  );
});

String customerOrderStatusLabel(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized.isEmpty) return status;
  final key = 'STOREFRONT.STATUS_$normalized';
  // Caller wraps with t(); this only builds the key.
  return key;
}
