import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand.dart';
import '../../../core/category_icons.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/slug.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_store.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';
import 'categories_controller.dart';
import 'category_thumb.dart';

/// Full-screen create / edit / view category (outside bottom bar).
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({
    super.key,
    this.categoryId,
  });

  /// Null = create custom category.
  final String? categoryId;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _sortOrder;
  var _slugEdited = false;
  var _isActive = true;
  var _saving = false;
  var _loading = false;
  String? _error;
  StaffCategory? _category;

  bool get _isCreate => widget.categoryId == null;

  bool get _isMaster => _category?.isSystem == true;

  bool get _canEdit => _isCreate || (_category != null && !_isMaster);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _slug = TextEditingController();
    _sortOrder = TextEditingController(text: '0');
    _name.addListener(_onNameChanged);
    if (!_isCreate) {
      _loading = true;
      Future<void>.microtask(_load);
    }
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _name.dispose();
    _slug.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_slugEdited && _isCreate && _canEdit) {
      final next = toSlug(_name.text);
      if (_slug.text != next) {
        _slug.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
    if (_isCreate && mounted) setState(() {});
  }

  String get _previewSlug {
    if (_isCreate) {
      final typed = _slug.text.trim();
      if (typed.isNotEmpty) return typed;
      return toSlug(_name.text);
    }
    return _category?.slug ?? toSlug(_name.text);
  }

  bool get _showingDefaultImage {
    final hasCustom = (_category?.iconUrl?.trim().isEmpty ?? true) == false;
    if (hasCustom) return false;
    final slug = _previewSlug;
    return resolveCategoryImageSrc(null, slug) != null ||
        resolveCategoryBannerSrc(slug) != null;
  }

  void _hydrate(StaffCategory category) {
    _category = category;
    _name.text = category.name;
    _slug.text = category.slug;
    _sortOrder.text = category.sortOrder.round().toString();
    _isActive = category.isActive;
    _slugEdited = true;
  }

  Future<void> _load() async {
    final id = widget.categoryId!;
    var found = ref.read(categoriesSettingsProvider.notifier).findById(id);
    if (found == null) {
      await ref.read(categoriesSettingsProvider.notifier).refresh();
      found = ref.read(categoriesSettingsProvider.notifier).findById(id);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (found == null) {
        _error = t('ERROR_GENERIC');
      } else {
        _hydrate(found);
      }
    });
  }

  Future<void> _save() async {
    if (!_canEdit || _saving) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _name.text.trim();
    final slug = _slug.text.trim();
    final sort = int.tryParse(_sortOrder.text.trim()) ?? 0;

    setState(() => _saving = true);
    final notifier = ref.read(categoriesSettingsProvider.notifier);
    final String? error;
    if (_isCreate) {
      error = await notifier.createCustom(
        name: name,
        slug: slug.isEmpty ? null : slug,
        sortOrder: sort,
      );
    } else {
      error = await notifier.updateCustom(
        categoryId: widget.categoryId!,
        name: name,
        sortOrder: sort,
        isActive: _isActive,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      final message = error;
      setState(() {
        if (message == 'AUTH_SUPABASE_MISSING') {
          _error = t('AUTH_SUPABASE_MISSING');
        } else if (message.startsWith('STORE_FORM.')) {
          _error = t(message);
        } else {
          _error = message;
        }
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            _isCreate
                ? 'STORE_FORM.CATEGORY_CREATED'
                : 'STORE_FORM.CATEGORY_SAVED',
          ),
        ),
      ),
    );
    staffBack(context, fallback: Routes.staffCategories);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final listState = ref.watch(categoriesSettingsProvider);
    final theme = Theme.of(context);
    final busy = _saving || listState.busy;
    final title = _isCreate
        ? t('STORE_FORM.CREATE_CUSTOM_CATEGORY')
        : (_isMaster
            ? t('STORE_FORM.VIEW_CATEGORY')
            : t('STORE_FORM.EDIT_CATEGORY'));

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: busy
              ? null
              : () => staffBack(context, fallback: Routes.staffCategories),
        ),
        title: title,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (!_isCreate && _category == null)
              ? Center(child: Text(_error ?? t('ERROR_GENERIC')))
              : UnfocusOnTap(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: <Widget>[
                              if (_isMaster)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: AppTheme.borderRadius,
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: Text(
                                    t('STORE_FORM.MASTER_CATEGORY_READ_ONLY'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF065F46),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              _CategoryImagePreview(
                                slug: _previewSlug,
                                iconUrl: _category?.iconUrl,
                                isDefault: _showingDefaultImage,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t('STORE_FORM.CATEGORY_NAME'),
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _name,
                                enabled: _canEdit && !busy,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: t('STORE_FORM.CATEGORY_NAME'),
                                  prefixIcon:
                                      const Icon(Icons.sell_outlined),
                                ),
                                validator: (String? value) {
                                  if (!_canEdit) return null;
                                  if ((value?.trim().length ?? 0) < 2) {
                                    return t('STORE_FORM.CATEGORY_NAME');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              Text(
                                t('STORE_FORM.CATEGORY_SLUG'),
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _slug,
                                enabled: _isCreate && _canEdit && !busy,
                                onChanged: (_) {
                                  _slugEdited = true;
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: t('STORE_FORM.CATEGORY_SLUG_HINT'),
                                  prefixIcon:
                                      const Icon(Icons.link_outlined),
                                  helperText: _isCreate
                                      ? t('STORE_FORM.CATEGORY_SLUG_HELP')
                                      : null,
                                ),
                                validator: (String? value) {
                                  if (!_isCreate) return null;
                                  final slug = (value ?? '').trim();
                                  if (slug.isEmpty) return null;
                                  if (toSlug(slug) != slug) {
                                    return t(
                                      'STORE_FORM.CATEGORY_SLUG_INVALID',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              Text(
                                t('STORE_FORM.CATEGORY_SORT_ORDER'),
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _sortOrder,
                                enabled: _canEdit && !busy,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  hintText: '0',
                                  prefixIcon: const Icon(Icons.sort),
                                  helperText: t(
                                    'STORE_FORM.CATEGORY_SORT_ORDER_HELP',
                                  ),
                                ),
                              ),
                              if (!_isCreate) ...<Widget>[
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(t('STORE_FORM.CATEGORY_ACTIVE')),
                                  subtitle: Text(
                                    t('STORE_FORM.CATEGORY_ACTIVE_HINT'),
                                  ),
                                  value: _isActive,
                                  onChanged: !_canEdit || busy
                                      ? null
                                      : (bool value) =>
                                          setState(() => _isActive = value),
                                ),
                              ],
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
                        if (_canEdit)
                          ColoredBox(
                            color: Brand.themeBackground,
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => staffBack(
                                                  context,
                                                  fallback:
                                                      Routes.staffCategories,
                                                ),
                                        child: Text(t('CANCEL')),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton.icon(
                                        onPressed: busy ? null : _save,
                                        icon: busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Icon(
                                                _isCreate
                                                    ? Icons.add
                                                    : Icons.save_outlined,
                                              ),
                                        label: Text(
                                          t(
                                            _isCreate
                                                ? 'STORE_FORM.CREATE_CUSTOM_CATEGORY'
                                                : 'STORE_FORM.SAVE',
                                          ),
                                        ),
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
}

class _CategoryImagePreview extends StatelessWidget {
  const _CategoryImagePreview({
    required this.slug,
    required this.iconUrl,
    required this.isDefault,
  });

  final String slug;
  final String? iconUrl;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCustomIcon = (iconUrl?.trim().isEmpty ?? true) == false;
    final banner = hasCustomIcon ? null : resolveCategoryBannerSrc(slug);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t('STORE_FORM.CATEGORY_IMAGE'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (banner != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.asset(
                banner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Align(
                  alignment: Alignment.centerLeft,
                  child: CategoryThumb(
                    slug: slug,
                    iconUrl: iconUrl,
                    size: 88,
                  ),
                ),
              ),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: CategoryThumb(
              slug: slug,
              iconUrl: iconUrl,
              size: 88,
            ),
          ),
        if (isDefault) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            t('STORE_FORM.CATEGORY_IMAGE_DEFAULT_HINT'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}
