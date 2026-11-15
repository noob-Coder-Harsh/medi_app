import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/brand.dart';
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
import '../../../data/rpc/staff_write_rpc.dart';
import '../../../data/supabase_client.dart';
import '../auth/staff_session.dart';
import '../inventory/inventory_detail_controller.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';

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
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(
            context,
            fallback: Routes.staffMedicinesProduct(storeProductId),
          ),
        ),
        title: t('STORE_FORM.EDIT_PRODUCT'),
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
  late bool _isFeatured;
  late String _salePolicy;
  bool _loadingCategories = true;
  bool _saving = false;
  bool _preparingImage = false;
  String? _error;
  Uint8List? _imageBytes;
  String _imageFilename = 'product.webp';
  String? _networkImageUrl;
  bool _imageCleared = false;

  static const double _fieldGap = 10;
  static const EdgeInsets _densePad = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  bool get _isSystem => widget.product.isSystem;

  @override
  void initState() {
    super.initState();
    _networkImageUrl = widget.product.imageUrl ?? widget.product.thumb;
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
    _isFeatured = widget.product.isFeatured;
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
        if (_categoryId == null ||
            !_categories.any((Category c) => c.id == _categoryId)) {
          _categoryId = _categories.isEmpty ? null : _categories.first.id;
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
        _imageCleared = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = t('STORE_FORM.PRODUCT_IMAGE_PREPARE_FAILED'));
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

  double? _parseMoney(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mrp = _parseMoney(_mrp.text);
    final selling = _parseMoney(_selling.text);
    final reorder = int.tryParse(_reorder.text.trim()) ?? 0;
    final rack = _rack.text.trim().isEmpty ? null : _rack.text.trim();

    setState(() => _saving = true);
    try {
      String? imageUrlUpdate;
      if (!_isSystem) {
        if (_imageBytes != null && _imageBytes!.isNotEmpty) {
          final writes = ref.read(staffWriteRpcProvider);
          if (writes == null) {
            setState(() {
              _saving = false;
              _error = t('AUTH_SUPABASE_MISSING');
            });
            return;
          }
          final storeId = ref.read(staffSessionProvider).storeUser?.storeId;
          if (storeId == null || storeId.isEmpty) {
            setState(() {
              _saving = false;
              _error = 'STORE_REQUIRED';
            });
            return;
          }
          imageUrlUpdate = await writes.uploadProductImage(
            storeId: storeId,
            bytes: _imageBytes!,
            filename: _imageFilename,
          );
        } else if (_imageCleared) {
          imageUrlUpdate = '';
        }
      }

      final UpdateStoreProductInput input;
      if (_isSystem) {
        input = UpdateStoreProductInput(
          isActive: _isActive,
          isFeatured: _isFeatured,
          salePolicy: _salePolicy,
          rackLocation: rack,
          reorderLevel: reorder,
          listingMrp: mrp,
          listingSellingPrice: selling,
        );
      } else {
        if (_categoryId == null || _categoryId!.isEmpty) {
          setState(() {
            _saving = false;
            _error = t('STORE_FORM.CATEGORY_NAME');
          });
          return;
        }
        _syncPackQtyFromField();
        final qtyEditable = isPackQuantityEditable(_dosageForm, _baseUnit);
        final packQty =
            qtyEditable ? _primaryPackQuantity.clamp(1, 1 << 30) : 1;
        input = UpdateStoreProductInput(
          isActive: _isActive,
          isFeatured: _isFeatured,
          salePolicy: _salePolicy,
          rackLocation: rack,
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
          primaryPackQuantity: packQty,
          requiresPrescription: _requiresRx,
          listingMrp: mrp,
          listingSellingPrice: selling,
          imageUrl: imageUrlUpdate,
        );
      }

      final error = await ref
          .read(inventoryDetailProvider(widget.storeProductId).notifier)
          .saveListing(input);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _saving = false;
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
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
          .map(
            (o) => StaffSelectOption(value: o.value, label: o.label),
          )
          .toList(growable: false),
      selected: selected,
    );
  }

  String _salePolicyLabel(String value) {
    switch (value) {
      case 'inherit':
        return t('STORE_FORM.SALE_POLICY_INHERIT');
      case 'loose_allowed':
        return t('STORE_FORM.SALE_POLICY_LOOSE');
      case 'pack_only':
        return t('STORE_FORM.SALE_POLICY_PACK');
      case 'whole_only':
        return t('STORE_FORM.SALE_POLICY_WHOLE');
      default:
        return value;
    }
  }

  static const List<String> _salePolicyValues = <String>[
    'inherit',
    'loose_allowed',
    'pack_only',
    'whole_only',
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final providerBusy =
        ref.watch(inventoryDetailProvider(widget.storeProductId)).busy;
    final busy = providerBusy || _saving;
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
    final displayNetworkUrl =
        !_imageCleared && (_imageBytes == null || _imageBytes!.isEmpty)
            ? _networkImageUrl
            : null;
    final canEditIdentity = !_isSystem && !busy;

    return Form(
      key: _formKey,
      child: UnfocusOnTap(
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
                      if (_isSystem)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: BrandTeal.soft,
                            borderRadius: AppTheme.borderRadius,
                            border: Border.all(
                              color: BrandTeal.border,
                              width: AppTheme.hairline,
                            ),
                          ),
                          child: Text(
                            t('STORE_FORM.CATALOG_PRODUCT_READ_ONLY'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF065F46),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      _FormSection(
                          title: t('STORE_FORM.PRODUCT_INFO_SECTION'),
                          icon: Icons.medication_outlined,
                          initiallyExpanded: true,
                          compact: compact,
                          child: Column(
                            children: <Widget>[
                              _ProductImagePicker(
                                bytes: _imageBytes,
                                networkUrl: displayNetworkUrl,
                                enabled:
                                    canEditIdentity && !_preparingImage,
                                preparing: _preparingImage,
                                onPick: _showImageSourceSheet,
                                onRemove: () => setState(() {
                                  _imageBytes = null;
                                  _imageFilename = 'product.webp';
                                  _imageCleared = true;
                                }),
                              ),
                              const SizedBox(height: _fieldGap),
                              _LabeledField(
                                label: t('STORE_FORM.PRODUCT_NAME'),
                                required: true,
                                child: TextFormField(
                                  controller: _name,
                                  enabled: canEditIdentity,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _deco(
                                    hint: t(
                                      'STORE_FORM.PRODUCT_NAME_PLACEHOLDER',
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.inventory_2_outlined),
                                  ),
                                  validator: (String? value) {
                                    if (_isSystem) return null;
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
                                  enabled: canEditIdentity,
                                  textCapitalization: TextCapitalization.words,
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
                                  enabled: canEditIdentity,
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
                                  enabled: canEditIdentity,
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
                                  searchHint: t('STORE_FORM.SEARCH_CATEGORIES'),
                                  headerIcon: Icons.grid_view_rounded,
                                  onPick: _pickOption,
                                  onChanged: (String value) =>
                                      setState(() => _categoryId = value),
                                  validator: (String? value) {
                                    if (_isSystem) return null;
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
                                    enabled: canEditIdentity,
                                    decoration: _deco(
                                      hint: t('STORE_FORM.STRENGTH_PLACEHOLDER'),
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
                                    enabled: canEditIdentity,
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
                                    searchHint: t('STORE_FORM.SEARCH_DOSAGE_FORM'),
                                    headerIcon: Icons.medication_liquid_outlined,
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
                                onChanged: canEditIdentity
                                    ? (bool? value) => setState(
                                          () => _requiresRx = value ?? false,
                                        )
                                    : null,
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    t('STORE_FORM.PRODUCT_FEATURED_HINT'),
                                    style: theme.textTheme.bodySmall?.copyWith(
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
                                        : (allowedPackTypes.isEmpty
                                            ? _primaryPackType
                                            : allowedPackTypes.first),
                                    enabled: canEditIdentity,
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
                                    searchHint: t('STORE_FORM.SEARCH_PACK_TYPE'),
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
                                    enabled: canEditIdentity && qtyEditable,
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
                                      if (_isSystem || !qtyEditable) {
                                        return null;
                                      }
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
                            _TwoCol(
                              left: _LabeledField(
                                label: t('STORE_FORM.MRP'),
                                child: TextFormField(
                                  controller: _mrp,
                                  enabled: !busy,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _deco(
                                    prefixIcon:
                                        const Icon(Icons.currency_rupee),
                                  ),
                                ),
                              ),
                              right: _LabeledField(
                                label: t('STORE_FORM.SELLING_PRICE'),
                                child: TextFormField(
                                  controller: _selling,
                                  enabled: !busy,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _deco(
                                    prefixIcon:
                                        const Icon(Icons.currency_rupee),
                                    fillColor: BrandTeal.soft,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: _fieldGap),
                            _TwoCol(
                              left: _LabeledField(
                                label: t('STORE_FORM.RACK_LOCATION'),
                                child: TextFormField(
                                  controller: _rack,
                                  enabled: !busy,
                                  decoration: _deco(
                                    prefixIcon: const Icon(
                                      Icons.place_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              right: _LabeledField(
                                label: t('STORE_FORM.REORDER_LEVEL'),
                                child: TextFormField(
                                  controller: _reorder,
                                  enabled: !busy,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _deco(
                                    prefixIcon: const Icon(
                                      Icons.notifications_active_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: _fieldGap),
                            _LabeledField(
                              label: t('STORE_FORM.SALE_POLICY'),
                              child: StaffSheetSelectField(
                                value: _salePolicy,
                                enabled: !busy,
                                options: _salePolicyValues
                                    .map(
                                      (String value) => StaffSelectOption(
                                        value: value,
                                        label: _salePolicyLabel(value),
                                      ),
                                    )
                                    .toList(growable: false),
                                decoration: _deco(
                                  prefixIcon: const Icon(
                                    Icons.shopping_bag_outlined,
                                  ),
                                ),
                                title: t('STORE_FORM.SALE_POLICY'),
                                subtitle: t('STORE_FORM.SALE_POLICY_DESC'),
                                headerIcon: Icons.shopping_bag_outlined,
                                onChanged: (String value) =>
                                    setState(() => _salePolicy = value),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t('STORE_FORM.SALE_POLICY_DESC'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: _fieldGap),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                t('STORE_FORM.CATALOG_SET_ACTIVE'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              value: _isActive,
                              onChanged: busy
                                  ? null
                                  : (bool value) =>
                                      setState(() => _isActive = value),
                              activeThumbColor: Brand.themeColor,
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
                                  fallback: Routes.staffMedicinesProduct(
                                    widget.storeProductId,
                                  ),
                                ),
                        child: Text(t('CANCEL')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed:
                            busy || _loadingCategories ? null : _save,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(t('STORE_FORM.SAVE_PRODUCT')),
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

class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({
    required this.bytes,
    required this.networkUrl,
    required this.enabled,
    required this.preparing,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final bool enabled;
  final bool preparing;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get _hasLocal => bytes != null && bytes!.isNotEmpty;

  bool get _hasNetwork {
    final url = networkUrl?.trim() ?? '';
    return url.isNotEmpty;
  }

  bool get hasImage => _hasLocal || _hasNetwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                                    child: _hasLocal
                                        ? Image.memory(
                                            bytes!,
                                            fit: BoxFit.contain,
                                          )
                                        : Image.network(
                                            networkUrl!.trim(),
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace,
                                            ) =>
                                                Icon(
                                              Icons.broken_image_outlined,
                                              color: AppTheme.ink.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
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