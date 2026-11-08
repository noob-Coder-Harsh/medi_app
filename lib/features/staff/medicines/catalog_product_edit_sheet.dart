import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/packaging_constants.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/catalog_product.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import '../../../data/rpc/listing_rpc.dart';
import '../../../data/supabase_client.dart';
import '../inventory/inventory_detail_controller.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';

/// Full-screen product edit (outside bottom bar).
class CatalogProductEditPage extends ConsumerWidget {
  const CatalogProductEditPage({super.key, required this.storeProductId});

  final String storeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(inventoryDetailProvider(storeProductId));
    final product = state.product;

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(
            context,
            fallback: Routes.staffMedicinesProduct(storeProductId),
          ),
        ),
        title: t('STORE_FORM.CATALOG_EDIT_META'),
      ),
      body: state.loading && product == null
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? Center(child: Text(state.error ?? t('ERROR_GENERIC')))
              : CatalogProductEditForm(
                  storeProductId: storeProductId,
                  product: product,
                ),
    );
  }
}

class CatalogProductEditForm extends ConsumerStatefulWidget {
  const CatalogProductEditForm({
    super.key,
    required this.storeProductId,
    required this.product,
  });

  final String storeProductId;
  final ListingCard product;

  @override
  ConsumerState<CatalogProductEditForm> createState() =>
      _CatalogProductEditFormState();
}

