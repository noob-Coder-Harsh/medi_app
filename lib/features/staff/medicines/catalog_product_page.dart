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
import '../inventory/add_batch_sheet.dart';
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
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              staffBack(context, fallback: Routes.staffMedicines),
        ),
        title: state.product?.name ?? t('STORE_FORM.MEDICINES_TITLE'),
        actions: <Widget>[
          if (state.product != null)
            TextButton(
              onPressed: () => context.push(
                Routes.staffMedicinesProductEdit(storeProductId),
              ),
              child: Text(
                t('STORE_FORM.CATALOG_EDIT_META'),
                style: const TextStyle(color: AppTheme.onTeal),
              ),
            ),
          StaffAppBarAction.refresh(
            onPressed: () => ref
                .read(inventoryDetailProvider(storeProductId).notifier)
                .refresh(),
          ),
        ],
      ),
      floatingActionButton: state.allowsOpeningStock && state.product != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await showAddBatchSheet(
                  context,
                  storeProductId: storeProductId,
                  product: state.product!,
                );
                if (!context.mounted || !created) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('STORE_FORM.ADD_BATCH'))),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(t('STORE_FORM.ADD_BATCH')),
            )
          : null,
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final wide = constraints.maxWidth >= 600;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            _HeroCard(
              product: product,
              allowsOpening: state.allowsOpeningStock,
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
            const SizedBox(height: 12),
            _StatsStrip(
              available: product.availableQuantity,
              onHand: product.onHandQuantity,
              activeBatches: activeBatches,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: t('STORE_FORM.PRODUCT_INFO_SECTION'),
              child: _InfoGrid(
                wide: wide,
                rows: <(String, String)>[
                  (
                    t('STORE_FORM.CATEGORIES_TITLE'),
                    product.categoryName ?? '—',
                  ),
                  (
                    t('STOREFRONT.PRODUCT_MANUFACTURER'),
                    product.manufacturer?.trim().isNotEmpty == true
                        ? product.manufacturer!
                        : '—',
                  ),
                  (
                    t('STORE_FORM.GENERIC_NAME'),
                    product.genericName?.trim().isNotEmpty == true
                        ? product.genericName!
                        : '—',
                  ),
                  (
                    t('STORE_FORM.STRENGTH'),
                    product.strength?.trim().isNotEmpty == true
                        ? product.strength!
                        : '—',
                  ),
                  (
                    t('STORE_FORM.DOSAGE_FORM'),
                    product.dosageForm?.trim().isNotEmpty == true
                        ? product.dosageForm!
                        : '—',
                  ),
                  (
                    t('STORE_FORM.PRIMARY_PACK_TYPE'),
                    product.packLabel.trim().isNotEmpty
                        ? product.packLabel
                        : '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: t('STORE_FORM.PRICING_SECTION'),
              child: _InfoGrid(
                wide: wide,
                rows: <(String, String)>[
                  (
                    t('STORE_FORM.SELLING_PRICE'),
                    product.sellingPrice == null
                        ? '—'
                        : Format.rupee(product.sellingPrice!),
                  ),
                  (
                    t('STORE_FORM.MRP'),
                    product.mrp == null ? '—' : Format.rupee(product.mrp!),
                  ),
                  (
                    t('STORE_FORM.GST_RATE'),
                    product.gstRate == null
                        ? '—'
                        : '${Format.stock(product.gstRate!)}%',
                  ),
                  (
                    t('STORE_FORM.STOCK_COUNT'),
                    Format.stock(product.availableQuantity),
                  ),
                  (
                    t('STORE_FORM.ON_HAND'),
                    Format.stock(product.onHandQuantity),
                  ),
                  (
                    t('STORE_FORM.RESERVED'),
                    Format.stock(product.reservedQuantity),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () => context.push(
                        Routes.staffMedicinesProductEdit(storeProductId),
                      ),
              child: Text(t('STORE_FORM.CATALOG_EDIT_META')),
            ),
            const SizedBox(height: 20),
            Text(
              t('STORE_FORM.STOCK_BATCHES'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (state.batches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  state.allowsOpeningStock
                      ? t('STORE_FORM.OPENING_STOCK_DESCRIPTION')
                      : t('STORE_FORM.PURCHASE_STOCK_VIA_PURCHASE'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              )
            else
              ...state.batches.map(
                (InventoryBatch batch) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BatchCard(
                    storeProductId: storeProductId,
                    batch: batch,
                    busy: state.busy,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.product, required this.allowsOpening});

  final ListingCard product;
  final bool allowsOpening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = product.imageUrl ?? product.thumb;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Brand.themeBackground,
                  child: url != null && url.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => _Initials(product.name),
                        )
                      : _Initials(product.name),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _Chip(
                  label: product.isSystem
                      ? t('STORE_FORM.CATALOG_KIND_MASTER')
                      : t('STORE_FORM.CATALOG_KIND_CUSTOM'),
                  color: Brand.themeColor,
                ),
                if (product.requiresPrescription)
                  const _Chip(label: 'Rx', color: AppTheme.amber),
                _Chip(
                  label: product.availableQuantity > 0
                      ? t('STOREFRONT.IN_STOCK')
                      : t('STOREFRONT.OUT_OF_STOCK'),
                  color: product.availableQuantity > 0
                      ? Brand.themeColor
                      : AppTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (product.genericName != null &&
                product.genericName!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                product.genericName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              allowsOpening
                  ? t('STORE_FORM.OPENING_STOCK_DESCRIPTION')
                  : t('STORE_FORM.PURCHASE_STOCK_VIA_PURCHASE'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
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
            label: t('STORE_FORM.STOCK_COUNT'),
            value: Format.stock(available),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: t('STORE_FORM.ON_HAND'),
            value: Format.stock(onHand),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: t('STORE_FORM.STOCK_BATCHES'),
            value: Format.stock(activeBatches),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: const Color(0xFFCCFBF1),
      borderRadius: AppTheme.borderRadius,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.wide, required this.rows});

  final bool wide;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: rows
            .map((row) => _DetailRow(label: row.$1, value: row.$2))
            .toList(growable: false),
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      final left = rows[i];
      final right = i + 1 < rows.length ? rows[i + 1] : null;
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _DetailRow(label: left.$1, value: left.$2)),
            const SizedBox(width: 12),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _DetailRow(label: right.$1, value: right.$2),
            ),
          ],
        ),
      );
    }
    return Column(children: children);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
      BatchStatusTone.green => theme.colorScheme.primary,
      BatchStatusTone.slate =>
        theme.colorScheme.onSurface.withValues(alpha: 0.45),
    };

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.batch.batchNo?.isNotEmpty == true
                        ? widget.batch.batchNo!
                        : '—',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  status.label,
                  style: theme.textTheme.labelLarge?.copyWith(color: tone),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Avail ${Format.stock(widget.batch.availableQuantity)}'
              ' / ${Format.stock(widget.batch.quantity)}'
              '  ·  MRP ${Format.rupee(widget.batch.mrp)}'
              '  ·  ${Format.rupee(widget.batch.sellingPrice)}',
              style: theme.textTheme.bodySmall,
            ),
            if (widget.batch.purchasePrice != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                '${t('STORE_FORM.PURCHASE_PRICE')}: ${Format.rupee(widget.batch.purchasePrice!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            if (widget.batch.expiresAt != null &&
                widget.batch.expiresAt!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                '${t('STORE_FORM.EXPIRES_AT')}: ${widget.batch.expiresAt}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            if (_editing) ...<Widget>[
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.SELLING_PRICE'),
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
                child: TextButton(
                  onPressed: widget.busy
                      ? null
                      : () => setState(() => _editing = true),
                  child: Text(t('STORE_FORM.INVENTORY_EDIT_SELLING_PRICE')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _trim(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}
