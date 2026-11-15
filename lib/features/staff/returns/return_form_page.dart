import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_order.dart';
import '../shell/staff_app_bar.dart';
import '../ui/staff_ui.dart';
import 'returns_controller.dart';

class ReturnFormPage extends ConsumerStatefulWidget {
  const ReturnFormPage({super.key, this.prefillOrderId});

  final String? prefillOrderId;

  @override
  ConsumerState<ReturnFormPage> createState() => _ReturnFormPageState();
}

class _ReturnFormPageState extends ConsumerState<ReturnFormPage> {
  final _reason = TextEditingController();
  final _notes = TextEditingController();
  final _orderSearch = TextEditingController();
  var _prefillTried = false;

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    _orderSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(returnFormProvider);
    final theme = Theme.of(context);

    final prefill = widget.prefillOrderId;
    if (!_prefillTried &&
        prefill != null &&
        prefill.isNotEmpty &&
        state.orderId == null &&
        !state.loading) {
      _prefillTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(returnFormProvider.notifier).selectOrder(prefill);
      });
    }

    final hasOrder = state.orderDetail != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffReturns),
        ),
        title: t('STORE_FORM.RETURN_INITIATE'),
      ),
      body: state.loading && state.orderDetail == null
          ? const Center(child: CircularProgressIndicator())
          : UnfocusOnTap(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      children: <Widget>[
                        Text(
                          t('STORE_FORM.RETURN_INITIATE_SUBTITLE'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.62),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _localizeError(state.error!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        if (!hasOrder) ...<Widget>[
                          Text(
                            t('STORE_FORM.RETURN_FROM_ORDER'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StaffSearchField(
                            controller: _orderSearch,
                            height: 44,
                            fillColor: Colors.white,
                            hintText: t('STORE_FORM.SEARCH_ORDERS'),
                            showLoading: state.loading &&
                                _orderSearch.text.trim().isNotEmpty,
                            onChanged: (String value) => ref
                                .read(returnFormProvider.notifier)
                                .setOrderQuery(value),
                          ),
                          const SizedBox(height: 10),
                          if (state.deliveredOrders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  t('STORE_FORM.ORDERS_NO_RESULTS'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.ink.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...state.deliveredOrders.map(
                              (StaffOrderListItem order) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _OrderPickCard(
                                    order: order,
                                    onTap: () => ref
                                        .read(returnFormProvider.notifier)
                                        .selectOrder(order.id),
                                  ),
                                );
                              },
                            ),
                        ] else ...<Widget>[
                          _SelectedOrderCard(
                            detail: state.orderDetail!,
                            enabled: !state.busy,
                            onChange: () =>
                                ref.read(returnFormProvider.notifier).clearOrder(),
                          ),
                          const SizedBox(height: 18),
                          _StepHeader(
                            step: 1,
                            title: t('STORE_FORM.RETURN_STEP_ITEMS'),
                          ),
                          const SizedBox(height: 10),
                          ...state.lines.map((ReturnFormLine line) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ReturnItemCard(
                                line: line,
                                busy: state.busy,
                                onToggle: (bool selected) => ref
                                    .read(returnFormProvider.notifier)
                                    .toggleLine(line.orderItemId, selected),
                                onQty: (int qty) => ref
                                    .read(returnFormProvider.notifier)
                                    .setLineQty(line.orderItemId, qty),
                                onCondition: (String value) => ref
                                    .read(returnFormProvider.notifier)
                                    .setLineCondition(line.orderItemId, value),
                                onRestock: (String value) => ref
                                    .read(returnFormProvider.notifier)
                                    .setLineRestock(line.orderItemId, value),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                          _StepHeader(
                            step: 2,
                            title: t('STORE_FORM.RETURN_STEP_DETAILS'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _reason,
                            onChanged: (String value) => ref
                                .read(returnFormProvider.notifier)
                                .setReason(value),
                            decoration: InputDecoration(
                              labelText: t('STORE_FORM.RETURN_REASON'),
                              hintText: t('STORE_FORM.RETURN_REASON_HINT'),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(
                                Icons.swap_horiz_rounded,
                                color: Brand.themeColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notes,
                            minLines: 2,
                            maxLines: 4,
                            onChanged: (String value) => ref
                                .read(returnFormProvider.notifier)
                                .setNotes(value),
                            decoration: InputDecoration(
                              labelText: t('STORE_FORM.RETURN_NOTES'),
                              hintText: t('STORE_FORM.RETURN_NOTES_HINT'),
                              filled: true,
                              fillColor: Colors.white,
                              alignLabelWithHint: true,
                              prefixIcon: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Brand.themeColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ],
                    ),
                  ),
                  if (hasOrder)
                    _RefundFooter(
                      amount: state.refundEstimate,
                      itemCount: state.selectedItemCount,
                      qty: state.selectedQty,
                      busy: state.busy,
                      onSubmit: () => _submit(context),
                    ),
                ],
              ),
            ),
    );
  }

  String _localizeError(String raw) {
    if (raw.startsWith('STORE_FORM.')) {
      final label = t(raw);
      return label == raw ? raw : label;
    }
    return raw;
  }

  Future<void> _submit(BuildContext context) async {
    final error = await ref.read(returnFormProvider.notifier).submit();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_localizeError(error))),
      );
      return;
    }
    final id = ref.read(returnFormProvider).createdReturnId;
    if (id == null || id.isEmpty) return;
    context.go(Routes.staffReturn(id));
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Brand.themeColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _SelectedOrderCard extends StatelessWidget {
  const _SelectedOrderCard({
    required this.detail,
    required this.enabled,
    required this.onChange,
  });

  final StaffOrderDetail detail;
  final bool enabled;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateTime.tryParse(detail.placedAt)?.toLocal();
    final phone = detail.customerPhone.trim();
    final customer = phone.isEmpty
        ? detail.displayCustomer
        : '${detail.displayCustomer} · $phone';
    final itemsLabel =
        '${detail.items.length} ${t('STORE_FORM.RETURN_ITEMS').toLowerCase()}';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Brand.themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: Brand.themeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${t('STORE_FORM.RETURN_ORDER')} #${detail.orderNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: <Widget>[
                      if (when != null)
                        _InlineMeta(
                          icon: Icons.calendar_today_outlined,
                          label: Format.dateTime(when),
                        ),
                      _InlineMeta(
                        icon: Icons.shopping_cart_outlined,
                        label: itemsLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  Format.rupee(detail.totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: enabled ? onChange : null,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(t('STORE_FORM.RETURN_CHANGE_ORDER')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderPickCard extends StatelessWidget {
  const _OrderPickCard({required this.order, required this.onTap});

  final StaffOrderListItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateTime.tryParse(order.placedAt)?.toLocal();

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Brand.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Brand.themeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '#${order.orderNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.displayCustomer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.68),
                      ),
                    ),
                    if (when != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        Format.dateTime(when),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                Format.rupee(order.totalAmount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.ink.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnItemCard extends StatelessWidget {
  const _ReturnItemCard({
    required this.line,
    required this.busy,
    required this.onToggle,
    required this.onQty,
    required this.onCondition,
    required this.onRestock,
  });

  final ReturnFormLine line;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQty;
  final ValueChanged<String> onCondition;
  final ValueChanged<String> onRestock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = line.selected;
    final borderColor = selected
        ? Brand.themeColor.withValues(alpha: 0.55)
        : AppTheme.hairlineColor;
    final bg = selected
        ? Brand.themeColor.withValues(alpha: 0.06)
        : Colors.white;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              onTap: busy ? null : () => onToggle(!selected),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: <Widget>[
                  _ProductThumb(name: line.productName, url: line.imageUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          line.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t('STORE_FORM.RETURN_SOLD_QTY')}: ${line.soldQty}'
                          ' · ${Format.rupee(line.unitPrice)} ${t('STOREFRONT.EACH')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    onChanged: busy
                        ? null
                        : (bool? value) => onToggle(value ?? false),
                  ),
                ],
              ),
            ),
            if (selected) ...<Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      t('STORE_FORM.RETURN_QTY'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _QtyStepper(
                      quantity: line.quantity,
                      min: 1,
                      max: line.soldQty,
                      enabled: !busy,
                      onChanged: onQty,
                    ),
                    const SizedBox(height: 10),
                    StaffSheetSelectField(
                      value: line.condition,
                      enabled: !busy,
                      options: <StaffSelectOption>[
                        StaffSelectOption(
                          value: 'sealed',
                          label: t('STORE_FORM.RETURN_CONDITION_SEALED'),
                        ),
                        StaffSelectOption(
                          value: 'opened',
                          label: t('STORE_FORM.RETURN_CONDITION_OPENED'),
                        ),
                        StaffSelectOption(
                          value: 'damaged',
                          label: t('STORE_FORM.RETURN_CONDITION_DAMAGED'),
                        ),
                        StaffSelectOption(
                          value: 'expired',
                          label: t('STORE_FORM.RETURN_CONDITION_EXPIRED'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: t('STORE_FORM.RETURN_CONDITION'),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                      ),
                      title: t('STORE_FORM.RETURN_CONDITION'),
                      headerIcon: Icons.inventory_2_outlined,
                      onChanged: onCondition,
                    ),
                    const SizedBox(height: 8),
                    StaffSheetSelectField(
                      value: line.restockAction,
                      enabled: !busy,
                      options: <StaffSelectOption>[
                        StaffSelectOption(
                          value: 'restock',
                          label: t('STORE_FORM.RETURN_RESTOCK'),
                        ),
                        StaffSelectOption(
                          value: 'dispose',
                          label: t('STORE_FORM.RETURN_DISPOSE'),
                        ),
                        StaffSelectOption(
                          value: 'supplier_return',
                          label: t('STORE_FORM.RETURN_SUPPLIER_RETURN'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: t('STORE_FORM.RETURN_RESTOCK_ACTION'),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.replay_outlined),
                      ),
                      title: t('STORE_FORM.RETURN_RESTOCK_ACTION'),
                      headerIcon: Icons.replay_outlined,
                      onChanged: onRestock,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: 52,
          height: 52,
          child: url != null && url!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.contain,
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
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Brand.themeColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: !enabled || quantity <= min
                ? null
                : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          IconButton(
            onPressed: !enabled || quantity >= max
                ? null
                : () => onChanged(quantity + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 12,
          color: AppTheme.ink.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _RefundFooter extends StatelessWidget {
  const _RefundFooter({
    required this.amount,
    required this.itemCount,
    required this.qty,
    required this.busy,
    required this.onSubmit,
  });

  final double amount;
  final int itemCount;
  final int qty;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: const Color(0xFFE8F6F1),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Brand.themeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: Brand.themeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Format.rupee(amount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Brand.themeColor,
                    ),
                  ),
                ),
                Text(
                  '${t('STORE_FORM.RETURN_SUMMARY_ITEMS')}: $itemCount'
                  ' | ${t('STORE_FORM.RETURN_SUMMARY_QTY')}: $qty',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: AppTheme.chargeHeight,
              child: FilledButton.icon(
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.assignment_return_outlined),
                label: Text(t('STORE_FORM.RETURN_SUBMIT')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
