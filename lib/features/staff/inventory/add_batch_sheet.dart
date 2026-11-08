import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/theme.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import 'inventory_detail_controller.dart';

Future<bool> showAddBatchSheet(
  BuildContext context, {
  required String storeProductId,
  required ListingCard product,
}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return AddBatchSheet(
        storeProductId: storeProductId,
        product: product,
      );
    },
  );
  return created == true;
}

class AddBatchSheet extends ConsumerStatefulWidget {
  const AddBatchSheet({
    super.key,
    required this.storeProductId,
    required this.product,
  });

  final String storeProductId;
  final ListingCard product;

  @override
  ConsumerState<AddBatchSheet> createState() => _AddBatchSheetState();
}

class _AddBatchSheetState extends ConsumerState<AddBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _batchNo = TextEditingController();
  final _packs = TextEditingController(text: '1');
  final _units = TextEditingController();
  final _purchase = TextEditingController();
  final _mrp = TextEditingController();
  final _selling = TextEditingController();
  final _expires = TextEditingController();

  String? _error;
  bool _usePacks = false;

  PackagingInfo get _packaging => PackagingInfo(
        baseUnit: widget.product.baseUnit,
        primaryPackType: widget.product.primaryPackType,
        primaryPackQuantity: widget.product.primaryPackQuantity,
      );

  @override
  void initState() {
    super.initState();
    _usePacks = hasRetailPack(_packaging);
    if (widget.product.mrp != null) {
      _mrp.text = _trimNum(widget.product.mrp!);
    }
    if (widget.product.sellingPrice != null) {
      _selling.text = _trimNum(widget.product.sellingPrice!);
    }
    _batchNo.text =
        'OPEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _batchNo.dispose();
    _packs.dispose();
    _units.dispose();
    _purchase.dispose();
    _mrp.dispose();
    _selling.dispose();
    _expires.dispose();
    super.dispose();
  }

  int? _resolvedQuantity() {
    if (_usePacks) {
      final packs = int.tryParse(_packs.text.trim());
      if (packs == null || packs < 1) return null;
      return convertPackToBaseQuantity(packs, _packaging);
    }
    final units = int.tryParse(_units.text.trim());
    if (units == null || units < 1) return null;
    return units;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final quantity = _resolvedQuantity();
    if (quantity == null) {
      setState(() => _error = t('STORE_FORM.QUANTITY'));
      return;
    }
    final purchase = double.tryParse(_purchase.text.trim());
    final mrp = double.tryParse(_mrp.text.trim());
    final selling = double.tryParse(_selling.text.trim());
    if (purchase == null || purchase < 0) {
      setState(() => _error = t('STORE_FORM.PURCHASE_PRICE'));
      return;
    }
    if (mrp == null || mrp < 0) {
      setState(() => _error = t('STORE_FORM.MRP'));
      return;
    }
    if (selling == null || selling < 0) {
      setState(() => _error = t('STORE_FORM.SELLING_PRICE'));
      return;
    }
    if (selling > mrp) {
      setState(() => _error = 'Selling price cannot exceed MRP');
      return;
    }

    final error = await ref
        .read(inventoryDetailProvider(widget.storeProductId).notifier)
        .addOpeningBatch(
          OpeningBatchInput(
            batchNo: _batchNo.text,
            mrp: mrp,
            sellingPrice: selling,
            quantity: quantity,
            purchasePrice: purchase,
            expiresAt: _expires.text.trim().isEmpty ? null : _expires.text.trim(),
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
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final busy =
        ref.watch(inventoryDetailProvider(widget.storeProductId)).busy;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    final packQty = normalizePackQuantity(_packaging.primaryPackQuantity);
    final qty = _resolvedQuantity();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.hairlineColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('STORE_FORM.ADD_BATCH'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('STORE_FORM.OPENING_STOCK_DESCRIPTION'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('STORE_FORM.STOCK_CALC_TITLE'),
                style: theme.textTheme.labelLarge,
              ),
              Text(
                t('STORE_FORM.STOCK_CALC_DESC'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchNo,
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.BATCH_NO'),
                ),
                validator: (String? value) {
                  if ((value ?? '').trim().isEmpty) {
                    return t('STORE_FORM.BATCH_NO');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (hasRetailPack(_packaging)) ...<Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('STORE_FORM.PURCHASE_PACKS')),
                  subtitle: Text(
                    '${t('STORE_FORM.PURCHASE_PACKS_HINT')} ($packQty ${getBaseUnitLabel(_packaging.baseUnit)} / ${getPrimaryPackTypeLabel(_packaging.primaryPackType)})',
                  ),
                  value: _usePacks,
                  onChanged: busy
                      ? null
                      : (bool value) => setState(() => _usePacks = value),
                ),
                const SizedBox(height: 8),
              ],
              if (_usePacks)
                TextFormField(
                  controller: _packs,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.PURCHASE_PACKS'),
                    helperText: qty == null
                        ? null
                        : '= $qty ${getBaseUnitLabel(_packaging.baseUnit)}',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (String? value) {
                    final packs = int.tryParse(value?.trim() ?? '');
                    if (packs == null || packs < 1) {
                      return t('STORE_FORM.QUANTITY');
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _units,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: t('STORE_FORM.QUANTITY'),
                  ),
                  validator: (String? value) {
                    final units = int.tryParse(value?.trim() ?? '');
                    if (units == null || units < 1) {
                      return t('STORE_FORM.QUANTITY');
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purchase,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.PURCHASE_PRICE'),
                  helperText: t('STORE_FORM.STOCK_CALC_PRICE_HINT'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mrp,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: t('STORE_FORM.MRP')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _selling,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.SELLING_PRICE'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expires,
                decoration: InputDecoration(
                  labelText: t('STORE_FORM.EXPIRES_AT'),
                  hintText: 'YYYY-MM-DD',
                ),
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
              FilledButton(
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('STORE_FORM.ADD_BATCH')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _trimNum(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}
