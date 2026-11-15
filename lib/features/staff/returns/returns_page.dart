import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/empty_list.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_return.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';
import 'return_status_style.dart';
import 'returns_controller.dart';

class ReturnsPage extends ConsumerStatefulWidget {
  const ReturnsPage({super.key});

  @override
  ConsumerState<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends ConsumerState<ReturnsPage> {
  final _search = TextEditingController();

  static const _statusFilters = <String>[
    'all',
    'pending',
    'approved',
    'rejected',
    'completed',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _statusChipLabel(String status) {
    if (status == 'all') return t('STORE_FORM.FILTER_ALL_RETURN_STATUS');
    final key = staffReturnStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(returnsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.RETURNS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () =>
                ref.read(returnsListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.staffReturnNew),
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_RETURN')),
      ),
      body: UnfocusOnTap(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t('STORE_FORM.RETURNS_SUBTITLE'),
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
                      hintText: t('STORE_FORM.SEARCH_RETURNS'),
                      showLoading:
                          state.loading && _search.text.trim().isNotEmpty,
                      onChanged: (String value) => ref
                          .read(returnsListProvider.notifier)
                          .setQuery(value),
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
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
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
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (BuildContext context, int index) {
                  final value = _statusFilters[index];
                  final selected = state.status == value;
                  return _StatusRailChip(
                    label: _statusChipLabel(value),
                    selected: selected,
                    accent: value == 'all'
                        ? Brand.themeColor
                        : returnStatusAccent(value),
                    icon: value == 'all'
                        ? Icons.assignment_return_outlined
                        : returnStatusIcon(value),
                    onTap: () => ref
                        .read(returnsListProvider.notifier)
                        .setStatus(value),
                  );
                },
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
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _body(ReturnsListState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      final hasFilters =
          state.status != 'all' || state.query.trim().isNotEmpty;
      return EmptyListBody(
        icon: Icons.assignment_return_outlined,
        message: t(
          hasFilters
              ? 'STORE_FORM.RETURNS_NO_RESULTS'
              : 'STORE_FORM.RETURNS_NO_RESULTS',
        ),
        action: FilledButton(
          onPressed: () => context.push(Routes.staffReturnNew),
          child: Text(t('STORE_FORM.ADD_RETURN')),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 96),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final item = state.items[index];
        return _ReturnCard(
          item: item,
          query: state.query,
          onTap: () => context.push(Routes.staffReturn(item.id)),
        );
      },
    );
  }
}

class _StatusRailChip extends StatelessWidget {
  const _StatusRailChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Brand.themeColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? Brand.themeColor : AppTheme.hairlineColor,
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
                      color: selected ? Colors.white : accent,
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

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({
    required this.item,
    required this.onTap,
    this.query,
  });

  final StaffReturnListItem item;
  final VoidCallback onTap;
  final String? query;

  String _statusLabel() {
    final key = staffReturnStatusLabelKey(item.status);
    final label = t(key);
    return label == key ? item.status : label;
  }

  String _itemsLabel() {
    final count = item.itemCount;
    final unit = count == 1
        ? t('STORE_FORM.POS_RECEIPT_ITEM')
        : t('STORE_FORM.RETURN_ITEMS');
    return '$count $unit'.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = returnStatusAccent(item.status);
    final wash = returnStatusWash(item.status);
    final border = returnStatusBorder(item.status);
    final when = DateTime.tryParse(item.createdAt)?.toLocal();
    final orderLabel = item.orderNumber == null
        ? '#${item.shortId}'
        : '#${item.orderNumber}';
    final phone = item.customerPhone.trim();

    return Material(
      color: wash,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _PackageIcon(accent: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            HighlightedText(
                              orderLabel,
                              query: query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            HighlightedText(
                              item.displayCustomer,
                              query: query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: AppTheme.ink,
                              ),
                            ),
                            if (phone.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
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
                                      phone,
                                      query: query,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.ink
                                            .withValues(alpha: 0.62),
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
                                    icon: Icons.inventory_2_outlined,
                                    label: _itemsLabel(),
                                  ),
                                ),
                                if (when != null) ...<Widget>[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _MetaChip(
                                      icon: Icons.calendar_today_outlined,
                                      label: Format.dateTime(when),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 118),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _StatusBadge(
                              label: _statusLabel(),
                              accent: accent,
                              icon: returnStatusIcon(item.status),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Format.rupee(item.refundAmount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageIcon extends StatelessWidget {
  const _PackageIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 20,
        color: accent,
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
        color: Colors.white.withValues(alpha: 0.72),
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
