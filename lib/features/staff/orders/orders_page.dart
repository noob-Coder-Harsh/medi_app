import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/empty_list.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_order.dart';
import '../shell/staff_app_bar.dart';
import 'order_status_style.dart';
import 'orders_controller.dart';

class StaffOrdersPage extends ConsumerStatefulWidget {
  const StaffOrdersPage({super.key});

  @override
  ConsumerState<StaffOrdersPage> createState() => _StaffOrdersPageState();
}

class _StaffOrdersPageState extends ConsumerState<StaffOrdersPage> {
  final _search = TextEditingController();

  static const _statusFilters = <String>[
    'all',
    'pending',
    'confirmed',
    'processing',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];

  static const _sourceFilters = <String>['all', 'online', 'pos'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _statusChipLabel(String status) {
    if (status == 'all') return t('STORE_FORM.FILTER_ALL_STATUS');
    final key = staffOrderStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  String _sourceChipLabel(String source) {
    if (source == 'all') return t('STORE_FORM.FILTER_ALL_SOURCE');
    final key = staffOrderSourceLabelKey(source);
    final label = t(key);
    return label == key ? source : label;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(ordersListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: StaffAppBar(
        title: t('STORE_FORM.ORDERS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () => ref.read(ordersListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      style: theme.textTheme.bodyMedium,
                      onChanged: (String value) {
                        ref.read(ordersListProvider.notifier).setQuery(value);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        hintText: t('STORE_FORM.SEARCH_ORDERS'),
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppTheme.ink.withValues(alpha: 0.55),
                        ),
                        suffixIcon: state.loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.hairlineColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.hairlineColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Brand.themeColor,
                          ),
                        ),
                      ),
                    ),
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
                        // Visual parity with mock; barcode search not wired yet.
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 22,
                        color: Brand.themeColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ChipRail(
            itemCount: _statusFilters.length,
            itemBuilder: (BuildContext context, int index) {
              final value = _statusFilters[index];
              final selected = state.status == value;
              return _StatusRailChip(
                label: _statusChipLabel(value),
                selected: selected,
                accent: value == 'all'
                    ? Brand.themeColor
                    : orderStatusAccent(value),
                showDot: value != 'all',
                onTap: () =>
                    ref.read(ordersListProvider.notifier).setStatus(value),
              );
            },
          ),
          const SizedBox(height: 4),
          _ChipRail(
            height: 40,
            itemCount: _sourceFilters.length,
            itemBuilder: (BuildContext context, int index) {
              final value = _sourceFilters[index];
              return _SourceRailChip(
                label: _sourceChipLabel(value),
                selected: state.source == value,
                icon: value == 'all' ? null : orderSourceIcon(value),
                onTap: () =>
                    ref.read(ordersListProvider.notifier).setSource(value),
              );
            },
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
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
    );
  }

  Widget _body(OrdersListState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return EmptyListBody(message: t('STORE_FORM.ORDERS_NO_RESULTS'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final item = state.items[index];
        return _OrderCard(
          item: item,
          onTap: () => context.push(Routes.staffOrder(item.id)),
        );
      },
    );
  }
}

class _ChipRail extends StatelessWidget {
  const _ChipRail({
    required this.itemCount,
    required this.itemBuilder,
    this.height = 38,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _StatusRailChip extends StatelessWidget {
  const _StatusRailChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.showDot,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : accent;
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
              if (showDot && !selected) ...<Widget>[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : fg,
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

class _SourceRailChip extends StatelessWidget {
  const _SourceRailChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final IconData? icon;
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
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : Brand.themeColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : Brand.themeColor,
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.item, required this.onTap});

  final StaffOrderListItem item;
  final VoidCallback onTap;

  String _itemsLabel() {
    final count = item.itemCount;
    final unit = count == 1
        ? t('STORE_FORM.POS_RECEIPT_ITEM')
        : t('STORE_FORM.ORDER_ITEMS');
    return '$count $unit';
  }

  String _statusLabel() {
    final key = staffOrderStatusLabelKey(item.status);
    final label = t(key);
    return label == key ? item.status : label;
  }

  String _sourceLabel() {
    final key = staffOrderSourceLabelKey(item.source);
    final label = t(key);
    return label == key ? item.source : label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = orderStatusAccent(item.status);
    final wash = orderStatusWash(item.status);
    final border = orderStatusBorder(item.status);
    final placed = DateTime.tryParse(item.placedAt)?.toLocal();
    final phone = item.customerPhone.trim().isNotEmpty
        ? item.customerPhone.trim()
        : item.displayCustomer;
    final thumbName = item.firstItemName ?? item.displayCustomer;

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
                  padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _ItemThumb(
                        name: thumbName,
                        url: item.firstItemImageUrl,
                        accent: accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '#${item.orderNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.68),
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: _OutlineMetaChip(
                                    icon: orderSourceIcon(item.source),
                                    label: _sourceLabel(),
                                    foreground: Brand.themeColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: _OutlineMetaChip(
                                    icon: Icons.shopping_bag_outlined,
                                    label: _itemsLabel(),
                                    foreground:
                                        AppTheme.ink.withValues(alpha: 0.72),
                                  ),
                                ),
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
                              icon: orderStatusIcon(item.status),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              Format.rupee(item.totalAmount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                                height: 1.1,
                              ),
                            ),
                            if (placed != null) ...<Widget>[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 10,
                                    color: AppTheme.ink.withValues(alpha: 0.45),
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      Format.dateTime(placed),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.ink
                                            .withValues(alpha: 0.52),
                                        fontSize: 10,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
          Text(
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
        ],
      ),
    );
  }
}

class _OutlineMetaChip extends StatelessWidget {
  const _OutlineMetaChip({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

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
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
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

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({
    required this.name,
    required this.url,
    required this.accent,
  });

  final String name;
  final String? url;
  final Color accent;

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
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: accent.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
