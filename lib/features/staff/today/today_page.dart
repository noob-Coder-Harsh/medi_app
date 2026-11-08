import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/dashboard_summary.dart';
import '../shell/staff_app_bar.dart';
import 'today_controller.dart';

/// Soft accent palette — vivid enough to scan, still readable on white.
abstract final class _DashColor {
  static const emerald = Color(0xFF059669);
  static const sky = Color(0xFF0284C7);
  static const violet = Color(0xFF7C3AED);
  static const amber = Color(0xFFD97706);
  static const online = Color(0xFF3B82F6);
  static const pos = Color(0xFF0D9488);
  static const completed = Color(0xFF16A34A);
  static const processing = Color(0xFFD97706);
  static const ready = Color(0xFF2563EB);
  static const cancelled = Color(0xFFDC2626);
  static const out = Color(0xFFDC2626);
  static const low = Color(0xFFD97706);
  static const inStock = Color(0xFF0D9488);
  static const rx = Color(0xFF7C3AED);
  static const otc = Color(0xFF0D9488);
  static const alertRedBg = Color(0xFFFEE2E2);
  static const alertAmberBg = Color(0xFFFEF3C7);
  static const alertSkyBg = Color(0xFFE0F2FE);
  static const catalogGreenBg = Color(0xFFECFDF5);
  static const catalogBlueBg = Color(0xFFEFF6FF);
}

