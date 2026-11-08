import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/catalog_product.dart';
import 'medicines_controller.dart';

Future<bool> showCatalogMasterSheet(BuildContext context) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const CatalogMasterSheet(),
  );
  return added == true;
}

class CatalogMasterSheet extends ConsumerStatefulWidget {
  const CatalogMasterSheet({super.key});

  @override
  ConsumerState<CatalogMasterSheet> createState() => _CatalogMasterSheetState();
}

class _CatalogMasterSheetState extends ConsumerState<CatalogMasterSheet> {
  final _search = TextEditingController();
  var _didAdd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicinesProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add(CatalogProduct product) async {
    final error =
        await ref.read(medicinesProvider.notifier).addToStore(product);
    if (!mounted) return;
    if (error != null) {
      final message =
          error == 'AUTH_SUPABASE_MISSING' ? t('AUTH_SUPABASE_MISSING') : error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    _didAdd = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('STORE_FORM.CATALOG_ADDED'))),
    );
  }

  Future<void> _createCustom() async {
    final created =
        await context.push<bool>(Routes.staffMedicinesCreate);
    if (!mounted || created != true) return;
    _didAdd = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(medicinesProvider);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController scrollController) {
          return Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.hairlineColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            t('STORE_FORM.CATALOG_DRAWER_TITLE'),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('STORE_FORM.CATALOG_DRAWER_DESC'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(_didAdd),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (String value) {
                    ref.read(medicinesProvider.notifier).setQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: t('STORE_FORM.CATALOG_SEARCH_PLACEHOLDER'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_search.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _search.clear();
                                  ref
                                      .read(medicinesProvider.notifier)
                                      .setQuery('');
                                },
                                icon: const Icon(Icons.close),
                              )),
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
              Expanded(child: _body(state, scrollController)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: OutlinedButton(
                    onPressed: _createCustom,
                    child: Text(t('STORE_FORM.CREATE_PRODUCT')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(MedicinesState state, ScrollController scrollController) {
    if (state.loading && state.catalog.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.catalog.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            state.query.trim().isEmpty
                ? t('STORE_FORM.CATALOG_ALL_ADDED')
                : t('STORE_FORM.CATALOG_NO_RESULTS'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            t('STORE_FORM.CATALOG_CUSTOM_HINT'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: state.catalog.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final product = state.catalog[index];
        final adding = state.addingIds.contains(product.id);
        return _MasterTile(
          product: product,
          adding: adding,
          onAdd: product.isInStore || adding ? null : () => _add(product),
        );
      },
    );
  }
}

class _MasterTile extends StatelessWidget {
  const _MasterTile({
    required this.product,
    required this.adding,
    required this.onAdd,
  });

  final CatalogProduct product;
  final bool adding;
  final VoidCallback? onAdd;

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
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (product.requiresPrescription)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            'Rx',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (product.subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      product.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (product.categoryName != null &&
                      product.categoryName!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      product.categoryName!,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (product.isInStore)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  t('STORE_FORM.CATALOG_ADDED'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: onAdd,
                child: adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('STORE_FORM.ADD_TO_STORE')),
              ),
          ],
        ),
      ),
    );
  }
}
