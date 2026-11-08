import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_store.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'categories_controller.dart';

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

  Future<void> _createCustom() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('STORE_FORM.CREATE_CUSTOM_CATEGORY')),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t('STORE_FORM.CATEGORY_NAME'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('CANCEL')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: Text(t('CONFIRM')),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final error =
        await ref.read(categoriesSettingsProvider.notifier).createCustom(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? t('STORE_FORM.CREATE_CUSTOM_CATEGORY'))),
    );
  }

  Future<void> _editCustom(StaffCategory category) async {
    final nameController = TextEditingController(text: category.name);
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('STORE_FORM.EDIT_CATEGORY')),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: t('STORE_FORM.CATEGORY_NAME'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('CANCEL')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: Text(t('CONFIRM')),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final error = await ref
        .read(categoriesSettingsProvider.notifier)
        .renameCustom(category.id, name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? t('STORE_FORM.EDIT_CATEGORY'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(categoriesSettingsProvider);
    final theme = Theme.of(context);
    final customSelected = state.selected
        .where((StaffCategory c) => !c.isSystem)
        .toList(growable: false);

    return Scaffold(
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
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (String value) =>
                  ref.read(categoriesSettingsProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_CATEGORIES'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: <Widget>[
                      Text(
                        t('STORE_FORM.CATEGORIES_SELECTED'),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (state.selected.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(t('STORE_FORM.CATEGORIES_NONE_SELECTED')),
                        )
                      else
                        ...state.selected.map((StaffCategory category) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _selectedIds.contains(category.id),
                            onChanged: state.busy
                                ? null
                                : (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(category.id);
                                      } else {
                                        _selectedIds.remove(category.id);
                                      }
                                    });
                                  },
                            title: Text(category.name),
                            subtitle: Text(
                              category.isSystem ? 'Catalog' : 'Custom',
                            ),
                            secondary: category.isSystem
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: state.busy
                                        ? null
                                        : () => _editCustom(category),
                                  ),
                          );
                        }),
                      if (_selectedIds.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: state.busy
                                ? null
                                : () async {
                                    final ids = _selectedIds.toList();
                                    _selectedIds.clear();
                                    setState(() {});
                                    await ref
                                        .read(
                                          categoriesSettingsProvider.notifier,
                                        )
                                        .detach(ids);
                                  },
                            child: Text(
                              t('STORE_FORM.REMOVE_SELECTED_CATEGORIES'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        t('STORE_FORM.CATEGORIES_AVAILABLE'),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (state.available.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            t('STORE_FORM.CATEGORIES_NONE_AVAILABLE'),
                          ),
                        )
                      else
                        ...state.available.map((StaffCategory category) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _availableIds.contains(category.id),
                            onChanged: state.busy
                                ? null
                                : (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _availableIds.add(category.id);
                                      } else {
                                        _availableIds.remove(category.id);
                                      }
                                    });
                                  },
                            title: Text(category.name),
                          );
                        }),
                      if (_availableIds.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton(
                            onPressed: state.busy
                                ? null
                                : () async {
                                    final ids = _availableIds.toList();
                                    _availableIds.clear();
                                    setState(() {});
                                    await ref
                                        .read(
                                          categoriesSettingsProvider.notifier,
                                        )
                                        .attach(ids);
                                  },
                            child: Text(
                              t('STORE_FORM.ADD_SELECTED_CATEGORIES'),
                            ),
                          ),
                        ),
                      if (customSelected.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          t('STORE_FORM.CATEGORIES_CUSTOM'),
                          style: theme.textTheme.titleMedium,
                        ),
                        ...customSelected.map(
                          (StaffCategory category) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(category.name),
                            trailing: TextButton(
                              onPressed: state.busy
                                  ? null
                                  : () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                              t('STORE_FORM.EDIT_CATEGORY'),
                                            ),
                                            content: Text(
                                              t(
                                                'STORE_FORM.CONFIRM_DEACTIVATE_CATEGORY',
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: Text(t('CANCEL')),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: Text(t('CONFIRM')),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (ok != true) return;
                                      await ref
                                          .read(
                                            categoriesSettingsProvider.notifier,
                                          )
                                          .deactivateCustom(category.id);
                                    },
                              child: Text(t('DELETE')),
                            ),
                          ),
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
