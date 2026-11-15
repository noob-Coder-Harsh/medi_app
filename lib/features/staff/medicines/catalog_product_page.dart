import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import '../inventory/inventory_detail_controller.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';

class CatalogProductPage extends ConsumerWidget {
  const CatalogProductPage({super.key, required this.storeProductId});

  final String storeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(inventoryDetailProvider(storeProductId));

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              staffBack(context, fallback: Routes.staffMedicines),
        ),
        title: state.product?.name ?? t('STORE_FORM.MEDICINES_TITLE'),
      ),
      body: state.loading && state.product == null
          ? const Center(child: CircularProgressIndicator())
          : state.product == null
              ? Center(child: Text(t('ERROR_GENERIC')))
              : _CatalogProductBody(
                  storeProductId: storeProductId,
                  state: state,
                ),
    );
  }
}

class _CatalogProductBody extends ConsumerWidget {
  const _CatalogProductBody({
    required this.storeProductId,
    required this.state,
  });

  final String storeProductId;
  final InventoryDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = state.product!;
    final theme = Theme.of(context);
    final activeBatches = state.batches
        .where((InventoryBatch b) => b.availableQuantity > 0)
        .length;
    final inStock = product.availableQuantity > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: <Widget>[
        _ImageSection(product: product),
        const SizedBox(height: 12),
        _ActionButtons(
          busy: state.busy,
          onEdit: () => context.push(
            Routes.staffMedicinesProductEdit(storeProductId),
          ),
          onManageStock: () => context.push(
            Routes.staffMedicinesProductStock(storeProductId),
          ),
        ),
        if (state.error != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error),
          ),
        ],
        const SizedBox(height: 14),
        _StatusBanner(
          isSystem: product.isSystem,
          requiresPrescription: product.requiresPrescription,
          inStock: inStock,
          stockHint: state.allowsOpeningStock
              ? t('STORE_FORM.OPENING_STOCK_DESCRIPTION')
              : t('STORE_FORM.PURCHASE_STOCK_VIA_PURCHASE'),
        ),
        const SizedBox(height: 14),
        _StatsStrip(
          available: product.availableQuantity,
          onHand: product.onHandQuantity,
          activeBatches: activeBatches,
        ),
        const SizedBox(height: 14),
        _VisualSection(
          icon: Icons.biotech_outlined,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFF0F9FF),
          title: t('STORE_FORM.PRODUCT_INFO_SECTION'),
          child: _FactWrap(
            items: <_FactItem>[
              _FactItem(
                icon: Icons.sell_outlined,
                color: const Color(0xFF0D9488),
                label: t('STORE_FORM.CATEGORIES_TITLE'),
                value: product.categoryName ?? '—',
              ),
              _FactItem(
                icon: Icons.apartment_outlined,
                color: const Color(0xFF7C3AED),
                label: t('STOREFRONT.PRODUCT_MANUFACTURER'),
                value: _orDash(product.manufacturer),
              ),
              _FactItem(
                icon: Icons.science_outlined,
                color: const Color(0xFF2563EB),
                label: t('STORE_FORM.GENERIC_NAME'),
                value: _orDash(product.genericName),
              ),
              _FactItem(
                icon: Icons.fitness_center_outlined,
                color: const Color(0xFFEA580C),
                label: t('STORE_FORM.STRENGTH'),
                value: _orDash(product.strength),
              ),
              _FactItem(
                icon: Icons.medication_outlined,
                color: const Color(0xFFDB2777),
                label: t('STORE_FORM.DOSAGE_FORM'),
                value: _orDash(product.dosageForm),
              ),
              _FactItem(
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF059669),
                label: t('STORE_FORM.PRIMARY_PACK_TYPE'),
                value: product.packLabel.trim().isNotEmpty
                    ? product.packLabel
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _VisualSection(
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFFCA8A04),
          iconBg: const Color(0xFFFEF9C3),
          title: t('STORE_FORM.PRICING_SECTION'),
          child: _FactWrap(
            items: <_FactItem>[
              _FactItem(
                icon: Icons.sell_outlined,
                color: Brand.themeColor,
                label: t('STORE_FORM.SELLING_PRICE'),
                value: product.sellingPrice == null
                    ? '—'
                    : Format.rupee(product.sellingPrice!),
                emphasize: true,
              ),
              _FactItem(
                icon: Icons.local_offer_outlined,
                color: const Color(0xFF9333EA),
                label: t('STORE_FORM.MRP'),
                value: product.mrp == null ? '—' : Format.rupee(product.mrp!),
              ),
              _FactItem(
                icon: Icons.percent_outlined,
                color: const Color(0xFF0891B2),
                label: t('STORE_FORM.GST_RATE'),
                value: product.gstRate == null
                    ? '—'
                    : '${Format.stock(product.gstRate!)}%',
              ),
              _FactItem(
                icon: Icons.warehouse_outlined,
                color: inStock ? Brand.themeColor : AppTheme.error,
                label: t('STORE_FORM.STOCK_COUNT'),
                value: Format.stock(product.availableQuantity),
                emphasize: true,
              ),
              _FactItem(
                icon: Icons.inventory_outlined,
                color: const Color(0xFF4F46E5),
                label: t('STORE_FORM.ON_HAND'),
                value: Format.stock(product.onHandQuantity),
              ),
              _FactItem(
                icon: Icons.lock_outline,
                color: const Color(0xFF64748B),
                label: t('STORE_FORM.RESERVED'),
                value: Format.stock(product.reservedQuantity),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _VisualSection(
          icon: Icons.layers_outlined,
          iconColor: const Color(0xFF0F766E),
          iconBg: const Color(0xFFCCFBF1),
          title: t('STORE_FORM.STOCK_BATCHES'),
          child: state.batches.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppTheme.ink.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.allowsOpeningStock
                              ? t('STORE_FORM.OPENING_STOCK_DESCRIPTION')
                              : t('STORE_FORM.PURCHASE_STOCK_VIA_PURCHASE'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.65),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: state.batches
                      .map(
                        (InventoryBatch batch) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BatchCard(
                            storeProductId: storeProductId,
                            batch: batch,
                            busy: state.busy,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  static String _orDash(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? '—' : v;
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.product});

  final ListingCard product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = product.imageUrl ?? product.thumb;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ColoredBox(
              color: Colors.white,
              child: url != null && url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => _Initials(product.name),
                    )
                  : _Initials(product.name),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (product.genericName != null &&
                    product.genericName!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.science_outlined,
                        size: 16,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.genericName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.busy,
    required this.onEdit,
    required this.onManageStock,
  });

  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onManageStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(t('STORE_FORM.EDIT_PRODUCT')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onManageStock,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text(t('STORE_FORM.MANAGE_STOCK')),
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isSystem,
    required this.requiresPrescription,
    required this.inStock,
    required this.stockHint,
  });

  final bool isSystem;
  final bool requiresPrescription;
  final bool inStock;
  final String stockHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatusPill(
                  icon: isSystem
                      ? Icons.verified_outlined
                      : Icons.storefront_outlined,
                  label: isSystem
                      ? t('STORE_FORM.CATALOG_KIND_MASTER')
                      : t('STORE_FORM.CATALOG_KIND_CUSTOM'),
                  color: Brand.themeColor,
                ),
                if (requiresPrescription)
                  const _StatusPill(
                    icon: Icons.medical_information_outlined,
                    label: 'Rx',
                    color: AppTheme.amber,
                  ),
                _StatusPill(
                  icon: inStock
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  label: inStock
                      ? t('STOREFRONT.IN_STOCK')
                      : t('STOREFRONT.OUT_OF_STOCK'),
                  color: inStock ? Brand.themeColor : AppTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppTheme.ink.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stockHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.62),
                      height: 1.35,
                    ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letters = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
    return Center(
      child: Text(
        letters.toUpperCase(),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.available,
    required this.onHand,
    required this.activeBatches,
  });

  final double available;
  final double onHand;
  final int activeBatches;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            icon: Icons.warehouse_outlined,
            color: Brand.themeColor,
            bg: const Color(0xFFCCFBF1),
            label: t('STORE_FORM.STOCK_COUNT'),
            value: Format.stock(available),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.inventory_outlined,
            color: const Color(0xFF4F46E5),
            bg: const Color(0xFFEEF2FF),
            label: t('STORE_FORM.ON_HAND'),
            value: Format.stock(onHand),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.layers_outlined,
            color: const Color(0xFFCA8A04),
            bg: const Color(0xFFFEF9C3),
            label: t('STORE_FORM.STOCK_BATCHES'),
            value: Format.stock(activeBatches),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualSection extends StatelessWidget {
  const _VisualSection({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _FactItem {
  const _FactItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool emphasize;
}

class _FactWrap extends StatelessWidget {
  const _FactWrap({required this.items});

  final List<_FactItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final twoCol = constraints.maxWidth >= 360;
        if (!twoCol) {
          return Column(
            children: items
                .map(
                  (_FactItem item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FactTile(item: item),
                  ),
                )
                .toList(growable: false),
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          final left = items[i];
          final right = i + 1 < items.length ? items[i + 1] : null;
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < items.length ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _FactTile(item: left)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: right == null
                        ? const SizedBox.shrink()
                        : _FactTile(item: right),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.item});

  final _FactItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: item.color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        item.emphasize ? FontWeight.w800 : FontWeight.w600,
                    color: AppTheme.ink,
                    height: 1.25,
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

class _BatchCard extends ConsumerStatefulWidget {
  const _BatchCard({
    required this.storeProductId,
    required this.batch,
    required this.busy,
  });

  final String storeProductId;
  final InventoryBatch batch;
  final bool busy;

  @override
  ConsumerState<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends ConsumerState<_BatchCard> {
  bool _editing = false;
  late final TextEditingController _price = TextEditingController(
    text: _trim(widget.batch.sellingPrice),
  );
  String? _error;

  @override
  void didUpdateWidget(covariant _BatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        oldWidget.batch.sellingPrice != widget.batch.sellingPrice) {
      _price.text = _trim(widget.batch.sellingPrice);
    }
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final price = double.tryParse(_price.text.trim());
    if (price == null || price < 0) {
      setState(() => _error = t('STORE_FORM.SELLING_PRICE'));
      return;
    }
    final error = await ref
        .read(inventoryDetailProvider(widget.storeProductId).notifier)
        .updateSellingPrice(batchId: widget.batch.id, sellingPrice: price);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error == 'AUTH_SUPABASE_MISSING'
            ? t('AUTH_SUPABASE_MISSING')
            : error;
      });
      return;
    }
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('STORE_FORM.INVENTORY_SELLING_PRICE_SAVED'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = batchStatus(widget.batch);
    final tone = switch (status.tone) {
      BatchStatusTone.red => AppTheme.error,
      BatchStatusTone.amber => AppTheme.amber,
      BatchStatusTone.green => Brand.themeColor,
      BatchStatusTone.slate =>
        theme.colorScheme.onSurface.withValues(alpha: 0.45),
    };

    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.qr_code_2_outlined, size: 16, color: tone),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.batch.batchNo?.isNotEmpty == true
                      ? widget.batch.batchNo!
                      : '—',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _BatchMetaChip(
                icon: Icons.warehouse_outlined,
                color: Brand.themeColor,
                text:
                    '${Format.stock(widget.batch.availableQuantity)} / ${Format.stock(widget.batch.quantity)}',
              ),
              _BatchMetaChip(
                icon: Icons.local_offer_outlined,
                color: const Color(0xFF9333EA),
                text: 'MRP ${Format.rupee(widget.batch.mrp)}',
              ),
              _BatchMetaChip(
                icon: Icons.sell_outlined,
                color: const Color(0xFF0D9488),
                text: Format.rupee(widget.batch.sellingPrice),
              ),
              if (widget.batch.purchasePrice != null)
                _BatchMetaChip(
                  icon: Icons.shopping_bag_outlined,
                  color: const Color(0xFF64748B),
                  text: Format.rupee(widget.batch.purchasePrice!),
                ),
              if (widget.batch.expiresAt != null &&
                  widget.batch.expiresAt!.isNotEmpty)
                _BatchMetaChip(
                  icon: Icons.event_outlined,
                  color: AppTheme.amber,
                  text: widget.batch.expiresAt!,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_editing) ...<Widget>[
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SELLING_PRICE'),
                prefixIcon: const Icon(Icons.sell_outlined),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: widget.busy
                      ? null
                      : () => setState(() {
                            _editing = false;
                            _price.text = _trim(widget.batch.sellingPrice);
                            _error = null;
                          }),
                  child: Text(t('CANCEL')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: widget.busy ? null : _save,
                  child: Text(t('STORE_FORM.INVENTORY_EDIT_SELLING_PRICE')),
                ),
              ],
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.busy
                    ? null
                    : () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(t('STORE_FORM.INVENTORY_EDIT_SELLING_PRICE')),
              ),
            ),
        ],
      ),
    );
  }

  String _trim(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}

class _BatchMetaChip extends StatelessWidget {
  const _BatchMetaChip({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
