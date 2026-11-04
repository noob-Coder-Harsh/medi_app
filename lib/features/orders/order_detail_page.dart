import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../data/models/customer_order.dart';
import '../account/customer_auth.dart';
import '../account/otp_sheet.dart';
import 'orders_controller.dart';

/// Single order detail. Cancel when [CustomerOrderDetail.canCancel].
class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  var _busy = false;

  Future<void> _ensureSignedIn() async {
    if (ref.read(customerSessionProvider).isSignedIn) return;
    await showOtpSheet(context);
  }

  Future<void> _cancel(CustomerOrderDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) {
        return AlertDialog(
          title: Text(t('STOREFRONT.ORDER_CANCEL')),
          content: Text(t('STOREFRONT.ORDER_CANCEL_CONFIRM')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(t('STOREFRONT.ORDER_CANCEL_KEEP')),
            ),
            FilledButton(
              key: const Key('order-cancel-confirm'),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(t('STOREFRONT.ORDER_CANCEL_CONFIRM_BTN')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final session = ref.read(customerSessionProvider);
    if (!session.isSignedIn) return;

    setState(() => _busy = true);
    try {
      await ref.read(appWriteApiProvider).cancelOrder(
        idToken: session.idToken!,
        orderId: detail.id,
      );
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STOREFRONT.ORDER_CANCELLED'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final session = ref.watch(customerSessionProvider);

    if (!session.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(t('STOREFRONT.ORDER_DETAIL_TITLE'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  t('STOREFRONT.ORDERS_SIGN_IN'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('order-detail-sign-in'),
                  onPressed: () async {
                    await _ensureSignedIn();
                  },
                  child: Text(t('STOREFRONT.SIGN_IN_TO_CHECKOUT')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final asyncDetail = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: Text(t('STOREFRONT.ORDER_DETAIL_TITLE'))),
      body: asyncDetail.when(
        loading: () => Center(child: Text(t('STOREFRONT.ORDERS_LOADING'))),
        error: (Object _, StackTrace __) => Center(
          child: Text(t('STOREFRONT.ORDER_NOT_FOUND')),
        ),
        data: (CustomerOrderDetail detail) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Text(
                '${t('STOREFRONT.ORDER_NUMBER')} #${detail.orderNumber}',
                key: const Key('order-detail-number'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_statusLabel(detail.status)),
              Text(
                '${t('STOREFRONT.ORDER_PLACED_ON')} ${_placedLabel(detail.placedAt)}',
              ),
              if (detail.storeName.isNotEmpty)
                Text('${t('STOREFRONT.ORDER_PHARMACY')}: ${detail.storeName}'),
              if (detail.paymentMethod.isNotEmpty)
                Text('${t('STOREFRONT.ORDER_PAYMENT')}: ${detail.paymentMethod}'),
              const SizedBox(height: 16),
              Text(
                t('STOREFRONT.ORDER_ITEMS'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final line in detail.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.name),
                  subtitle: Text(
                    '${Format.stock(line.quantity)} × ${Format.rupee(line.unitPrice)}',
                  ),
                  trailing: Text(Format.rupee(line.totalPrice)),
                ),
              const Divider(),
              Row(
                children: <Widget>[
                  Expanded(child: Text(t('STOREFRONT.TOTAL'))),
                  Text(
                    Format.rupee(detail.totalAmount),
                    style: AppTheme.rupee(
                      Theme.of(context).textTheme.titleMedium!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (detail.canCancel)
                SizedBox(
                  height: AppTheme.touchTarget,
                  child: OutlinedButton(
                    key: const Key('order-cancel'),
                    onPressed: _busy ? null : () => _cancel(detail),
                    child: Text(t('STOREFRONT.ORDER_CANCEL')),
                  ),
                ),
              TextButton(
                onPressed: () => context.go(Routes.orders),
                child: Text(t('STOREFRONT.ORDER_BACK')),
              ),
            ],
          );
        },
      ),
    );
  }
}