String _pct(num part, num total) {
  if (total <= 0) return '0.0';
  return ((part / total) * 100).toStringAsFixed(1);
}

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final range = ref.watch(todayRangeProvider);
    final async = ref.watch(todayDashboardProvider);

    return Scaffold(
      appBar: StaffAppBar(
        title: t('TODAY.TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () =>
                ref.read(todayDashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _RangeChips(
            selected: range,
            onSelected: (DashboardRange next) =>
                ref.read(todayDashboardProvider.notifier).setRange(next),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) => _ErrorBody(
                message: '$error',
                onRetry: () =>
                    ref.read(todayDashboardProvider.notifier).refresh(),
              ),
              data: (DashboardSummary summary) => _TodayBody(summary: summary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelected});

  final DashboardRange selected;
  final ValueChanged<DashboardRange> onSelected;

  static const List<(DashboardRange, String)> _options =
      <(DashboardRange, String)>[
        (DashboardRange.today, 'TODAY.RANGE_TODAY'),
        (DashboardRange.d7, 'TODAY.RANGE_7D'),
        (DashboardRange.d30, 'TODAY.RANGE_30D'),
        (DashboardRange.d90, 'TODAY.RANGE_90D'),
        (DashboardRange.all, 'TODAY.RANGE_ALL'),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final (DashboardRange range, String key) = _options[index];
          final bool isSelected = range == selected;
          return Material(
            color: isSelected ? Brand.themeColor : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadius,
              side: BorderSide(
                color: isSelected ? Brand.themeColor : AppTheme.hairlineColor,
              ),
            ),
            child: InkWell(
              borderRadius: AppTheme.borderRadius,
              onTap: () => onSelected(range),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  t(key),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = summary.sales;
    final alerts = summary.alerts;
    final metrics = summary.inventoryMetrics;
    final value = summary.inventoryValue;
    final catalog = summary.catalogCounts;
    final status = sales.statusCounts;

    final showAddProducts = catalog.products <= 0;
    final showOpenPos = !showAddProducts && sales.salesOrderCount <= 0;
    final rxPct = _pct(sales.prescriptionOrderCount, sales.salesOrderCount);
    final orderTotal = sales.orderCount <= 0 ? sales.salesOrderCount : sales.orderCount;

    return RefreshIndicator(
      onRefresh: () => ref.read(todayDashboardProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: <Widget>[
          if (showAddProducts || showOpenPos) ...<Widget>[
            _NextStepCard(
              label: showAddProducts
                  ? t('TODAY.NEXT_ADD_PRODUCTS')
                  : t('TODAY.NEXT_OPEN_POS'),
              onTap: () => context.go(
                showAddProducts ? Routes.staffMedicines : Routes.staffPos,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // KPI 2×2 — matches web top row
          Row(
            children: <Widget>[
              Expanded(
                child: _KpiTile(
                  label: t('TODAY.SALES'),
                  value: Format.rupee(sales.salesTotal),
                  accent: _DashColor.emerald,
                  icon: Icons.currency_rupee_rounded,
                  onTap: () => context.go(Routes.staffOrders),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: t('TODAY.ORDERS'),
                  value: Format.stock(sales.salesOrderCount),
                  subtitle:
                      '${Format.stock(sales.onlineOrderCount)} ${t('TODAY.ONLINE').toLowerCase()}'
                      ' · ${Format.stock(sales.posOrderCount)} ${t('TODAY.POS')}',
                  accent: _DashColor.sky,
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => context.go(Routes.staffOrders),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _KpiTile(
                  label: t('TODAY.PRESCRIPTION_ORDERS'),
                  value: Format.stock(sales.prescriptionOrderCount),
                  subtitle: t('TODAY.OF_TOTAL_ORDERS').replaceAll('{pct}', rxPct),
                  accent: _DashColor.violet,
                  icon: Icons.description_outlined,
                  onTap: () => context.go(Routes.staffOrders),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiTile(
                  label: t('TODAY.AOV'),
                  value: Format.rupee(sales.averageOrderValue),
                  accent: _DashColor.amber,
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => context.go(Routes.staffOrders),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Panel(
            title: t('TODAY.SALES_BREAKDOWN'),
            child: _DonutBlock(
              centerPrimary: Format.rupee(sales.salesTotal),
              centerSecondary: t('TODAY.SALES'),
              segments: <_DonutSegment>[
                _DonutSegment(
                  label: t('TODAY.ONLINE_SALES'),
                  value: sales.onlineSalesTotal,
                  color: _DashColor.online,
                  display: Format.rupee(sales.onlineSalesTotal),
                ),
                _DonutSegment(
                  label: t('TODAY.POS_COUNTER'),
                  value: sales.posSalesTotal,
                  color: _DashColor.pos,
                  display: Format.rupee(sales.posSalesTotal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.ORDER_STATUS'),
            child: Column(
              children: <Widget>[
                _StatusRow(
                  label: t('TODAY.COMPLETED'),
                  count: status.delivered,
                  total: orderTotal,
                  color: _DashColor.completed,
                ),
                _StatusRow(
                  label: t('TODAY.PROCESSING'),
                  count: status.processing,
                  total: orderTotal,
                  color: _DashColor.processing,
                  onTap: () => context.go(Routes.staffOrders),
                ),
                _StatusRow(
                  label: t('TODAY.READY'),
                  count: status.ready,
                  total: orderTotal,
                  color: _DashColor.ready,
                ),
                _StatusRow(
                  label: t('TODAY.CANCELLED'),
                  count: status.cancelled,
                  total: orderTotal,
                  color: _DashColor.cancelled,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.ORDER_TYPE'),
            child: _DonutBlock(
              centerPrimary: '$rxPct%',
              centerSecondary: t('TODAY.PRESCRIPTION'),
              segments: <_DonutSegment>[
                _DonutSegment(
                  label: t('TODAY.PRESCRIPTION'),
                  value: sales.prescriptionOrderCount,
                  color: _DashColor.rx,
                  display: Format.stock(sales.prescriptionOrderCount),
                ),
                _DonutSegment(
                  label: t('TODAY.OTC'),
                  value: sales.otcOrderCount,
                  color: _DashColor.otc,
                  display: Format.stock(sales.otcOrderCount),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.INVENTORY_HEALTH'),
            onTap: () => context.go(Routes.staffInventory),
            child: _DonutBlock(
              centerPrimary: Format.stock(metrics.totalSkus),
              centerSecondary: t('TODAY.TOTAL_SKUS'),
              segments: <_DonutSegment>[
                _DonutSegment(
                  label: t('TODAY.IN_STOCK'),
                  value: metrics.inStock,
                  color: _DashColor.inStock,
                  display: Format.stock(metrics.inStock),
                ),
                _DonutSegment(
                  label: t('TODAY.LOW_STOCK'),
                  value: metrics.lowStock,
                  color: _DashColor.low,
                  display: Format.stock(metrics.lowStock),
                ),
                _DonutSegment(
                  label: t('TODAY.OUT_OF_STOCK'),
                  value: metrics.outOfStock,
                  color: _DashColor.out,
                  display: Format.stock(metrics.outOfStock),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.CATALOG_SUMMARY'),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _CatalogTile(
                    label: t('TODAY.MEDICINES'),
                    value: Format.stock(catalog.products),
                    background: _DashColor.catalogGreenBg,
                    accent: _DashColor.emerald,
                    icon: Icons.medication_outlined,
                    onTap: () => context.go(Routes.staffMedicines),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CatalogTile(
                    label: t('TODAY.CATEGORIES'),
                    value: Format.stock(catalog.categories),
                    background: _DashColor.catalogBlueBg,
                    accent: _DashColor.sky,
                    icon: Icons.sell_outlined,
                    onTap: () => context.go(Routes.staffCategories),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.INVENTORY_VALUE'),
            child: Column(
              children: <Widget>[
                _ValueRow(
                  label: t('TODAY.AT_PURCHASE'),
                  value: Format.rupee(value.atPurchase),
                ),
                const Divider(height: 22),
                _ValueRow(
                  label: t('TODAY.AT_SELLING'),
                  value: Format.rupee(value.atSelling),
                ),
                const Divider(height: 22),
                _ValueRow(
                  label: t('TODAY.AT_MRP'),
                  value: Format.rupee(value.atMrp),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.ALERTS'),
            child: Column(
              children: <Widget>[
                _AlertBar(
                  label: t('TODAY.EXPIRING_30'),
                  value: Format.stock(alerts.expiring30),
                  background: _DashColor.alertRedBg,
                  accent: _DashColor.cancelled,
                  icon: Icons.warning_amber_rounded,
                  onTap: () => context.go(Routes.staffInventory),
                ),
                const SizedBox(height: 8),
                _AlertBar(
                  label: t('TODAY.EXPIRING_90'),
                  value: Format.stock(alerts.expiring90),
                  background: _DashColor.alertAmberBg,
                  accent: _DashColor.amber,
                  icon: Icons.warning_amber_rounded,
                  onTap: () => context.go(Routes.staffInventory),
                ),
                const SizedBox(height: 8),
                _AlertBar(
                  label: t('TODAY.RUNNING_LOW'),
                  value: Format.stock(alerts.lowStock),
                  background: _DashColor.alertSkyBg,
                  accent: _DashColor.sky,
                  icon: Icons.inventory_2_outlined,
                  onTap: () => context.go(Routes.staffMedicines),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            title: t('TODAY.PURCHASES_SUPPLIERS'),
            child: Column(
              children: <Widget>[
                _LinkRow(
                  label: t('TODAY.OPEN_POS'),
                  value: Format.stock(summary.openPoCount),
                  onTap: () => context.go(Routes.staffPurchases),
                ),
                const Divider(height: 22),
                _LinkRow(
                  label: t('TODAY.TOTAL_POS'),
                  value: Format.stock(summary.purchaseCount),
                  onTap: () => context.go(Routes.staffPurchases),
                ),
                const Divider(height: 22),
                _LinkRow(
                  label: t('TODAY.UNPAID_POS'),
                  value: Format.stock(summary.unpaidPoCount),
                  onTap: () => context.go(Routes.staffPurchases),
                ),
                const Divider(height: 22),
                _LinkRow(
                  label: t('TODAY.SUPPLIER_DUE'),
                  value: Format.rupee(summary.supplierDueTotal),
                  onTap: () => context.go(Routes.staffSuppliers),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _ShortcutCard(
                  label: t('TODAY.ORDERS'),
                  value: Format.stock(sales.salesOrderCount),
                  accent: _DashColor.sky,
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => context.go(Routes.staffOrders),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShortcutCard(
                  label: t('TODAY.PRESCRIPTION_ORDERS'),
                  value: Format.stock(sales.prescriptionOrderCount),
                  accent: _DashColor.violet,
                  icon: Icons.description_outlined,
                  onTap: () => context.go(Routes.staffOrders),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _ShortcutCard(
                  label: t('TODAY.OPEN_POS'),
                  value: Format.stock(summary.openPoCount),
                  accent: _DashColor.amber,
                  icon: Icons.inventory_2_outlined,
                  onTap: () => context.go(Routes.staffPurchases),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShortcutCard(
                  label: t('TODAY.CUSTOMERS'),
                  value: Format.stock(catalog.customers),
                  accent: _DashColor.emerald,
                  icon: Icons.groups_outlined,
                  onTap: () => context.go(Routes.staffCustomers),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.onTap});

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: onTap == null
          ? body
          : InkWell(
              borderRadius: AppTheme.borderRadius,
              onTap: onTap,
              child: body,
            ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withValues(alpha: 0.10),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.55),
                    height: 1.25,
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

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
    required this.display,
  });

  final String label;
  final double value;
  final Color color;
  final String display;
}

class _DonutBlock extends StatelessWidget {
  const _DonutBlock({
    required this.centerPrimary,
    required this.centerSecondary,
    required this.segments,
  });

  final String centerPrimary;
  final String centerSecondary;
  final List<_DonutSegment> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segments.fold<double>(0, (double a, _DonutSegment s) => a + s.value);

    return Column(
      children: <Widget>[
        SizedBox(
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size(148, 148),
                painter: _DonutPainter(segments: segments),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      centerPrimary,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      centerSecondary,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final _DonutSegment seg in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    seg.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                Text(
                  '${_pct(seg.value, total)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.5),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  seg.display,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (double a, _DonutSegment s) => a + s.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.28;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFE8EEF0)
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final _DonutSegment seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = seg.color
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    this.onTap,
    this.isLast = false,
  });

  final String label;
  final double count;
  final double total;
  final Color color;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            Format.stock(count),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              '${_pct(count, total)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.5),
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.label,
    required this.value,
    required this.background,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color background;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: BorderSide(color: accent.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.68),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBar extends StatelessWidget {
  const _AlertBar({
    required this.label,
    required this.value,
    required this.background,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color background;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: BorderSide(color: accent.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.95),
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.72),
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Brand.themeColor,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Brand.themeColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
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

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Brand.themeColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: Brand.themeColor),
      ),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Brand.themeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, color: Brand.themeColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(t('TODAY.RETRY'))),
          ],
        ),
      ),
    );
  }
}
