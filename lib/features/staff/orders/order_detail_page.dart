import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/link_opener.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/whatsapp.dart';
import '../../../data/models/staff_order.dart';
import '../pos/pos_receipt.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../store_settings/store_settings_controller.dart';
import 'order_receipt_sheet.dart';
import 'order_status_style.dart';
import 'orders_controller.dart';

class StaffOrderDetailPage extends ConsumerWidget {
  const StaffOrderDetailPage({super.key, required this.orderId});

  final String orderId;

  String _labelStatus(String status) {
    final key = staffOrderStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  String _labelSource(String source) {
    final key = staffOrderSourceLabelKey(source);
    final label = t(key);
    return label == key ? source : label;
  }

  String _fulfillmentLabel(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return t('STORE_FORM.ORDER_FULFILLMENT_COUNTER');
    }
    switch (value) {
      case 'counter':
        return t('STORE_FORM.ORDER_FULFILLMENT_COUNTER');
      case 'pickup':
        return t('STORE_FORM.ORDER_FULFILLMENT_PICKUP');
      case 'delivery':
        return t('STORE_FORM.ORDER_FULFILLMENT_DELIVERY');
      default:
        return raw!.trim();
    }
  }

  String _paymentLabel(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    if (value.length == 1) return value.toUpperCase();
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  Future<void> _openCall(WidgetRef ref, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    await ref.read(linkOpenerProvider).open(Uri.parse('tel:$digits'));
  }

  Future<void> _openWhatsApp(WidgetRef ref, String phone) async {
    final uri = whatsAppUri(number: phone);
    if (uri == null) return;
    await ref.read(linkOpenerProvider).open(uri);
  }

  void _printBill(
    BuildContext context,
    WidgetRef ref,
    StaffOrderDetail detail,
  ) {
    final store = ref.read(storeSettingsProvider).store;
    final receipt = PosReceiptSnapshot.fromOrder(store: store, order: detail);
    showOrderReceiptPreview(context, receipt: receipt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(staffOrderDetailProvider(orderId));
    final theme = Theme.of(context);
    final detail = state.detail;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context, fallback: Routes.staffOrders),
        ),
        title: detail == null
            ? t('STORE_FORM.ORDER_VIEW')
            : '${t('STOREFRONT.ORDER_NUMBER')} #${detail.orderNumber}',
        actions: <Widget>[
          if (detail != null && detail.nextStatuses.isNotEmpty)
            TextButton(
              onPressed: () => context.push(Routes.staffOrderEdit(orderId)),
              child: Text(
                t('MORE.EDIT_ORDER'),
                style: const TextStyle(color: AppTheme.onTeal),
              ),
            ),
          StaffAppBarAction.refresh(
            enabled: !state.busy,
            onPressed: () => ref
                .read(staffOrderDetailProvider(orderId).notifier)
                .refresh(),
          ),
        ],
      ),
      body: state.loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? Center(child: Text(state.error ?? t('ERROR_GENERIC')))
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        children: <Widget>[
                          _HeroCard(
                            detail: detail,
                            statusLabel: _labelStatus(detail.status),
                            sourceLabel: _labelSource(detail.source),
                          ),
                          if (state.error != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              state.error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _InfoPairRow(
                            customer: _CustomerCard(
                              name: detail.displayCustomer,
                              phone: detail.customerPhone,
                              onCall: detail.customerPhone.trim().isEmpty
                                  ? null
                                  : () => _openCall(ref, detail.customerPhone),
                              onWhatsApp: detail.customerPhone.trim().isEmpty
                                  ? null
                                  : () =>
                                      _openWhatsApp(ref, detail.customerPhone),
                            ),
                            information: _OrderInfoCard(
                              orderType: _fulfillmentLabel(
                                detail.fulfillmentType,
                              ),
                              payment: _paymentLabel(detail.paymentMethod),
                              statusLabel: _labelStatus(detail.status),
                              statusColor: orderStatusAccent(detail.status),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionHeader(
                            icon: Icons.inventory_2_outlined,
                            title: t('STORE_FORM.ORDER_ITEMS_COUNT').replaceAll(
                              '{count}',
                              '${detail.items.length}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in detail.items) ...<Widget>[
                            _ItemCard(item: item),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 6),
                          _SectionHeader(
                            icon: Icons.receipt_long_outlined,
                            title: t('STORE_FORM.ORDER_BILL_SUMMARY'),
                          ),
                          const SizedBox(height: 8),
                          _BillSummaryCard(detail: detail),
                          if (detail.history.isNotEmpty ||
                              detail.placedAt.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            _SectionHeader(
                              icon: Icons.schedule_rounded,
                              title: t('STORE_FORM.ORDER_TIMELINE'),
                            ),
                            const SizedBox(height: 8),
                            _TimelineCard(
                              detail: detail,
                              statusLabel: _labelStatus,
                              paymentLabel: _paymentLabel(detail.paymentMethod),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _BottomActions(
                      canReturn: detail.status == 'delivered',
                      onPrint: () => _printBill(context, ref, detail),
                      onReturn: () => context.push(
                        '${Routes.staffReturnNew}?orderId=${detail.id}',
                      ),
                      onReorder: () => context.push(Routes.staffPos),
                    ),
                  ],
                ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.detail,
    required this.statusLabel,
    required this.sourceLabel,
  });

  final StaffOrderDetail detail;
  final String statusLabel;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = orderStatusAccent(detail.status);
    final placed = DateTime.tryParse(detail.placedAt)?.toLocal();
    final itemsLabel = detail.items.length == 1
        ? '1 ${t('STORE_FORM.POS_RECEIPT_ITEM')}'
        : '${detail.items.length} ${t('STORE_FORM.ORDER_ITEMS')}';

    return Material(
      color: const Color(0xFFEDF8F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Brand.themeColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.hairlineColor),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: Brand.themeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${t('STOREFRONT.ORDER_NUMBER')} #${detail.orderNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (placed != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      '${t('STORE_FORM.ORDER_PLACED_ON')} ${Format.dateTime(placed)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _FilledStatusChip(
                        label: statusLabel,
                        color: accent,
                        icon: orderStatusIcon(detail.status),
                      ),
                      _SoftChip(
                        icon: orderSourceIcon(detail.source),
                        label: sourceLabel,
                      ),
                      _SoftChip(
                        icon: Icons.inventory_2_outlined,
                        label: itemsLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: AppTheme.hairlineColor,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  t('STORE_FORM.ORDER_AMOUNT_TITLE'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Format.rupee(detail.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.themeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPairRow extends StatelessWidget {
  const _InfoPairRow({
    required this.customer,
    required this.information,
  });

  final Widget customer;
  final Widget information;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final stack = constraints.maxWidth < 340;
        if (stack) {
          return Column(
            children: <Widget>[
              customer,
              const SizedBox(height: 8),
              information,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: customer),
              const SizedBox(width: 8),
              Expanded(child: information),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.name,
    required this.phone,
    this.onCall,
    this.onWhatsApp,
  });

  final String name;
  final String phone;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPhone = phone.trim().isNotEmpty;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.person_outline, size: 16, color: Brand.themeColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  t('STORE_FORM.ORDER_CUSTOMER_DETAILS'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showPhone && name != phone) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _RoundIconButton(
                icon: Icons.call_outlined,
                color: Brand.themeColor,
                onTap: onCall,
              ),
              const SizedBox(width: 8),
              _RoundIconButton(
                icon: Icons.chat_outlined,
                color: const Color(0xFF25D366),
                onTap: onWhatsApp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({
    required this.orderType,
    required this.payment,
    required this.statusLabel,
    required this.statusColor,
  });

  final String orderType;
  final String payment;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.assignment_outlined, size: 16, color: Brand.themeColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  t('STORE_FORM.ORDER_INFORMATION'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MiniRow(label: t('TODAY.ORDER_TYPE'), value: orderType),
          const SizedBox(height: 4),
          _MiniRow(label: t('STORE_FORM.PAYMENT_METHOD'), value: payment),
          const SizedBox(height: 4),
          _MiniRow(
            label: t('STORE_FORM.ORDER_STATUS'),
            value: statusLabel,
            valueColor: statusColor,
          ),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.55),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final StaffOrderLine item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = (item.baseUnitLabel ?? 'unit').trim();
    final pack = (item.packLabel ?? 'Unit').trim();
    final meta = '$pack • ${Format.rupee(item.unitPrice)} / $unit';

    return _WhiteCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Thumb(name: item.productName, url: item.imageUrl, size: 52),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if ((item.manufacturer ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    item.manufacturer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Format.rupee(item.totalPrice),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('STORE_FORM.ORDER_QTY')
                    .replaceAll('{count}', '${item.quantity}'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({required this.detail});

  final StaffOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: <Widget>[
                _BillRow(
                  label: t('STORE_FORM.ORDER_ITEMS_TOTAL').replaceAll(
                    '{count}',
                    '${detail.items.length}',
                  ),
                  value: Format.rupee(detail.subtotal),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        t('STORE_FORM.ORDER_DISCOUNT'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        Format.rupee(detail.discountAmount),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.deliveryCharge > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  _BillRow(
                    label: t('STORE_FORM.ORDER_DELIVERY'),
                    value: Format.rupee(detail.deliveryCharge),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final count = (constraints.maxWidth / 6).floor().clamp(10, 80);
                return Text(
                  List.filled(count, '-').join(),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.28),
                    letterSpacing: 1,
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t('STORE_FORM.ORDER_TOTAL_AMOUNT'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  Format.rupee(detail.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Brand.themeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.detail,
    required this.statusLabel,
    required this.paymentLabel,
  });

  final StaffOrderDetail detail;
  final String Function(String status) statusLabel;
  final String paymentLabel;

  @override
  Widget build(BuildContext context) {
    final events = <_TimelineEvent>[];
    final placed = DateTime.tryParse(detail.placedAt)?.toLocal();
    events.add(
      _TimelineEvent(
        label: t('STORE_FORM.ORDER_TIMELINE_PLACED'),
        at: placed,
        accent: Brand.themeColor,
      ),
    );

    final paid = detail.paymentStatus?.toLowerCase() == 'paid' ||
        (detail.paymentMethod ?? '').trim().isNotEmpty;
    if (paid) {
      events.add(
        _TimelineEvent(
          label: t('STORE_FORM.ORDER_TIMELINE_PAID').replaceAll(
            '{method}',
            paymentLabel,
          ),
          at: placed,
          accent: Brand.themeColor,
        ),
      );
    }

    if (detail.history.isNotEmpty) {
      for (final event in detail.history) {
        if (event.toStatus == 'pending' || event.toStatus == 'draft') continue;
        events.add(
          _TimelineEvent(
            label: statusLabel(event.toStatus),
            at: DateTime.tryParse(event.createdAt)?.toLocal(),
            accent: orderStatusAccent(event.toStatus),
            highlight: event.toStatus == detail.status,
          ),
        );
      }
    } else {
      events.add(
        _TimelineEvent(
          label: statusLabel(detail.status),
          at: placed,
          accent: orderStatusAccent(detail.status),
          highlight: true,
        ),
      );
    }

    return _WhiteCard(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < events.length; i++)
            _TimelineTile(
              event: events[i],
              isLast: i == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.label,
    required this.accent,
    this.at,
    this.highlight = false,
  });

  final String label;
  final DateTime? at;
  final Color accent;
  final bool highlight;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});

  final _TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: event.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: event.accent.withValues(alpha: 0.35),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (event.at != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    Format.dateTime(event.at!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    if (!event.highlight) return child;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: orderStatusWash(
          event.accent == Brand.themeColor ? 'delivered' : 'ready',
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.canReturn,
    required this.onPrint,
    required this.onReturn,
    required this.onReorder,
  });

  final bool canReturn;
  final VoidCallback onPrint;
  final VoidCallback onReturn;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _ActionButton(
                  onPressed: onPrint,
                  filled: false,
                  icon: Icons.print_outlined,
                  label: t('STORE_FORM.ORDER_PRINT_BILL'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ActionButton(
                  onPressed: canReturn ? onReturn : null,
                  filled: false,
                  icon: Icons.undo_rounded,
                  label: t('STORE_FORM.ORDER_REFUND_RETURN'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ActionButton(
                  onPressed: onReorder,
                  filled: true,
                  icon: Icons.refresh_rounded,
                  label: t('STORE_FORM.ORDER_REORDER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.filled,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool filled;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Brand.themeColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 44),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 44),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Brand.themeColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _FilledStatusChip extends StatelessWidget {
  const _FilledStatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: Brand.themeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Brand.themeColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.name,
    required this.url,
    required this.size,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: Brand.themeBackground,
        child: SizedBox(
          width: size,
          height: size,
          child: url != null && url!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  errorWidget:
                      (BuildContext context, String url, Object error) {
                    return _fallback();
                  },
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    final trimmed = name.trim();
    final letters = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
    return Center(
      child: Text(
        letters.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
