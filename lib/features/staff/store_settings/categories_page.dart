import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_store.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import '../ui/staff_ui.dart';
import 'categories_controller.dart';
import 'category_thumb.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  final _search = TextEditingController();
  final _selectedIds = <String>{};
  final _availableIds = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<StaffCategory> _filter(
    List<StaffCategory> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (StaffCategory c) =>
              c.name.toLowerCase().contains(q) ||
              c.slug.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Future<void> _openCategory(StaffCategory category) async {
    await context.push(Routes.staffCategoriesEdit(category.id));
    if (!mounted) return;
    await ref.read(categoriesSettingsProvider.notifier).refresh();
  }

  Future<void> _createCustom() async {
    await context.push(Routes.staffCategoriesCreate);
    if (!mounted) return;
    await ref.read(categoriesSettingsProvider.notifier).refresh();
  }

  Future<void> _deactivateCustom(StaffCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('STORE_FORM.EDIT_CATEGORY')),
          content: Text(t('STORE_FORM.CONFIRM_DEACTIVATE_CATEGORY')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('CANCEL')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('CONFIRM')),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final error = await ref
        .read(categoriesSettingsProvider.notifier)
        .deactivateCustom(category.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(categoriesSettingsProvider);
    final theme = Theme.of(context);
    final query = state.query;
    final selected = _filter(state.selected, query);
    final available = _filter(state.available, query);
    final custom = _filter(
      state.selected.where((StaffCategory c) => !c.isSystem).toList(),
      query,
    );
    final catalogCount =
        state.selected.where((StaffCategory c) => c.isSystem).length;
    final customCount =
        state.selected.where((StaffCategory c) => !c.isSystem).length;
    final hasSearch = query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context, fallback: Routes.staffStore),
        ),
        title: t('STORE_FORM.CATEGORIES_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            enabled: !state.busy,
            onPressed: () =>
                ref.read(categoriesSettingsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.busy ? null : _createCustom,
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_CATEGORY')),
      ),
      body: UnfocusOnTap(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '$catalogCount ${t('STORE_FORM.CATEGORY_MASTER_BADGE')} · '
                    '$customCount ${t('STORE_FORM.CATEGORY_CUSTOM_BADGE')} · '
                    '${state.selected.length + state.available.length} total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StaffSearchField(
                    controller: _search,
                    hintText: t('STORE_FORM.SEARCH_CATEGORIES'),
                    fillColor: Colors.white,
                    showLoading:
                        state.loading && _search.text.trim().isNotEmpty,
                    onChanged: (String value) => ref
                        .read(categoriesSettingsProvider.notifier)
                        .setQuery(value),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ),
            Expanded(
              child: state.loading && state.selected.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: <Widget>[
                        _CategorySection(
                          title: t('STORE_FORM.CATEGORIES_SELECTED'),
                          trailing: _selectedIds.isEmpty
                              ? null
                              : TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () async {
                                          final ids = _selectedIds.toList();
                                          _selectedIds.clear();
                                          setState(() {});
                                          await ref
                                              .read(
                                                categoriesSettingsProvider
                                                    .notifier,
                                              )
                                              .detach(ids);
                                        },
                                  child: Text(
                                    '${t('STORE_FORM.REMOVE_SELECTED_CATEGORIES')} (${_selectedIds.length})',
                                    style: TextStyle(color: AppTheme.error),
                                  ),
                                ),
                          emptyMessage: hasSearch
                              ? t('STORE_FORM.CATEGORIES_NO_RESULTS')
                              : t('STORE_FORM.CATEGORIES_NONE_SELECTED'),
                          isEmpty: selected.isEmpty,
                          children: selected
                              .map(
                                (StaffCategory category) => _CategoryRow(
                                  category: category,
                                  query: query,
                                  checked:
                                      _selectedIds.contains(category.id),
                                  busy: state.busy,
                                  onChecked: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(category.id);
                                      } else {
                                        _selectedIds.remove(category.id);
                                      }
                                    });
                                  },
                                  onOpen: () => _openCategory(category),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        _CategorySection(
                          title: t('STORE_FORM.CATEGORIES_AVAILABLE'),
                          trailing: _availableIds.isEmpty
                              ? null
                              : FilledButton(
                                  onPressed: state.busy
                                      ? null
                                      : () async {
                                          final ids = _availableIds.toList();
                                          _availableIds.clear();
                                          setState(() {});
                                          await ref
                                              .read(
                                                categoriesSettingsProvider
                                                    .notifier,
                                              )
                                              .attach(ids);
                                        },
                                  child: Text(
                                    '${t('STORE_FORM.ADD_SELECTED_CATEGORIES')} (${_availableIds.length})',
                                  ),
                                ),
                          emptyMessage: hasSearch
                              ? t('STORE_FORM.CATEGORIES_NO_RESULTS')
                              : t('STORE_FORM.CATEGORIES_NONE_AVAILABLE'),
                          isEmpty: available.isEmpty,
                          children: available
                              .map(
                                (StaffCategory category) => _CategoryRow(
                                  category: category,
                                  query: query,
                                  checked:
                                      _availableIds.contains(category.id),
                                  busy: state.busy,
                                  onChecked: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _availableIds.add(category.id);
                                      } else {
                                        _availableIds.remove(category.id);
                                      }
                                    });
                                  },
                                  onOpen: () => _openCategory(category),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        _CategorySection(
                          title: t('STORE_FORM.CATEGORIES_CUSTOM'),
                          emptyMessage: hasSearch
                              ? t('STORE_FORM.CATEGORIES_NO_RESULTS')
                              : t('STORE_FORM.CATEGORIES_NONE_CUSTOM'),
                          isEmpty: custom.isEmpty,
                          children: custom
                              .map(
                                (StaffCategory category) => _CustomCategoryRow(
                                  category: category,
                                  query: query,
                                  busy: state.busy,
                                  onOpen: () => _openCategory(category),
                                  onDeactivate: () =>
                                      _deactivateCustom(category),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.children,
    required this.emptyMessage,
    required this.isEmpty,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final String emptyMessage;
  final bool isEmpty;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.55),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.query,
    required this.checked,
    required this.busy,
    required this.onChecked,
    required this.onOpen,
  });

  final StaffCategory category;
  final String query;
  final bool checked;
  final bool busy;
  final ValueChanged<bool?> onChecked;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: <Widget>[
              Checkbox(
                value: checked,
                onChanged: busy ? null : onChecked,
                visualDensity: VisualDensity.compact,
              ),
              CategoryThumb(
                slug: category.slug,
                iconUrl: category.iconUrl,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HighlightedText(
                      category.name,
                      query: query,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.isSystem
                          ? t('STORE_FORM.CATEGORY_MASTER_BADGE')
                          : t('STORE_FORM.CATEGORY_CUSTOM_BADGE'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: category.isSystem
                    ? t('STORE_FORM.VIEW_CATEGORY')
                    : t('STORE_FORM.EDIT_CATEGORY'),
                onPressed: busy ? null : onOpen,
                icon: Icon(
                  category.isSystem
                      ? Icons.info_outline
                      : Icons.edit_outlined,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomCategoryRow extends StatelessWidget {
  const _CustomCategoryRow({
    required this.category,
    required this.query,
    required this.busy,
    required this.onOpen,
    required this.onDeactivate,
  });

  final StaffCategory category;
  final String query;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: <Widget>[
              CategoryThumb(
                slug: category.slug,
                iconUrl: category.iconUrl,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HighlightedText(
                      category.name,
                      query: query,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.isActive ? t('STORE_FORM.CATEGORY_ACTIVE') : t('STORE_FORM.CATEGORY_INACTIVE')} · /${category.slug}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: busy ? null : onDeactivate,
                child: Text(
                  t('DELETE'),
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
