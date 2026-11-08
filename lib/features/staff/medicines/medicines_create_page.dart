import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
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
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'medicines_controller.dart';

/// Full-screen create product (outside bottom bar).
class MedicinesCreatePage extends ConsumerStatefulWidget {
  const MedicinesCreatePage({super.key});

  @override
  ConsumerState<MedicinesCreatePage> createState() =>
      _MedicinesCreatePageState();
}

class _MedicinesCreatePageState extends ConsumerState<MedicinesCreatePage> {
  final _name = TextEditingController();
  final _generic = TextEditingController();
  final _manufacturer = TextEditingController();
  final _strength = TextEditingController();
  final _packQty = TextEditingController();
  final _batchNo = TextEditingController(text: 'B001');
  final _quantity = TextEditingController(text: '1');
  final _purchase = TextEditingController(text: '0');
  final _mrp = TextEditingController(text: '0');
  final _selling = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();

  List<Category> _categories = const <Category>[];
  String? _categoryId;
  String _dosageForm = 'tablet';
  late String _baseUnit;
  late String _primaryPackType;
  late int _primaryPackQuantity;
  bool _requiresRx = false;
  bool _loadingCategories = true;
  bool _genericEdited = false;
  String? _error;
  DateTime? _manufacturedAt;
  DateTime? _expiresAt;

  static const double _fieldGap = 10;
  static const EdgeInsets _densePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  @override
  void initState() {
    super.initState();
    _applyPackagingDefaults('tablet', force: true);
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _generic.dispose();
    _manufacturer.dispose();
    _strength.dispose();
    _packQty.dispose();
    _batchNo.dispose();
    _quantity.dispose();
    _purchase.dispose();
    _mrp.dispose();
    _selling.dispose();
    super.dispose();
  }

  void _applyPackagingDefaults(String? dosageForm, {bool force = false}) {
    final defaults = getPackagingDefaultsForDosageForm(dosageForm);
    _baseUnit = defaults.baseUnit;
    _primaryPackType = defaults.primaryPackType;
    _primaryPackQuantity = defaults.packQuantityEditable
        ? defaults.primaryPackQuantity
        : 1;
    if (force || _packQty.text != '$_primaryPackQuantity') {
      _packQty.text = '$_primaryPackQuantity';
    }
  }

  void _onDosageChanged(String? value) {
    final next = value ?? 'tablet';
    setState(() {
      _dosageForm = next;
      _applyPackagingDefaults(next, force: true);
    });
  }

