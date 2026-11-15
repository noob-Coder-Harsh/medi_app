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
import 'customers_controller.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openCustomer(StaffCustomer customer) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) => _CustomerSheet(customer: customer),
    );
  }

  Future<void> _pickSort(CustomersState state) async {
    final selected = await showModalBottomSheet<CustomerSort>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final sort in CustomerSort.values)
                ListTile(
                  leading: Icon(
                    state.sort == sort
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: state.sort == sort
                        ? Brand.themeColor
                        : AppTheme.ink.withValues(alpha: 0.35),
                  ),
                  title: Text(_sortLabel(sort)),
                  onTap: () => Navigator.pop(context, sort),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    ref.read(customersProvider.notifier).setSort(selected);
  }

  String _sortLabel(CustomerSort sort) {
    switch (sort) {
      case CustomerSort.highestDue:
        return t('STORE_FORM.CUSTOMERS_SORT_HIGHEST_DUE');
      case CustomerSort.lowestDue:
        return t('STORE_FORM.CUSTOMERS_SORT_LOWEST_DUE');
      case CustomerSort.nameAsc:
        return t('STORE_FORM.CUSTOMERS_SORT_NAME');
      case CustomerSort.recent:
        return t('STORE_FORM.CUSTOMERS_SORT_RECENT');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(customersProvider);
    final theme = Theme.of(context);
    final visible = state.visibleItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.CUSTOMERS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: UnfocusOnTap(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t('STORE_FORM.CUSTOMERS_SUBTITLE'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.62),
                    height: 1.25,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: StaffSearchField(
                      controller: _search,
                      height: 44,
                      fillColor: Colors.white,
                      hintText: t('STORE_FORM.SEARCH_CUSTOMERS'),
                      showLoading:
                          state.loading && _search.text.trim().isNotEmpty,
                      onChanged: (String value) {
                        ref.read(customersProvider.notifier).setQuery(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.hairlineColor),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _pickSort(state),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: Brand.themeColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _StatsRow(
              total: state.totalCount,
              clear: state.clearCount,
              due: state.dueCount,
              loading: state.loading && state.items.isEmpty,
              filter: state.filter,
              onSelect: (CustomerDueFilter value) {
                ref.read(customersProvider.notifier).setFilter(value);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          _FilterChip(
                            label: t('STORE_FORM.CUSTOMERS_FILTER_ALL'),
                            selected: state.filter == CustomerDueFilter.all,
                            accent: Brand.themeColor,
                            fillWhenUnselected: Colors.white,
                            onTap: () => ref
                                .read(customersProvider.notifier)
                                .setFilter(CustomerDueFilter.all),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label:
                                '${t('STORE_FORM.CUSTOMERS_FILTER_DUE')} (${state.dueCount})',
                            selected: state.filter == CustomerDueFilter.due,
                            accent: AppTheme.error,
                            fillWhenUnselected: const Color(0xFFFEE2E2),
                            onTap: () => ref
                                .read(customersProvider.notifier)
                                .setFilter(CustomerDueFilter.due),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label:
                                '${t('STORE_FORM.CUSTOMERS_FILTER_CLEAR')} (${state.clearCount})',
                            selected: state.filter == CustomerDueFilter.clear,
                            accent: const Color(0xFF15803D),
                            fillWhenUnselected: Colors.white,
                            onTap: () => ref
                                .read(customersProvider.notifier)
                                .setFilter(CustomerDueFilter.clear),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(color: AppTheme.hairlineColor),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _pickSort(state),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _sortLabel(state.sort),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppTheme.ink.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
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
                          icon: Icons.people_outline,
                          message: t('STORE_FORM.CUSTOMERS_NO_RESULTS'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final item = visible[index];
                            return _CustomerCard(
                              item: item,
                              query: state.query,
                              onTap: () => _openCustomer(item),
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
    required this.total,
    required this.clear,
    required this.due,
    required this.loading,
    required this.filter,
    required this.onSelect,
  });

  final int total;
  final int clear;
  final int due;
  final bool loading;
  final CustomerDueFilter filter;
  final ValueChanged<CustomerDueFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _StatTile(
              icon: Icons.groups_outlined,
              value: total,
              label: t('STORE_FORM.CUSTOMERS_STAT_TOTAL'),
              tint: Brand.themeColor,
              background: Colors.white,
              loading: loading,
              selected: filter == CustomerDueFilter.all,
              onTap: () => onSelect(CustomerDueFilter.all),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.check_circle_outline,
              value: clear,
              label: t('STORE_FORM.CUSTOMERS_STAT_CLEAR'),
              tint: const Color(0xFF15803D),
              background: Colors.white,
              loading: loading,
              selected: filter == CustomerDueFilter.clear,
              onTap: () => onSelect(CustomerDueFilter.clear),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              icon: Icons.warning_amber_rounded,
              value: due,
              label: t('STORE_FORM.CUSTOMERS_STAT_DUE'),
              tint: AppTheme.error,
              background: const Color(0xFFFEE2E2),
              loading: loading,
              selected: filter == CustomerDueFilter.due,
              onTap: () => onSelect(CustomerDueFilter.due),
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
    required this.value,
    required this.label,
    required this.tint,
    required this.background,
    required this.loading,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color tint;
  final Color background;
  final bool loading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? tint : AppTheme.hairlineColor,
          width: selected ? 1.5 : 1,
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
                loading ? '—' : Format.stock(value),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
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
    required this.selected,
    required this.accent,
    required this.onTap,
    this.fillWhenUnselected = Colors.white,
  });

  final String label;
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
          child: Text(
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
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.item,
    required this.onTap,
    this.query,
  });

  final StaffCustomer item;
  final VoidCallback onTap;
  final String? query;

  bool get _hasDue => item.currentBalance > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _hasDue ? AppTheme.error : Brand.themeColor;
    final wash = _hasDue ? const Color(0xFFFFF7F7) : Colors.white;
    final last = _formatLastOrder(item.lastOrderAt);

    return Material(
      color: wash,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _hasDue
              ? AppTheme.error.withValues(alpha: 0.18)
              : AppTheme.hairlineColor,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _InitialsAvatar(
                name: item.displayName,
                accent: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HighlightedText(
                      item.displayName,
                      query: query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: AppTheme.ink,
                      ),
                    ),
                    if (_hasDistinctPhone(item)) ...<Widget>[
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: AppTheme.ink.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: HighlightedText(
                              _displayPhone(item.phone),
                              query: query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: _MetaChip(
                            icon: Icons.shopping_cart_outlined,
                            label: t('STORE_FORM.CUSTOMERS_ORDERS_COUNT')
                                .replaceAll('{count}', '${item.totalOrders}'),
                          ),
                        ),
                        if (last != null) ...<Widget>[
                          const SizedBox(width: 6),
                          Flexible(
                            child: _MetaChip(
                              icon: Icons.calendar_today_outlined,
                              label: t('STORE_FORM.CUSTOMERS_LAST_ORDER')
                                  .replaceAll('{date}', last),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (_hasDue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        t('STORE_FORM.CUSTOMERS_OUTSTANDING'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.error.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Format.rupee(item.currentBalance),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle,
                        size: 13,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t('STORE_FORM.CUSTOMERS_NO_DUES'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF15803D),
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.ink.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.accent,
  });

  final String name;
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
      child: Text(
        _initials(name),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
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

class _CustomerSheet extends ConsumerStatefulWidget {
  const _CustomerSheet({required this.customer});

  final StaffCustomer customer;

  @override
  ConsumerState<_CustomerSheet> createState() => _CustomerSheetState();
}

class _CustomerSheetState extends ConsumerState<_CustomerSheet> {
  late final TextEditingController _amount = TextEditingController();
  late final FocusNode _amountFocus = FocusNode();
  String _method = 'cash';
  String? _error;

  bool get _hasDue => widget.customer.currentBalance > 0;

  @override
  void initState() {
    super.initState();
    if (_hasDue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    setState(() => _error = null);
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = t('STORE_FORM.PAYMENT_AMOUNT'));
      return;
    }
    if (amount > widget.customer.currentBalance) {
      setState(
        () =>
            _error = t('STORE_FORM.PAYMENT_SETTLEMENT_EXCEEDS_CUSTOMER_BALANCE'),
      );
      return;
    }
    final error = await ref.read(customersProvider.notifier).collectDues(
          customerId: widget.customer.customerId,
          amount: amount,
          method: _method,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(customersProvider).busy;
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final customer = widget.customer;
    final last = _formatLastOrder(customer.lastOrderAt);

    return UnfocusOnTap(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _InitialsAvatar(
                    name: customer.displayName,
                    accent: _hasDue ? AppTheme.error : Brand.themeColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          customer.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_hasDistinctPhone(customer)) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            _displayPhone(customer.phone),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            _MetaChip(
                              icon: Icons.shopping_cart_outlined,
                              label: t('STORE_FORM.CUSTOMERS_ORDERS_COUNT')
                                  .replaceAll(
                                '{count}',
                                '${customer.totalOrders}',
                              ),
                            ),
                            if (last != null)
                              _MetaChip(
                                icon: Icons.calendar_today_outlined,
                                label: t('STORE_FORM.CUSTOMERS_LAST_ORDER')
                                    .replaceAll('{date}', last),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_hasDue)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              t('STORE_FORM.CUSTOMERS_OUTSTANDING'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.error.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              Format.rupee(customer.currentBalance),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t('STORE_FORM.CUSTOMERS_NO_DUES'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF15803D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_hasDue) ...<Widget>[
                const SizedBox(height: 18),
                Text(
                  t('STORE_FORM.PAYMENT_COLLECT_DUES'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t('STORE_FORM.CUSTOMERS_COLLECT_HINT'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amount,
                  focusNode: _amountFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.CUSTOMERS_COLLECT_RETURNING'),
                    prefixText: '₹ ',
                    helperText:
                        '${t('STORE_FORM.PAYMENT_CUSTOMER_BALANCE')}: ${Format.rupee(customer.currentBalance)}',
                  ),
                ),
                const SizedBox(height: 10),
                StaffSheetSelectField(
                  value: _method,
                  enabled: !busy,
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
                  ),
                  title: t('STORE_FORM.PAYMENT_METHOD'),
                  headerIcon: Icons.payments_outlined,
                  onChanged: (String value) => setState(() => _method = value),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : _collect,
                  child: Text(t('STORE_FORM.PAYMENT_ADD_CUSTOMER')),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _hasDistinctPhone(StaffCustomer customer) {
  final name = customer.name?.trim() ?? '';
  return name.isNotEmpty;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final value = parts.first;
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String _displayPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    final local = digits.substring(2);
    return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
  }
  if (digits.length == 10) {
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }
  return phone;
}

String? _formatLastOrder(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final when = DateTime.tryParse(raw)?.toLocal();
  if (when == null) return null;
  try {
    return DateFormat('dd MMM').format(when);
  } catch (_) {
    return Format.date(when);
  }
}
