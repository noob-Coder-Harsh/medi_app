import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/medi_app_bar.dart';
import '../../core/theme.dart';
import '../../data/models/customer_order.dart';
import '../account/customer_auth.dart';
import '../account/otp_sheet.dart';
import 'orders_controller.dart';

/// My orders. Guest = Sign in CTA; signed-in = list from `/api/app/orders`.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  String _statusLabel(String status) {
    final key = customerOrderStatusLabel(status);
    final label = t(key);
    return label == key ? status : label;
  }

  String _placedLabel(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return Format.date(parsed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final session = ref.watch(customerSessionProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: MediAppBar(titleText: t('NAV.ORDERS')),
      body: !session.isSignedIn
          ? _GuestBody(
              onSignIn: () async {
                final ok = await showOtpSheet(context);
                if (ok) {
                  ref.invalidate(myOrdersProvider);
                }
              },
            )
          : ref.watch(myOrdersProvider).when(
              loading: () => Center(child: Text(t('STOREFRONT.ORDERS_LOADING'))),
              error: (Object _, StackTrace __) => Center(
                child: Text(t('STOREFRONT.SEARCH_FAILED')),
              ),
              data: (List<CustomerOrderListItem> orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            t('STOREFRONT.ORDERS_EMPTY'),
                            key: const Key('orders-empty'),
                            style: text.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('STOREFRONT.ORDERS_EMPTY_HINT'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  key: const Key('orders-list'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (BuildContext _, int __) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final order = orders[index];
                    return ListTile(
                      key: Key('order-row-${order.id}'),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadius,
                        side: const BorderSide(
                          color: AppTheme.hairlineColor,
                          width: AppTheme.hairline,
                        ),
                      ),
                      title: Text(
                        '${t('STOREFRONT.ORDER_NUMBER')} #${order.orderNumber}',
                      ),
                      subtitle: Text(
                        '${order.storeName}\n${_statusLabel(order.status)} · ${_placedLabel(order.placedAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        Format.rupee(order.totalAmount),
                        style: AppTheme.rupee(text.titleSmall!),
                      ),
                      onTap: () => context.push(Routes.order(order.id)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _GuestBody extends StatelessWidget {
  const _GuestBody({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t('STOREFRONT.ORDERS_EMPTY'),
            key: const Key('orders-empty'),
            style: text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t('STOREFRONT.ORDERS_EMPTY_HINT'),
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t('STOREFRONT.ORDERS_SIGN_IN'),
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: AppTheme.touchTarget,
            child: FilledButton(
              key: const Key('orders-sign-in'),
              onPressed: onSignIn,
              child: Text(t('STOREFRONT.SIGN_IN_TO_CHECKOUT')),
            ),
          ),
        ],
      ),
    );
  }
}