  void _onPackTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _primaryPackType = value;
      if (!isPackQuantityEditable(_dosageForm, _baseUnit)) {
        _primaryPackQuantity = 1;
        _packQty.text = '1';
      }
    });
  }

  void _onNameChanged(String value) {
    if (_genericEdited) return;
    _generic.text = value;
  }

  void _onGenericChanged(String value) {
    final name = _name.text;
    if (value != name) {
      _genericEdited = true;
    } else if (value == name) {
      _genericEdited = false;
    }
  }

  void _syncPackQtyFromField() {
    final parsed = int.tryParse(_packQty.text.trim());
    if (parsed != null && parsed >= 1) {
      _primaryPackQuantity = parsed;
    }
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
        _categoryId = _categories.isEmpty ? null : _categories.first.id;
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

  Future<void> _pickDate({required bool manufacturing}) async {
    final initial = manufacturing
        ? (_manufacturedAt ?? DateTime.now())
        : (_expiresAt ?? DateTime.now().add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (manufacturing) {
        _manufacturedAt = picked;
      } else {
        _expiresAt = picked;
      }
    });
  }

  String? _isoDate(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double? _parseMoney(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categoryId = _categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      setState(() => _error = t('STORE_FORM.CATEGORY_NAME'));
      return;
    }

    _syncPackQtyFromField();
    final qtyEditable = isPackQuantityEditable(_dosageForm, _baseUnit);
    final packQty = qtyEditable ? _primaryPackQuantity.clamp(1, 1 << 30) : 1;

    final quantity = int.tryParse(_quantity.text.trim());
    final purchase = _parseMoney(_purchase.text);
    final mrp = _parseMoney(_mrp.text);
    final selling = _parseMoney(_selling.text);
    if (quantity == null ||
        purchase == null ||
        mrp == null ||
        selling == null) {
      setState(() => _error = t('STORE_FORM.PRICING_SECTION'));
      return;
    }

    final error = await ref.read(medicinesProvider.notifier).createCustom(
          CreateCustomProductInput(
            categoryId: categoryId,
            name: _name.text,
            genericName: _generic.text,
            manufacturer: _manufacturer.text,
            strength: _strength.text,
            dosageForm: _dosageForm,
            baseUnit: _baseUnit,
            primaryPackType: _primaryPackType,
            primaryPackQuantity: packQty,
            requiresPrescription: _requiresRx,
            openingBatch: OpeningBatchInput(
              batchNo: _batchNo.text,
              quantity: quantity,
              purchasePrice: purchase,
              mrp: mrp,
              sellingPrice: selling,
              manufacturedAt: _isoDate(_manufacturedAt),
              expiresAt: _isoDate(_expiresAt),
            ),
          ),
        );

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error == 'AUTH_SUPABASE_MISSING'
          ? t('AUTH_SUPABASE_MISSING')
          : error);
      return;
    }
    context.pop(true);
  }

  InputDecoration _deco({
    required String label,
    String? hint,
    Widget? prefixIcon,
    bool dense = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      isDense: dense,
      contentPadding: dense ? _densePad : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final busy = ref.watch(medicinesProvider).busyWrite;
    final theme = Theme.of(context);
    final qtyEditable = isPackQuantityEditable(_dosageForm, _baseUnit);
    final allowedPackTypes = getAllowedPackTypesForDosageForm(_dosageForm);
    final preview = formatPackLabel(
      PackagingInfo(
        baseUnit: _baseUnit,
        primaryPackType: _primaryPackType,
        primaryPackQuantity: qtyEditable
            ? (int.tryParse(_packQty.text.trim()) ?? _primaryPackQuantity)
                .toDouble()
            : 1,
      ),
    );

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: busy
              ? null
              : () => staffBack(context, fallback: Routes.staffMedicines),
        ),
        title: t('STORE_FORM.CREATE_PRODUCT'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Expanded(
              child: _loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: <Widget>[
                        Text(
                          t('STORE_FORM.CATALOG_CUSTOM_HINT'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormSection(
                          title: t('STORE_FORM.PRODUCT_INFO_SECTION'),
                          description:
                              t('STORE_FORM.PRODUCT_INFO_SECTION_DESC'),
                          child: Column(
                            children: <Widget>[
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _categoryId,
                                decoration: _deco(
                                  label: t('STORE_FORM.CATEGORIES_TITLE'),
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
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return t('STORE_FORM.CATEGORIES_TITLE');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: TextFormField(
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: _onNameChanged,
                                  decoration: _deco(
                                    label: t('STORE_FORM.PRODUCT_NAME'),
                                    hint: t(
                                      'STORE_FORM.PRODUCT_NAME_PLACEHOLDER',
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.medication_outlined),
                                  ),
                                  validator: (String? value) {
                                    final text = value?.trim() ?? '';
                                    if (text.length < 2) {
                                      return t('STORE_FORM.PRODUCT_NAME');
                                    }
                                    return null;
                                  },
                                ),
                                right: TextFormField(
                                  controller: _generic,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: _onGenericChanged,
                                  decoration: _deco(
                                    label: t('STORE_FORM.GENERIC_NAME'),
                                    hint: t(
                                      'STORE_FORM.GENERIC_NAME_PLACEHOLDER',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: TextFormField(
                                  controller: _manufacturer,
                                  decoration: _deco(
                                    label:
                                        t('STOREFRONT.PRODUCT_MANUFACTURER'),
                                    hint: t(
                                      'STORE_FORM.MANUFACTURER_PLACEHOLDER',
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.apartment_outlined),
                                  ),
                                ),
                                right: TextFormField(
                                  controller: _strength,
                                  decoration: _deco(
                                    label: t('STORE_FORM.STRENGTH'),
                                    hint:
                                        t('STORE_FORM.STRENGTH_PLACEHOLDER'),
                                    prefixIcon:
                                        const Icon(Icons.info_outline),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _dosageForm,
                                decoration: _deco(
                                  label: t('STORE_FORM.DOSAGE_FORM'),
                                  prefixIcon: const Icon(
                                    Icons.water_drop_outlined,
                                  ),
                                ),
                                items: kDosageFormValues
                                    .map(
                                      (String value) =>
                                          DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(_title(value)),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: busy ? null : _onDosageChanged,
                              ),
                              const SizedBox(height: 4),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  t('STORE_FORM.REQUIRES_PRESCRIPTION'),
                                ),
                                value: _requiresRx,
                                onChanged: busy
                                    ? null
                                    : (bool? value) => setState(
                                          () => _requiresRx = value ?? false,
                                        ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          title: t('STORE_FORM.PACKAGING_SECTION'),
                          description:
                              t('STORE_FORM.PACKAGING_SECTION_SHORT_DESC'),
                          child: Column(
                            children: <Widget>[
                              _InfoBanner(
                                text: t('STORE_FORM.PACKAGING_SECTION_DESC'),
                                background: BrandTeal.soft,
                                border: BrandTeal.border,
                                foreground: const Color(0xFF065F46),
                              ),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: DropdownButtonFormField<String>(
                                  // ignore: deprecated_member_use
                                  value: allowedPackTypes
                                          .contains(_primaryPackType)
                                      ? _primaryPackType
                                      : allowedPackTypes.first,
                                  decoration: _deco(
                                    label: t('STORE_FORM.PRIMARY_PACK_TYPE'),
                                    prefixIcon:
                                        const Icon(Icons.layers_outlined),
                                  ),
                                  items: allowedPackTypes
                                      .map(
                                        (String value) =>
                                            DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            getPrimaryPackTypeLabel(value),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged:
                                      busy ? null : _onPackTypeChanged,
                                ),
                                right: TextFormField(
                                  controller: _packQty,
                                  enabled: !busy && qtyEditable,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _deco(
                                    label:
                                        t('STORE_FORM.PRIMARY_PACK_QUANTITY'),
                                    prefixIcon: const Icon(Icons.tag),
                                  ),
                                  onChanged: (_) {
                                    _syncPackQtyFromField();
                                    setState(() {});
                                  },
                                  validator: (String? value) {
                                    if (!qtyEditable) return null;
                                    final parsed =
                                        int.tryParse(value?.trim() ?? '');
                                    if (parsed == null || parsed < 1) {
                                      return t(
                                        'STORE_FORM.PRIMARY_PACK_QUANTITY',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _PackPreviewCard(preview: preview),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          title: t('STORE_FORM.PRICING_SECTION'),
                          description: t('STORE_FORM.PRICING_SECTION_DESC'),
                          child: Column(
                            children: <Widget>[
                              const _StockCalcHint(),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: TextFormField(
                                  controller: _batchNo,
                                  decoration: _deco(
                                    label: t('STORE_FORM.BATCH_NO'),
                                    prefixIcon: const Icon(Icons.tag),
                                    dense: true,
                                  ),
                                  validator: (String? value) {
                                    if ((value?.trim() ?? '').isEmpty) {
                                      return t('STORE_FORM.BATCH_NO');
                                    }
                                    return null;
                                  },
                                ),
                                right: TextFormField(
                                  controller: _quantity,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _deco(
                                    label: t('STORE_FORM.QUANTITY'),
                                    prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    dense: true,
                                  ),
                                  validator: (String? value) {
                                    final parsed =
                                        int.tryParse(value?.trim() ?? '');
                                    if (parsed == null || parsed < 1) {
                                      return t('STORE_FORM.QUANTITY');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: TextFormField(
                                  controller: _purchase,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _deco(
                                    label: t('STORE_FORM.PURCHASE_PRICE'),
                                    prefixIcon:
                                        const Icon(Icons.currency_rupee),
                                    dense: true,
                                  ),
                                  validator: (String? value) {
                                    final parsed = _parseMoney(value ?? '');
                                    if (parsed == null || parsed < 0) {
                                      return t('STORE_FORM.PURCHASE_PRICE');
                                    }
                                    return null;
                                  },
                                ),
                                right: TextFormField(
                                  controller: _mrp,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _deco(
                                    label: t('STORE_FORM.MRP'),
                                    prefixIcon:
                                        const Icon(Icons.currency_rupee),
                                    dense: true,
                                  ),
                                  validator: (String? value) {
                                    final parsed = _parseMoney(value ?? '');
                                    if (parsed == null || parsed < 0) {
                                      return t('STORE_FORM.MRP');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              TextFormField(
                                controller: _selling,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: _deco(
                                  label: t('STORE_FORM.SELLING_PRICE'),
                                  prefixIcon:
                                      const Icon(Icons.currency_rupee),
                                  dense: true,
                                ),
                                validator: (String? value) {
                                  final parsed = _parseMoney(value ?? '');
                                  if (parsed == null || parsed < 0) {
                                    return t('STORE_FORM.SELLING_PRICE');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: _DateField(
                                  label: t('STORE_FORM.MANUFACTURED_AT'),
                                  value: _manufacturedAt,
                                  enabled: !busy,
                                  dense: true,
                                  onTap: () =>
                                      _pickDate(manufacturing: true),
                                  onClear: () => setState(
                                    () => _manufacturedAt = null,
                                  ),
                                ),
                                right: _DateField(
                                  label: t('STORE_FORM.EXPIRES_AT'),
                                  value: _expiresAt,
                                  enabled: !busy,
                                  dense: true,
                                  onTap: () =>
                                      _pickDate(manufacturing: false),
                                  onClear: () =>
                                      setState(() => _expiresAt = null),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => staffBack(
                                  context,
                                  fallback: Routes.staffMedicines,
                                ),
                        child: Text(t('CANCEL')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed:
                            busy || _loadingCategories ? null : _submit,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(t('STORE_FORM.CREATE_PRODUCT')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Always two columns — phone (360px) included.
class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: border, width: AppTheme.hairline),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              height: 1.35,
            ),
      ),
    );
  }
}

class _PackPreviewCard extends StatelessWidget {
  const _PackPreviewCard({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrandTeal.soft,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: BrandTeal.border, width: AppTheme.hairline),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BrandTeal.border),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t('STORE_FORM.PACKAGING_PREVIEW').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  preview,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
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

class _StockCalcHint extends StatelessWidget {
  const _StockCalcHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const amberBg = Color(0xFFFFFBEB);
    const amberBorder = Color(0xFFFDE68A);
    const amberFg = Color(0xFF78350F);
    final examples = <String>[
      t('STORE_FORM.STOCK_CALC_TABLETS'),
      t('STORE_FORM.STOCK_CALC_CAPSULES'),
      t('STORE_FORM.STOCK_CALC_SYRUP'),
      t('STORE_FORM.STOCK_CALC_INJECTION'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: amberBg,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: amberBorder, width: AppTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t('STORE_FORM.STOCK_CALC_TITLE'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: amberFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t('STORE_FORM.STOCK_CALC_DESC'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: amberFg.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: examples
                .map(
                  (String text) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: amberFg,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
    this.dense = false,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final display = value == null ? 'dd-mm-yyyy' : Format.date(value!);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: dense,
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : null,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: value == null
            ? null
            : IconButton(
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.clear, size: 18),
              ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            display,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: dense ? 14 : null,
                  color: value == null
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45)
                      : null,
                ),
          ),
        ),
      ),
    );
  }
}

abstract final class BrandTeal {
  static const Color soft = Color(0xFFF0FDFA);
  static const Color border = Color(0xFFCCFBF1);
}
