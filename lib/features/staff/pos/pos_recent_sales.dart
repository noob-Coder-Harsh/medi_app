import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_colors.dart';
import '../../../core/brand.dart';
import '../../../core/empty_list.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/pos_checkout.dart';
import '../../../data/models/staff_order.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';
import '../orders/order_status_style.dart';

class PosRecentSalesController extends AsyncNotifier<List<PosRecentSale>> {
  @override
  Future<List<PosRecentSale>> build() => _load();

  Future<List<PosRecentSale>> _load() async {
    final session = ref.read(staffSessionProvider).session;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) return const <PosRecentSale>[];
    try {
      return await ref.read(staffWriteApiProvider).recentSales(accessToken: token);
    } catch (_) {
      return const <PosRecentSale>[];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void prepend(PosRecentSale sale) {
    final current = state.asData?.value ?? const <PosRecentSale>[];
    state = AsyncData(<PosRecentSale>[
      sale,
      ...current.where((PosRecentSale s) => s.id != sale.id),
    ]);
  }
}

final posRecentSalesProvider =
    AsyncNotifierProvider<PosRecentSalesController, List<PosRecentSale>>(
      PosRecentSalesController.new,
    );

class PosRecentSalesButton extends ConsumerWidget {
  const PosRecentSalesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final async = ref.watch(posRecentSalesProvider);
    final sales = async.asData?.value ?? const <PosRecentSale>[];

    return IconButton(
      tooltip: t('STORE_FORM.POS_RECENT_SALES'),
      onPressed: () => _open(context),
      icon: Badge(
        isLabelVisible: sales.isNotEmpty,
        label: Text('${sales.length.clamp(0, 9)}'),
        child: const Icon(Icons.history),
      ),
    );
  }

  Future<void> _open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Brand.themeBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheet) => const _PosRecentSalesSheet(),
    );
  }
}

class _PosRecentSalesSheet extends ConsumerWidget {
  const _PosRecentSalesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final async = ref.watch(posRecentSalesProvider);
    final sales = async.asData?.value ?? const <PosRecentSale>[];
    final loading = async.isLoading && sales.isEmpty;
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Brand.themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Brand.themeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        t('STORE_FORM.POS_RECENT_SALES'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sales.isEmpty
                            ? t('STORE_FORM.POS_NO_RECENT_SALES')
                            : t('STORE_FORM.POS_ITEMS_COUNT')
                                .replaceAll('{count}', '${sales.length}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t('CHROME.CLOSE_MORE'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: Brand.themeColor,
                    onRefresh: () =>
                        ref.read(posRecentSalesProvider.notifier).refresh(),
                    child: sales.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              EmptyListBody(
                                icon: Icons.point_of_sale_outlined,
                                message: t('STORE_FORM.POS_NO_RECENT_SALES'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            itemCount: sales.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (BuildContext context, int index) {
                              final sale = sales[index];
                              return _RecentSaleCard(
                                sale: sale,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push(Routes.staffOrder(sale.id));
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentSaleCard extends StatelessWidget {
  const _RecentSaleCard({
    required this.sale,
    required this.onTap,
  });

  final PosRecentSale sale;
  final VoidCallback onTap;

  String get _status {
    final raw = sale.status.trim();
    return raw.isEmpty ? 'completed' : raw;
  }

  String _statusLabel() {
    final key = staffOrderStatusLabelKey(_status);
    final label = t(key);
    return label == key ? _status : label;
  }

  String _sourceLabel() {
    final key = staffOrderSourceLabelKey(sale.source);
    final label = t(key);
    return label == key ? sale.source : label;
  }

  String _itemsLabel() {
    final count = sale.itemCount;
    if (count <= 0) return t('STORE_FORM.SOURCE_POS');
    final unit = count == 1
        ? t('STORE_FORM.POS_RECEIPT_ITEM')
        : t('STORE_FORM.ORDER_ITEMS');
    return '$count $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;
    final accent = orderStatusAccent(status);
    final wash = orderStatusWash(status);
    final border = orderStatusBorder(status);
    final placed = DateTime.tryParse(sale.placedAt)?.toLocal();
    final name = (sale.customerName ?? '').trim();
    final phone = sale.customerPhone.trim();
    final title = name.isNotEmpty
        ? name
        : (phone.isNotEmpty ? phone : t('STORE_FORM.SOURCE_POS'));
    final subtitle = name.isNotEmpty && phone.isNotEmpty ? phone : null;

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
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          orderStatusIcon(status),
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '#${sale.orderNumber}',
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
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            if (subtitle != null) ...<Widget>[
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 7),
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: _MetaChip(
                                    icon: orderSourceIcon(sale.source),
                                    label: _sourceLabel(),
                                    foreground: Brand.themeColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: _MetaChip(
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
                              icon: orderStatusIcon(status),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Format.rupee(sale.totalAmount),
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
                                    Icons.schedule_rounded,
                                    size: 11,
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
        color: Colors.white.withValues(alpha: 0.78),
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
