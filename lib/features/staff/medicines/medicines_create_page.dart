import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/packaging.dart';
import '../../../core/packaging_constants.dart';
import '../../../core/product_image_prepare.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/catalog_product.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import '../../../data/rpc/listing_rpc.dart';
import '../../../data/supabase_client.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';
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
  bool _isFeatured = false;
  bool _loadingCategories = true;
  bool _genericEdited = false;
  String? _error;
  DateTime? _manufacturedAt;
  DateTime? _expiresAt;
  Uint8List? _imageBytes;
  String _imageFilename = 'product.webp';
  bool _preparingImage = false;

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

  Future<void> _pickImage(ImageSource source) async {
    if (_preparingImage) return;
    setState(() {
      _preparingImage = true;
      _error = null;
    });
    try {
      final prepared = await ProductImagePrepare.pickCropAndCompress(
        context: context,
        source: source,
      );
      if (!mounted) return;
      if (prepared == null) return;
      setState(() {
        _imageBytes = prepared.bytes;
        _imageFilename = prepared.filename;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = t('STORE_FORM.PRODUCT_IMAGE_PREPARE_FAILED'),
      );
      debugPrint('Product image prepare failed: $error');
    } finally {
      if (mounted) setState(() => _preparingImage = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(t('STORE_FORM.PRODUCT_IMAGE_GALLERY')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(t('STORE_FORM.PRODUCT_IMAGE_CAMERA')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    await _pickImage(source);
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
            isFeatured: _isFeatured,
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
          imageBytes: _imageBytes,
          imageFilename: _imageFilename,
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
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool dense = true,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: dense,
      filled: fillColor != null,
      fillColor: fillColor,
      contentPadding: dense ? _densePad : null,
      hintStyle: TextStyle(
        fontSize: 13,
        color: AppTheme.ink.withValues(alpha: 0.38),
      ),
    );
  }

  Future<String?> _pickOption({
    required String title,
    required List<_SelectOption> options,
    String? selected,
    String? subtitle,
    String? searchHint,
    IconData? headerIcon,
  }) {
    return showStaffOptionSheet(
      context: context,
      title: title,
      subtitle: subtitle,
      searchHint: searchHint,
      headerIcon: headerIcon,
      options: options
          .map((o) => StaffSelectOption(value: o.value, label: o.label))
          .toList(growable: false),
      selected: selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final busy = ref.watch(medicinesProvider).busyWrite;
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 390;
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
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: busy
              ? null
              : () => staffBack(context, fallback: Routes.staffMedicines),
        ),
        title: t('STORE_FORM.CREATE_PRODUCT'),
      ),
      body: UnfocusOnTap(
        child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            Expanded(
              child: _loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 12 : 16,
                        10,
                        compact ? 12 : 16,
                        24,
                      ),
                      children: <Widget>[
                        _FormSection(
                          title: t('STORE_FORM.PRODUCT_INFO_SECTION'),
                          icon: Icons.medication_outlined,
                          initiallyExpanded: true,
                          compact: compact,
                          child: Column(
                            children: <Widget>[
                              _ProductImagePicker(
                                bytes: _imageBytes,
                                enabled: !busy && !_preparingImage,
                                preparing: _preparingImage,
                                onPick: _showImageSourceSheet,
                                onRemove: () => setState(() {
                                  _imageBytes = null;
                                  _imageFilename = 'product.webp';
                                }),
                              ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STORE_FORM.PRODUCT_NAME'),
                                required: true,
                                child: TextFormField(
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: _onNameChanged,
                                  decoration: _deco(
                                    hint: t(
                                      'STORE_FORM.PRODUCT_NAME_PLACEHOLDER',
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.inventory_2_outlined),
                                  ),
                                  validator: (String? value) {
                                    final text = value?.trim() ?? '';
                                    if (text.length < 2) {
                                      return t('STORE_FORM.PRODUCT_NAME');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STORE_FORM.GENERIC_NAME'),
                                child: TextFormField(
                                  controller: _generic,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: _onGenericChanged,
                                  decoration: _deco(
                                    hint: t(
                                      'STORE_FORM.GENERIC_NAME_PLACEHOLDER',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.medication_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STOREFRONT.PRODUCT_MANUFACTURER'),
                                child: TextFormField(
                                  controller: _manufacturer,
                                  decoration: _deco(
                                    hint: t(
                                      'STORE_FORM.MANUFACTURER_PLACEHOLDER',
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.apartment_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STORE_FORM.CATEGORIES_TITLE'),
                                required: true,
                                child: _SheetSelectField(
                                  value: _categoryId,
                                  enabled: !busy,
                                  options: _categories
                                      .map(
                                        (Category c) => _SelectOption(
                                          value: c.id,
                                          label: c.name,
                                        ),
                                      )
                                      .toList(growable: false),
                                  decoration: _deco(
                                    hint: t('STORE_FORM.CATEGORIES_TITLE'),
                                    prefixIcon:
                                        const Icon(Icons.sell_outlined),
                                  ),
                                  title: t('STORE_FORM.CATEGORY_PICK_TITLE'),
                                  subtitle: t(
                                    'STORE_FORM.CATEGORY_PICK_SUBTITLE',
                                  ),
                                  searchHint:
                                      t('STORE_FORM.SEARCH_CATEGORIES'),
                                  headerIcon: Icons.grid_view_rounded,
                                  onPick: _pickOption,
                                  onChanged: (String value) =>
                                      setState(() => _categoryId = value),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return t('STORE_FORM.CATEGORIES_TITLE');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: _LabeledField(
                                  label: t('STORE_FORM.STRENGTH'),
                                  child: TextFormField(
                                    controller: _strength,
                                    decoration: _deco(
                                      hint: t(
                                        'STORE_FORM.STRENGTH_PLACEHOLDER',
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.speed_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                right: _LabeledField(
                                  label: t('STORE_FORM.DOSAGE_FORM'),
                                  child: _SheetSelectField(
                                    value: _dosageForm,
                                    enabled: !busy,
                                    options: kDosageFormValues
                                        .map(
                                          (String value) => _SelectOption(
                                            value: value,
                                            label: _title(value),
                                          ),
                                        )
                                        .toList(growable: false),
                                    decoration: _deco(
                                      prefixIcon: const Icon(
                                        Icons.medication_liquid_outlined,
                                      ),
                                    ),
                                    title: t('STORE_FORM.DOSAGE_FORM'),
                                    subtitle: t(
                                      'STORE_FORM.DOSAGE_FORM_PICK_SUBTITLE',
                                    ),
                                    searchHint:
                                        t('STORE_FORM.SEARCH_DOSAGE_FORM'),
                                    headerIcon:
                                        Icons.medication_liquid_outlined,
                                    onPick: _pickOption,
                                    onChanged: (String value) =>
                                        _onDosageChanged(value),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  t('STORE_FORM.REQUIRES_PRESCRIPTION'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                                value: _requiresRx,
                                onChanged: busy
                                    ? null
                                    : (bool? value) => setState(
                                          () => _requiresRx = value ?? false,
                                        ),
                              ),
                              const SizedBox(height: 4),
                              Material(
                                color: BrandTeal.soft,
                                borderRadius: AppTheme.borderRadius,
                                child: SwitchListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  dense: true,
                                  secondary: Icon(
                                    Icons.star_outline_rounded,
                                    color: Brand.themeColor,
                                  ),
                                  value: _isFeatured,
                                  onChanged: busy
                                      ? null
                                      : (bool value) => setState(
                                            () => _isFeatured = value,
                                          ),
                                  title: Text(
                                    t('STORE_FORM.PRODUCT_FEATURED'),
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    t('STORE_FORM.PRODUCT_FEATURED_HINT'),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  activeThumbColor: Brand.themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FormSection(
                          title: t('STORE_FORM.PACKAGING_SECTION'),
                          icon: Icons.layers_outlined,
                          initiallyExpanded: true,
                          compact: compact,
                          child: Column(
                            children: <Widget>[
                              _TwoCol(
                                left: _LabeledField(
                                  label: t('STORE_FORM.PRIMARY_PACK_TYPE'),
                                  child: _SheetSelectField(
                                    value: allowedPackTypes
                                            .contains(_primaryPackType)
                                        ? _primaryPackType
                                        : allowedPackTypes.first,
                                    enabled: !busy,
                                    options: allowedPackTypes
                                        .map(
                                          (String value) => _SelectOption(
                                            value: value,
                                            label: getPrimaryPackTypeLabel(
                                              value,
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                    decoration: _deco(
                                      prefixIcon:
                                          const Icon(Icons.layers_outlined),
                                    ),
                                    title: t('STORE_FORM.PRIMARY_PACK_TYPE'),
                                    subtitle: t(
                                      'STORE_FORM.PACK_TYPE_PICK_SUBTITLE',
                                    ),
                                    searchHint:
                                        t('STORE_FORM.SEARCH_PACK_TYPE'),
                                    headerIcon: Icons.layers_outlined,
                                    onPick: _pickOption,
                                    onChanged: (String value) =>
                                        _onPackTypeChanged(value),
                                  ),
                                ),
                                right: _LabeledField(
                                  label: t('STORE_FORM.PRIMARY_PACK_QUANTITY'),
                                  child: TextFormField(
                                    controller: _packQty,
                                    enabled: !busy && qtyEditable,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _deco(
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
                              ),
                              const SizedBox(height: _fieldGap),
                              _PackPreviewCard(preview: preview),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FormSection(
                          title: t('STORE_FORM.PRICING_SECTION'),
                          icon: Icons.currency_rupee,
                          initiallyExpanded: true,
                          compact: compact,
                          child: Column(
                            children: <Widget>[
                              const _StockCalcHint(),
                              const SizedBox(height: _fieldGap),
                              _TwoCol(
                                left: _LabeledField(
                                  label: t('STORE_FORM.PURCHASE_PRICE'),
                                  child: TextFormField(
                                    controller: _purchase,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: _deco(
                                      prefixIcon:
                                          const Icon(Icons.currency_rupee),
                                    ),
                                    validator: (String? value) {
                                      final parsed = _parseMoney(value ?? '');
                                      if (parsed == null || parsed < 0) {
                                        return t('STORE_FORM.PURCHASE_PRICE');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                right: _LabeledField(
                                  label: t('STORE_FORM.MRP'),
                                  child: TextFormField(
                                    controller: _mrp,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: _deco(
                                      prefixIcon:
                                          const Icon(Icons.currency_rupee),
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
                              ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STORE_FORM.SELLING_PRICE'),
                                required: true,
                                child: TextFormField(
                                  controller: _selling,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _deco(
                                    prefixIcon:
                                        const Icon(Icons.currency_rupee),
                                    fillColor: BrandTeal.soft,
                                  ),
                                  validator: (String? value) {
                                    final parsed = _parseMoney(value ?? '');
                                    if (parsed == null || parsed < 0) {
                                      return t('STORE_FORM.SELLING_PRICE');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              if (compact) ...<Widget>[
                                _TwoCol(
                                  left: _LabeledField(
                                    label: t('STORE_FORM.BATCH_NO'),
                                    child: TextFormField(
                                      controller: _batchNo,
                                      decoration: _deco(
                                        prefixIcon: const Icon(
                                          Icons.qr_code_2_outlined,
                                        ),
                                      ),
                                      validator: (String? value) {
                                        if ((value?.trim() ?? '').isEmpty) {
                                          return t('STORE_FORM.BATCH_NO');
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  right: _LabeledField(
                                    label: t('STORE_FORM.QUANTITY'),
                                    child: TextFormField(
                                      controller: _quantity,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _deco(
                                        prefixIcon: const Icon(
                                          Icons.warehouse_outlined,
                                        ),
                                      ),
                                      validator: (String? value) {
                                        final parsed = int.tryParse(
                                          value?.trim() ?? '',
                                        );
                                        if (parsed == null || parsed < 1) {
                                          return t('STORE_FORM.QUANTITY');
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: _fieldGap),
                                _LabeledField(
                                  label: t('STORE_FORM.EXPIRES_AT'),
                                  child: _DateField(
                                    value: _expiresAt,
                                    enabled: !busy,
                                    dense: true,
                                    onTap: () =>
                                        _pickDate(manufacturing: false),
                                    onClear: () => setState(
                                      () => _expiresAt = null,
                                    ),
                                  ),
                                ),
                              ] else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: _LabeledField(
                                        label: t('STORE_FORM.BATCH_NO'),
                                        child: TextFormField(
                                          controller: _batchNo,
                                          decoration: _deco(
                                            prefixIcon: const Icon(
                                              Icons.qr_code_2_outlined,
                                            ),
                                          ),
                                          validator: (String? value) {
                                            if ((value?.trim() ?? '')
                                                .isEmpty) {
                                              return t('STORE_FORM.BATCH_NO');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _LabeledField(
                                        label: t('STORE_FORM.EXPIRES_AT'),
                                        child: _DateField(
                                          value: _expiresAt,
                                          enabled: !busy,
                                          dense: true,
                                          onTap: () =>
                                              _pickDate(manufacturing: false),
                                          onClear: () => setState(
                                            () => _expiresAt = null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _LabeledField(
                                        label: t('STORE_FORM.QUANTITY'),
                                        child: TextFormField(
                                          controller: _quantity,
                                          keyboardType: TextInputType.number,
                                          inputFormatters:
                                              <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: _deco(
                                            prefixIcon: const Icon(
                                              Icons.warehouse_outlined,
                                            ),
                                          ),
                                          validator: (String? value) {
                                            final parsed = int.tryParse(
                                              value?.trim() ?? '',
                                            );
                                            if (parsed == null ||
                                                parsed < 1) {
                                              return t('STORE_FORM.QUANTITY');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STORE_FORM.MANUFACTURED_AT'),
                                child: _DateField(
                                  value: _manufacturedAt,
                                  enabled: !busy,
                                  dense: true,
                                  onTap: () =>
                                      _pickDate(manufacturing: true),
                                  onClear: () => setState(
                                    () => _manufacturedAt = null,
                                  ),
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
            ColoredBox(
              color: Brand.themeBackground,
              child: SafeArea(
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
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _title(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _FormSection extends StatefulWidget {
  const _FormSection({
    required this.title,
    required this.child,
    this.icon,
    this.initiallyExpanded = true,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final bool initiallyExpanded;
  final bool compact;

  @override
  State<_FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<_FormSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSize = widget.compact ? 14.0 : 15.0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            borderRadius: AppTheme.borderRadius,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                widget.compact ? 12 : 14,
                12,
                widget.compact ? 8 : 10,
                12,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.icon != null) ...<Widget>[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: Brand.themeColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.compact ? 12 : 14,
                0,
                widget.compact ? 12 : 14,
                widget.compact ? 12 : 14,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _SelectOption {
  const _SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}


class _SheetSelectField extends FormField<String> {
  _SheetSelectField({
    required String? value,
    required List<_SelectOption> options,
    required String title,
    required Future<String?> Function({
      required String title,
      required List<_SelectOption> options,
      String? selected,
      String? subtitle,
      String? searchHint,
      IconData? headerIcon,
    }) onPick,
    required ValueChanged<String> onChanged,
    required InputDecoration decoration,
    String? subtitle,
    String? searchHint,
    IconData? headerIcon,
    super.validator,
    bool enabled = true,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<String> field) {
            final current = value ?? field.value;
            String? label;
            for (final option in options) {
              if (option.value == current) {
                label = option.label;
                break;
              }
            }
            final hintColor = AppTheme.ink.withValues(alpha: 0.38);
            return InkWell(
              borderRadius: AppTheme.borderRadius,
              onTap: !enabled || options.isEmpty
                  ? null
                  : () async {
                      final picked = await onPick(
                        title: title,
                        options: options,
                        selected: current,
                        subtitle: subtitle,
                        searchHint: searchHint,
                        headerIcon: headerIcon,
                      );
                      if (picked == null) return;
                      field.didChange(picked);
                      onChanged(picked);
                    },
              child: InputDecorator(
                isEmpty: label == null || label.isEmpty,
                decoration: decoration.copyWith(
                  errorText: field.errorText,
                  suffixIcon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled
                        ? AppTheme.ink.withValues(alpha: 0.45)
                        : AppTheme.ink.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  label ?? decoration.hintText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(field.context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        color: label == null ? hintColor : null,
                      ),
                ),
              ),
            );
          },
        );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            children: required
                ? const <InlineSpan>[
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
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

class _PackPreviewCard extends StatelessWidget {
  const _PackPreviewCard({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrandTeal.soft,
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: BrandTeal.border, width: AppTheme.hairline),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              preview,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
              const Icon(Icons.info_outline, size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  t('STORE_FORM.STOCK_CALC_TITLE'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: amberFg,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            t('STORE_FORM.STOCK_CALC_DESC'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: amberFg.withValues(alpha: 0.85),
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: examples
                .map(
                  (String text) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: amberFg,
                        fontSize: 10.5,
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
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
    this.dense = false,
  });

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: dense ? 13 : null,
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

class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({
    required this.bytes,
    required this.enabled,
    required this.preparing,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final bool enabled;
  final bool preparing;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = bytes != null && bytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('STORE_FORM.PRODUCT_IMAGE'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.ink.withValues(alpha: 0.72),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            InkWell(
              onTap: enabled ? onPick : null,
              borderRadius: AppTheme.borderRadius,
              child: CustomPaint(
                painter: hasImage ? null : const _DashedBorderPainter(),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: preparing
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : hasImage
                          ? Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: AppTheme.borderRadius,
                                  child: ColoredBox(
                                    color: Colors.white,
                                    child: Image.memory(
                                      bytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: enabled ? onPick : null,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: AppTheme.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.photo_camera_outlined,
                                  color: Brand.themeColor.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t('STORE_FORM.PRODUCT_IMAGE_ADD'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    color: Brand.themeColor,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            if (hasImage) ...<Widget>[
              const SizedBox(width: 12),
              TextButton(
                onPressed: enabled ? onRemove : null,
                child: Text(t('STORE_FORM.PRODUCT_IMAGE_REMOVE')),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Brand.themeColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 3.5;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
      const Radius.circular(AppTheme.radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class BrandTeal {
  static const Color soft = Color(0xFFF0FDFA);
  static const Color border = Color(0xFFCCFBF1);
}
