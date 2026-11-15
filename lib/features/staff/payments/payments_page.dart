import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/brand.dart';
import '../../../core/empty_list.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_books.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';
import 'payments_controller.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) => const _AddPaymentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final visible = state.visibleItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.PAYMENTS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref.read(paymentsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.busy ? null : _addPayment,
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_PAYMENT')),
      ),
      body: UnfocusOnTap(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t('STORE_FORM.PAYMENTS_SUBTITLE'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.62),
                    height: 1.25,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: StaffSearchField(
                controller: _search,
                height: 44,
                fillColor: Colors.white,
                hintText: t('STORE_FORM.SEARCH_PAYMENTS'),
                showLoading:
                    state.loading && _search.text.trim().isNotEmpty,
                onChanged: (String value) {
                  ref.read(paymentsProvider.notifier).setQuery(value);
                },
              ),
            ),
            _StatsRow(
              inflowTotal: state.inflowTotal,
              outflowTotal: state.outflowTotal,
              pendingCount: state.pendingCount,
              loading: state.loading && state.items.isEmpty,
              direction: state.direction,
              onSelect: (PaymentDirectionFilter value) {
                ref.read(paymentsProvider.notifier).setDirection(value);
              },
            ),
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _FilterChip(
                    label: t('STORE_FORM.CUSTOMERS_FILTER_ALL'),
                    icon: Icons.payments_outlined,
                    selected: state.direction == PaymentDirectionFilter.all,
                    accent: Brand.themeColor,
                    onTap: () => ref
                        .read(paymentsProvider.notifier)
                        .setDirection(PaymentDirectionFilter.all),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label:
                        '${t('STORE_FORM.PAYMENT_DIRECTION_INFLOW')} (${state.inflowCount})',
                    icon: Icons.south_west_rounded,
                    selected:
                        state.direction == PaymentDirectionFilter.inflow,
                    accent: const Color(0xFF15803D),
                    fillWhenUnselected: const Color(0xFFDCFCE7),
                    onTap: () => ref
                        .read(paymentsProvider.notifier)
                        .setDirection(PaymentDirectionFilter.inflow),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label:
                        '${t('STORE_FORM.PAYMENT_DIRECTION_OUTFLOW')} (${state.outflowCount})',
                    icon: Icons.north_east_rounded,
                    selected:
                        state.direction == PaymentDirectionFilter.outflow,
                    accent: AppTheme.error,
                    fillWhenUnselected: const Color(0xFFFEE2E2),
                    onTap: () => ref
                        .read(paymentsProvider.notifier)
                        .setDirection(PaymentDirectionFilter.outflow),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ),
            Expanded(
              child: state.loading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? EmptyListBody(
                          icon: Icons.payments_outlined,
                          message: t('STORE_FORM.PAYMENTS_NO_RESULTS'),
                          action: FilledButton(
                            onPressed: state.busy ? null : _addPayment,
                            child: Text(t('STORE_FORM.ADD_PAYMENT')),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 96),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            return _PaymentCard(
                              item: visible[index],
                              query: state.query,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.inflowTotal,
    required this.outflowTotal,
    required this.pendingCount,
    required this.loading,
    required this.direction,
    required this.onSelect,
  });

  final double inflowTotal;
  final double outflowTotal;
  final int pendingCount;
  final bool loading;
  final PaymentDirectionFilter direction;
  final ValueChanged<PaymentDirectionFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatTile(
              icon: Icons.south_west_rounded,
              valueText: loading ? '—' : Format.rupee(inflowTotal),
              label: t('STORE_FORM.PAYMENT_TOTAL_INBOUND'),
              tint: const Color(0xFF15803D),
              background: const Color(0xFFDCFCE7),
              selected: direction == PaymentDirectionFilter.inflow,
              onTap: () => onSelect(PaymentDirectionFilter.inflow),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.north_east_rounded,
              valueText: loading ? '—' : Format.rupee(outflowTotal),
              label: t('STORE_FORM.PAYMENT_TOTAL_OUTBOUND'),
              tint: AppTheme.error,
              background: const Color(0xFFFEE2E2),
              selected: direction == PaymentDirectionFilter.outflow,
              onTap: () => onSelect(PaymentDirectionFilter.outflow),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.schedule_outlined,
              valueText: loading ? '—' : Format.stock(pendingCount),
              label: t('STORE_FORM.PAYMENT_PENDING_COUNT'),
              tint: AppTheme.amber,
              background: const Color(0xFFFEF3C7),
              selected: false,
              onTap: () => onSelect(PaymentDirectionFilter.all),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.valueText,
    required this.label,
    required this.tint,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String valueText;
  final String label;
  final Color tint;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? tint : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 18, color: tint),
              const SizedBox(height: 8),
              Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.65),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.fillWhenUnselected = Colors.white,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final Color fillWhenUnselected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Brand.themeColor : fillWhenUnselected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? Brand.themeColor
              : (fillWhenUnselected == Colors.white
                  ? AppTheme.hairlineColor
                  : accent.withValues(alpha: 0.35)),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : accent,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? Colors.white
                          : (fillWhenUnselected == Colors.white
                              ? AppTheme.ink
                              : accent),
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.item, required this.query});

  final StaffPayment item;
  final String query;

  bool get _isOutflow => item.paymentDirection == 'outflow';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _isOutflow ? AppTheme.error : const Color(0xFF15803D);
    final wash =
        _isOutflow ? const Color(0xFFFFF7F7) : const Color(0xFFF7FDF9);
    final party = _partyLabel(item);
    final when = _formatWhen(item.paidAt ?? item.createdAt);
    final typeLabel = _typeLabel(item.paymentType);
    final methodLabel = _methodLabel(item.method);
    final statusLabel = _statusLabel(item.status);
    final statusAccent = _statusAccent(item.status);

    return Material(
      color: wash,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _DirectionIcon(
                      outflow: _isOutflow,
                      accent: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          HighlightedText(
                            party,
                            query: query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: <Widget>[
                              Icon(
                                _typeIcon(item.paymentType),
                                size: 12,
                                color: AppTheme.ink.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  typeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        AppTheme.ink.withValues(alpha: 0.62),
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              _MetaChip(
                                icon: _methodIcon(item.method),
                                label: methodLabel,
                              ),
                              if (when != null)
                                _MetaChip(
                                  icon: Icons.calendar_today_outlined,
                                  label: when,
                                ),
                              if (item.referenceNumber != null &&
                                  item.referenceNumber!.trim().isNotEmpty)
                                _MetaChip(
                                  icon: Icons.tag_outlined,
                                  label: item.referenceNumber!.trim(),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 118),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '${_isOutflow ? '−' : '+'}${Format.rupee(item.amount)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _StatusBadge(
                            label: statusLabel,
                            accent: statusAccent,
                            icon: _statusIcon(item.status),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionIcon extends StatelessWidget {
  const _DirectionIcon({
    required this.outflow,
    required this.accent,
  });

  final bool outflow;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        outflow ? Icons.north_east_rounded : Icons.south_west_rounded,
        size: 20,
        color: accent,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 11,
            color: AppTheme.ink.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    height: 1.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.accent,
    required this.icon,
  });

  final String label;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    height: 1.1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet();

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  bool _customerMode = true;
  String? _customerId;
  String? _supplierId;
  String _method = 'cash';
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = t('STORE_FORM.PAYMENT_AMOUNT'));
      return;
    }

    final notifier = ref.read(paymentsProvider.notifier);
    final String? error;
    if (_customerMode) {
      final customerId = _customerId;
      if (customerId == null) {
        setState(() => _error = t('STORE_FORM.PAYMENT_SELECT_CUSTOMER'));
        return;
      }
      error = await notifier.settleCustomer(
        CustomerSettlementInput(
          customerId: customerId,
          amount: amount,
          method: _method,
        ),
      );
    } else {
      final supplierId = _supplierId;
      if (supplierId == null) {
        setState(() => _error = t('STORE_FORM.PAYMENT_SELECT_SUPPLIER'));
        return;
      }
      error = await notifier.settleSupplier(
        SupplierSettlementInput(
          supplierId: supplierId,
          amount: amount,
          method: _method,
        ),
      );
    }

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final dueCustomers = state.customers
        .where((StaffCustomer c) => c.currentBalance > 0)
        .toList();
    final dueSuppliers = state.suppliers
        .where((StaffSupplier s) => s.currentBalance > 0)
        .toList();

    return UnfocusOnTap(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                t('STORE_FORM.ADD_PAYMENT'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: <ButtonSegment<bool>>[
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: Text(t('STORE_FORM.PAYMENT_ADD_CUSTOMER')),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: Text(t('STORE_FORM.PAYMENT_ADD_SUPPLIER')),
                  ),
                ],
                selected: <bool>{_customerMode},
                onSelectionChanged: (Set<bool> next) {
                  setState(() {
                    _customerMode = next.first;
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_customerMode)
                StaffSheetSelectField(
                  value: _customerId,
                  enabled: !state.busy && dueCustomers.isNotEmpty,
                  options: dueCustomers
                      .map(
                        (StaffCustomer c) => StaffSelectOption(
                          value: c.customerId,
                          label:
                              '${c.displayName} (${Format.rupee(c.currentBalance)})',
                        ),
                      )
                      .toList(growable: false),
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PAYMENT_SELECT_CUSTOMER'),
                    hintText: t('STORE_FORM.PAYMENT_SELECT_CUSTOMER'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  title: t('STORE_FORM.PAYMENT_SELECT_CUSTOMER'),
                  searchHint: t('STORE_FORM.SEARCH_CUSTOMERS'),
                  headerIcon: Icons.person_outline,
                  onChanged: (String value) =>
                      setState(() => _customerId = value),
                )
              else
                StaffSheetSelectField(
                  value: _supplierId,
                  enabled: !state.busy && dueSuppliers.isNotEmpty,
                  options: dueSuppliers
                      .map(
                        (StaffSupplier s) => StaffSelectOption(
                          value: s.id,
                          label:
                              '${s.name} (${Format.rupee(s.currentBalance)})',
                        ),
                      )
                      .toList(growable: false),
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PAYMENT_SELECT_SUPPLIER'),
                    hintText: t('STORE_FORM.PAYMENT_SELECT_SUPPLIER'),
                    prefixIcon: const Icon(Icons.local_shipping_outlined),
                  ),
                  title: t('STORE_FORM.PAYMENT_SELECT_SUPPLIER'),
                  searchHint: t('STORE_FORM.SEARCH_SUPPLIERS'),
                  headerIcon: Icons.local_shipping_outlined,
                  onChanged: (String value) =>
                      setState(() => _supplierId = value),
                ),
              if ((_customerMode && dueCustomers.isEmpty) ||
                  (!_customerMode && dueSuppliers.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t('STORE_FORM.PAYMENTS_NO_RESULTS'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PAYMENT_AMOUNT'),
                  prefixText: '₹ ',
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              StaffSheetSelectField(
                value: _method,
                enabled: !state.busy,
                options: <StaffSelectOption>[
                  StaffSelectOption(
                    value: 'cash',
                    label: t('STORE_FORM.PAYMENT_METHOD_CASH'),
                  ),
                  StaffSelectOption(
                    value: 'upi',
                    label: t('STORE_FORM.PAYMENT_METHOD_UPI'),
                  ),
                  StaffSelectOption(
                    value: 'bank_transfer',
                    label: t('STORE_FORM.PAYMENT_METHOD_BANK'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PAYMENT_METHOD'),
                  prefixIcon: Icon(_methodIcon(_method)),
                ),
                title: t('STORE_FORM.PAYMENT_METHOD'),
                headerIcon: Icons.payments_outlined,
                onChanged: (String value) => setState(() => _method = value),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.busy ? null : _submit,
                icon: state.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(t('STORE_FORM.ADD_PAYMENT')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _partyLabel(StaffPayment item) {
  return item.customerName ??
      item.supplierName ??
      item.orderNo ??
      item.purchaseInvoice ??
      '—';
}

String _typeLabel(String type) {
  return switch (type) {
    'purchase' => t('STORE_FORM.PAYMENT_TYPE_PURCHASE'),
    'refund' => t('STORE_FORM.PAYMENT_TYPE_REFUND'),
    'supplier_settlement' => t('STORE_FORM.PAYMENT_TYPE_SETTLEMENT'),
    'adjustment' => t('STORE_FORM.PAYMENT_TYPE_ADJUSTMENT'),
    _ => t('STORE_FORM.PAYMENT_TYPE_SALE'),
  };
}

IconData _typeIcon(String type) {
  return switch (type) {
    'purchase' => Icons.shopping_bag_outlined,
    'refund' => Icons.replay_outlined,
    'supplier_settlement' => Icons.handshake_outlined,
    'adjustment' => Icons.tune_rounded,
    _ => Icons.point_of_sale_outlined,
  };
}

String _methodLabel(String method) {
  return switch (method) {
    'upi' => t('STORE_FORM.PAYMENT_METHOD_UPI'),
    'card' => t('STORE_FORM.PAYMENT_METHOD_CARD'),
    'bank_transfer' => t('STORE_FORM.PAYMENT_METHOD_BANK'),
    'credit' => t('STORE_FORM.PAYMENT_METHOD_CREDIT'),
    'wallet' => t('STORE_FORM.PAYMENT_METHOD_WALLET'),
    _ => t('STORE_FORM.PAYMENT_METHOD_CASH'),
  };
}

IconData _methodIcon(String method) {
  return switch (method) {
    'upi' => Icons.qr_code_2_outlined,
    'card' => Icons.credit_card_outlined,
    'bank_transfer' => Icons.account_balance_outlined,
    'credit' => Icons.account_balance_wallet_outlined,
    'wallet' => Icons.wallet_outlined,
    _ => Icons.payments_outlined,
  };
}

String _statusLabel(String status) {
  return switch (status.toLowerCase()) {
    'pending' => t('STORE_FORM.PAYMENT_STATUS_PENDING'),
    'partial' => t('STORE_FORM.PAYMENT_STATUS_PARTIAL'),
    'failed' => t('STORE_FORM.PAYMENT_STATUS_FAILED'),
    'refunded' => t('STORE_FORM.PAYMENT_STATUS_REFUNDED'),
    'cancelled' => t('STORE_FORM.PAYMENT_STATUS_CANCELLED'),
    _ => t('STORE_FORM.PAYMENT_STATUS_PAID'),
  };
}

Color _statusAccent(String status) {
  return switch (status.toLowerCase()) {
    'pending' => AppTheme.amber,
    'partial' => const Color(0xFF2563EB),
    'failed' || 'cancelled' => AppTheme.error,
    'refunded' => const Color(0xFF7C3AED),
    _ => const Color(0xFF15803D),
  };
}

IconData _statusIcon(String status) {
  return switch (status.toLowerCase()) {
    'pending' => Icons.schedule_outlined,
    'partial' => Icons.timelapse_outlined,
    'failed' => Icons.error_outline,
    'refunded' => Icons.replay_outlined,
    'cancelled' => Icons.cancel_outlined,
    _ => Icons.check_circle_outline,
  };
}

String? _formatWhen(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final when = DateTime.tryParse(raw)?.toLocal();
  if (when == null) return null;
  try {
    return DateFormat('dd MMM, hh:mm a').format(when);
  } catch (_) {
    return Format.dateTime(when);
  }
}