class _CatalogProductEditFormState
    extends ConsumerState<CatalogProductEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.product.name);
  late final TextEditingController _generic =
      TextEditingController(text: widget.product.genericName ?? '');
  late final TextEditingController _manufacturer =
      TextEditingController(text: widget.product.manufacturer ?? '');
  late final TextEditingController _strength =
      TextEditingController(text: widget.product.strength ?? '');
  late final TextEditingController _mrp = TextEditingController(
    text: widget.product.mrp == null ? '' : _num(widget.product.mrp!),
  );
  late final TextEditingController _selling = TextEditingController(
    text: widget.product.sellingPrice == null
        ? ''
        : _num(widget.product.sellingPrice!),
  );
  late final TextEditingController _packQty = TextEditingController(
    text: widget.product.primaryPackQuantity == null
        ? '1'
        : widget.product.primaryPackQuantity!.round().toString(),
  );
  late final TextEditingController _rack =
      TextEditingController(text: widget.product.rackLocation ?? '');
  late final TextEditingController _reorder = TextEditingController(
    text: widget.product.reorderLevel.round().toString(),
  );

  List<Category> _categories = const <Category>[];
  String? _categoryId;
  late String _dosageForm;
  late String _baseUnit;
  late String _primaryPackType;
  late int _primaryPackQuantity;
  late bool _requiresRx;
  late bool _isActive;
  late String _salePolicy;
  bool _loadingCategories = true;
  String? _error;

  bool get _isSystem => widget.product.isSystem;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product.categoryId;
    _dosageForm = (widget.product.dosageForm ?? 'tablet').toLowerCase();
    if (!kDosageFormValues.contains(_dosageForm)) {
      _dosageForm = 'tablet';
    }
    final defaults = getPackagingDefaultsForDosageForm(_dosageForm);
    _baseUnit = widget.product.baseUnit?.isNotEmpty == true
        ? widget.product.baseUnit!
        : defaults.baseUnit;
    _primaryPackType = widget.product.primaryPackType?.isNotEmpty == true
        ? widget.product.primaryPackType!
        : defaults.primaryPackType;
    _primaryPackQuantity = widget.product.primaryPackQuantity?.round() ??
        defaults.primaryPackQuantity;
    _requiresRx = widget.product.requiresPrescription;
    _isActive = widget.product.isActive;
    _salePolicy = widget.product.salePolicy.isEmpty
        ? 'inherit'
        : widget.product.salePolicy;
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _generic.dispose();
    _manufacturer.dispose();
    _strength.dispose();
    _mrp.dispose();
    _selling.dispose();
    _packQty.dispose();
    _rack.dispose();
    _reorder.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!AppSupabase.isReady) {
      setState(() {
        _loadingCategories = false;
        _error = t('AUTH_SUPABASE_MISSING');
      });
      return;
    }
    try {
      final categories =
          await ref.read(listingRpcProvider).listSystemCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories.where((Category c) => c.isActive).toList();
        if (_categoryId == null ||
            !_categories.any((Category c) => c.id == _categoryId)) {
          _categoryId =
              _categories.isEmpty ? null : _categories.first.id;
        }
        _loadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _error = '$error';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mrp = double.tryParse(_mrp.text.trim());
    final selling = double.tryParse(_selling.text.trim());
    final reorder = int.tryParse(_reorder.text.trim()) ?? 0;
    final packQty = int.tryParse(_packQty.text.trim()) ?? 1;

    final UpdateStoreProductInput input;
    if (_isSystem) {
      input = UpdateStoreProductInput(
        isActive: _isActive,
        salePolicy: _salePolicy,
        rackLocation: _rack.text.trim().isEmpty ? null : _rack.text.trim(),
        reorderLevel: reorder,
        listingMrp: mrp,
        listingSellingPrice: selling,
      );
    } else {
      if (_categoryId == null || _categoryId!.isEmpty) {
        setState(() => _error = t('STORE_FORM.CATEGORY_NAME'));
        return;
      }
      input = UpdateStoreProductInput(
        isActive: _isActive,
        salePolicy: _salePolicy,
        rackLocation: _rack.text.trim().isEmpty ? null : _rack.text.trim(),
        reorderLevel: reorder,
        categoryId: _categoryId,
        name: _name.text,
        genericName: _generic.text.trim().isEmpty ? '' : _generic.text.trim(),
        manufacturer:
            _manufacturer.text.trim().isEmpty ? '' : _manufacturer.text.trim(),
        strength: _strength.text.trim().isEmpty ? '' : _strength.text.trim(),
        dosageForm: _dosageForm,
        baseUnit: _baseUnit,
        primaryPackType: _primaryPackType,
        primaryPackQuantity: packQty.clamp(1, 1 << 30),
        requiresPrescription: _requiresRx,
        listingMrp: mrp,
        listingSellingPrice: selling,
      );
    }

    final error = await ref
        .read(inventoryDetailProvider(widget.storeProductId).notifier)
        .saveListing(input);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error == 'AUTH_SUPABASE_MISSING'
            ? t('AUTH_SUPABASE_MISSING')
            : error;
      });
      return;
    }
    staffBack(
      context,
      fallback: Routes.staffMedicinesProduct(widget.storeProductId),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final busy = ref.watch(inventoryDetailProvider(widget.storeProductId)).busy;
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 420;
    final qtyEditable = isPackQuantityEditable(_dosageForm, _baseUnit);
    final allowedPackTypes = getAllowedPackTypesForDosageForm(_dosageForm);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          if (_isSystem) ...<Widget>[
            Text(
              t('STORE_FORM.CATALOG_PRODUCT_READ_ONLY'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_loadingCategories)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...<Widget>[
            if (!_isSystem) ...<Widget>[
              _SectionHeader(
                title: t('STORE_FORM.PRODUCT_INFO_SECTION'),
                description: t('STORE_FORM.PRODUCT_INFO_SECTION_DESC'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _categoryId,
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.CATEGORIES_TITLE'),
                          prefixIcon: const Icon(Icons.sell_outlined),
                        ),
                        items: _categories
                            .map(
                              (Category c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: busy
                            ? null
                            : (String? value) =>
                                setState(() => _categoryId = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.PRODUCT_NAME'),
                          prefixIcon: const Icon(Icons.medication_outlined),
                        ),
                        validator: (String? value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 2) {
                            return t('STORE_FORM.PRODUCT_NAME');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _PairRow(
                        wide: wide,
                        left: TextFormField(
                          controller: _generic,
                          decoration: InputDecoration(
                            labelText: t('STORE_FORM.GENERIC_NAME'),
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                        right: TextFormField(
                          controller: _manufacturer,
                          decoration: InputDecoration(
                            labelText: t('STOREFRONT.PRODUCT_MANUFACTURER'),
                            prefixIcon: const Icon(Icons.apartment_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PairRow(
                        wide: wide,
                        left: TextFormField(
                          controller: _strength,
                          decoration: InputDecoration(
                            labelText: t('STORE_FORM.STRENGTH'),
                            prefixIcon: const Icon(Icons.info_outline),
                          ),
                        ),
                        right: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _dosageForm,
                          decoration: InputDecoration(
                            labelText: t('STORE_FORM.DOSAGE_FORM'),
                            prefixIcon:
                                const Icon(Icons.water_drop_outlined),
                          ),
                          items: kDosageFormValues
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(_title(value)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: busy
                              ? null
                              : (String? value) {
                                  if (value == null) return;
                                  final defaults =
                                      getPackagingDefaultsForDosageForm(value);
                                  setState(() {
                                    _dosageForm = value;
                                    _baseUnit = defaults.baseUnit;
                                    _primaryPackType = defaults.primaryPackType;
                                    _primaryPackQuantity =
                                        defaults.primaryPackQuantity;
                                    _packQty.text =
                                        '$_primaryPackQuantity';
                                  });
                                },
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(t('STORE_FORM.REQUIRES_PRESCRIPTION')),
                        value: _requiresRx,
                        onChanged: busy
                            ? null
                            : (bool? value) => setState(
                                  () => _requiresRx = value ?? false,
                                ),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: t('STORE_FORM.PACKAGING_SECTION'),
                        description:
                            t('STORE_FORM.PACKAGING_SECTION_SHORT_DESC'),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: AppTheme.borderRadius,
                          border: Border.all(
                            color: const Color(0xFFCCFBF1),
                            width: AppTheme.hairline,
                          ),
                        ),
                        child: Text(
                          t('STORE_FORM.PACKAGING_SECTION_DESC'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF065F46),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.BASE_UNIT'),
                          filled: true,
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        child: Text(
                          getBaseUnitLabel(_baseUnit),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PairRow(
                        wide: wide,
                        left: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: allowedPackTypes.contains(_primaryPackType)
                              ? _primaryPackType
                              : allowedPackTypes.first,
                          decoration: InputDecoration(
                            labelText: t('STORE_FORM.PRIMARY_PACK_TYPE'),
                            prefixIcon: const Icon(Icons.layers_outlined),
                          ),
                          items: allowedPackTypes
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(getPrimaryPackTypeLabel(value)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: busy
                              ? null
                              : (String? value) {
                                  if (value == null) return;
                                  setState(() => _primaryPackType = value);
                                },
                        ),
                        right: TextFormField(
                          controller: _packQty,
                          enabled: !busy && qtyEditable,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: t('STORE_FORM.PRIMARY_PACK_QUANTITY'),
                            prefixIcon: const Icon(Icons.tag),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionHeader(
                      title: t('STORE_FORM.PRICING_SECTION'),
                      description: t('STORE_FORM.PRICING_SECTION_DESC'),
                    ),
                    const SizedBox(height: 12),
                    _PairRow(
                      wide: wide,
                      left: TextFormField(
                        controller: _mrp,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.MRP'),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                      ),
                      right: TextFormField(
                        controller: _selling,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.SELLING_PRICE'),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PairRow(
                      wide: wide,
                      left: TextFormField(
                        controller: _rack,
                        decoration: const InputDecoration(labelText: 'Rack'),
                      ),
                      right: TextFormField(
                        controller: _reorder,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reorder level',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _salePolicy,
                      decoration: const InputDecoration(
                        labelText: 'Sale policy',
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'inherit',
                          child: Text('Inherit'),
                        ),
                        DropdownMenuItem(
                          value: 'loose_allowed',
                          child: Text('Loose allowed'),
                        ),
                        DropdownMenuItem(
                          value: 'pack_only',
                          child: Text('Pack only'),
                        ),
                        DropdownMenuItem(
                          value: 'whole_only',
                          child: Text('Whole only'),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (String? value) {
                              if (value == null) return;
                              setState(() => _salePolicy = value);
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t('STORE_FORM.CATALOG_SET_ACTIVE')),
                      value: _isActive,
                      onChanged: busy
                          ? null
                          : (bool value) => setState(() => _isActive = value),
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
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => staffBack(
                              context,
                              fallback: Routes.staffMedicinesProduct(
                                widget.storeProductId,
                              ),
                            ),
                    child: Text(t('CANCEL')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    child: Text(t('CONFIRM')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _title(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String _num(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.wide,
    required this.left,
    required this.right,
  });

  final bool wide;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: <Widget>[
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}
