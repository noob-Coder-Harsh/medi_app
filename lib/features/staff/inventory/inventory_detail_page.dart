import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import '../shell/staff_app_bar.dart';
import 'add_batch_sheet.dart';
import 'inventory_detail_controller.dart';

class InventoryDetailPage extends ConsumerWidget {
  const InventoryDetailPage({super.key, required this.storeProductId});

  final String storeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(inventoryDetailProvider(storeProductId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffInventory),
        ),
        title: state.product?.name ?? t('STORE_FORM.INVENTORY_SIDEBAR_TITLE'),
        actions: <Widget>[
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
              : _DetailBody(
                  storeProductId: storeProductId,
                  state: state,
                  theme: theme,
                ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.storeProductId,
    required this.state,
    required this.theme,
  });

  final String storeProductId;
  final InventoryDetailState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = state.product!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        _HeaderCard(product: product, allowsOpening: state.allowsOpeningStock),
        if (state.error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error),
          ),
        ],
        const SizedBox(height: 16),
        _ListingEditor(
          storeProductId: storeProductId,
          product: product,
          busy: state.busy,
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
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.product, required this.allowsOpening});

  final ListingCard product;
  final bool allowsOpening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(product.name, style: theme.textTheme.titleLarge),
            if (product.genericName != null &&
                product.genericName!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(product.genericName!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text(
              '${t('STORE_FORM.STOCK_COUNT')}: ${Format.stock(product.availableQuantity)}'
              '${product.sellingPrice == null ? '' : '  ·  ${Format.rupee(product.sellingPrice!)}'}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
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

class _ListingEditor extends ConsumerStatefulWidget {
  const _ListingEditor({
    required this.storeProductId,
    required this.product,
    required this.busy,
  });

  final String storeProductId;
  final ListingCard product;
  final bool busy;

  @override
  ConsumerState<_ListingEditor> createState() => _ListingEditorState();
}

class _ListingEditorState extends ConsumerState<_ListingEditor> {
  late bool _active = widget.product.isActive;
  late String _salePolicy = widget.product.salePolicy.isEmpty
      ? 'inherit'
      : widget.product.salePolicy;
  late final TextEditingController _rack =
      TextEditingController(text: widget.product.rackLocation ?? '');
  late final TextEditingController _reorder = TextEditingController(
    text: widget.product.reorderLevel.round().toString(),
  );
  String? _error;

  @override
  void didUpdateWidget(covariant _ListingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.updatedAt != widget.product.updatedAt) {
      _active = widget.product.isActive;
      _salePolicy = widget.product.salePolicy.isEmpty
          ? 'inherit'
          : widget.product.salePolicy;
      _rack.text = widget.product.rackLocation ?? '';
      _reorder.text = widget.product.reorderLevel.round().toString();
    }
  }

  @override
  void dispose() {
    _rack.dispose();
    _reorder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final reorder = int.tryParse(_reorder.text.trim());
    if (reorder == null || reorder < 0) {
      setState(() => _error = t('STORE_FORM.STOCK_COUNT'));
      return;
    }
    final error = await ref
        .read(inventoryDetailProvider(widget.storeProductId).notifier)
        .saveListing(
          UpdateStoreProductInput(
            isActive: _active,
            salePolicy: _salePolicy,
            rackLocation: _rack.text.trim(),
            reorderLevel: reorder,
          ),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error == 'AUTH_SUPABASE_MISSING'
            ? t('AUTH_SUPABASE_MISSING')
            : error;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('STORE_FORM.INVENTORY_SELLING_PRICE_SAVED'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('STORE_FORM.CATALOG_EDIT_META'),
              style: theme.textTheme.titleMedium,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: widget.busy
                  ? null
                  : (bool value) => setState(() => _active = value),
            ),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _salePolicy,
              decoration: InputDecoration(
                labelText: t('STORE_FORM.SALE_POLICY'),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'inherit', child: Text('Inherit')),
                DropdownMenuItem(
                  value: 'loose_allowed',
                  child: Text('Loose allowed'),
                ),
                DropdownMenuItem(value: 'pack_only', child: Text('Pack only')),
                DropdownMenuItem(
                  value: 'whole_only',
                  child: Text('Whole only'),
                ),
              ],
              onChanged: widget.busy
                  ? null
                  : (String? value) {
                      if (value == null) return;
                      setState(() => _salePolicy = value);
                    },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rack,
              decoration: const InputDecoration(labelText: 'Rack'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reorder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reorder level'),
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
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: widget.busy ? null : _save,
              child: Text(t('CONFIRM')),
            ),
          ],
        ),
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
    if (!_editing && oldWidget.batch.sellingPrice != widget.batch.sellingPrice) {
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
      BatchStatusTone.slate => theme.colorScheme.onSurface.withValues(
          alpha: 0.45,
        ),
    };

    return Material(
      color: theme.colorScheme.surface,
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
