import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/inventory_batch.dart';
import '../../../data/models/listing.dart';
import '../../../data/models/staff_store.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';
import '../inventory/inventory_controller.dart';
import '../shell/staff_app_bar.dart';
import 'catalog_product_card.dart';

class MedicinesPage extends ConsumerStatefulWidget {
  const MedicinesPage({super.key});

  @override
  ConsumerState<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends ConsumerState<MedicinesPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created =
        await context.push<bool>(Routes.staffMedicinesCreate);
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('STORE_FORM.CATALOG_ADDED'))),
    );
    await ref.read(inventoryListProvider.notifier).refresh();
  }

  Future<void> _showFilters() async {
    final state = ref.read(inventoryListProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return _CatalogFilterSheet(
          stock: state.stock,
          status: state.status,
          onStock: (String stock) {
            ref.read(inventoryListProvider.notifier).setStock(stock);
            Navigator.pop(context);
          },
          onStatus: (String status) {
            ref.read(inventoryListProvider.notifier).setStatus(status);
            Navigator.pop(context);
          },
          onClear: () {
            final notifier = ref.read(inventoryListProvider.notifier);
            notifier.setStock('all');
            notifier.setStatus('all');
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _onAction(
    ListingCard item,
    CatalogProductAction action,
  ) async {
    switch (action) {
      case CatalogProductAction.edit:
        context.push(Routes.staffMedicinesProductEdit(item.id));
      case CatalogProductAction.addBatch:
        context.push(Routes.staffMedicinesProduct(item.id));
      case CatalogProductAction.toggleActive:
        await _toggleActive(item);
    }
  }

  Future<void> _toggleActive(ListingCard item) async {
    final token = ref.read(staffSessionProvider).session?.accessToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('AUTH_SUPABASE_MISSING'))),
      );
      return;
    }
    try {
      await ref.read(staffWriteApiProvider).updateStoreProduct(
            accessToken: token,
            storeProductId: item.id,
            input: UpdateStoreProductInput(isActive: !item.isActive),
          );
      if (!mounted) return;
      await ref.read(inventoryListProvider.notifier).refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(inventoryListProvider);
    final theme = Theme.of(context);
    final filtersActive = state.stock != 'all' || state.status != 'all';

    return Scaffold(
      appBar: StaffAppBar(
        title: t('STORE_FORM.MEDICINES_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.filter(
            active: filtersActive,
            onPressed: _showFilters,
          ),
          StaffAppBarAction.refresh(
            onPressed: () =>
                ref.read(inventoryListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_PRODUCT')),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (String value) {
                      ref
                          .read(inventoryListProvider.notifier)
                          .setQuery(value);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: t('STORE_FORM.CATALOG_SEARCH_PLACEHOLDER'),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: state.loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (_search.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _search.clear();
                                    ref
                                        .read(inventoryListProvider.notifier)
                                        .setQuery('');
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                )),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _CategoryDropdown(
                    categories: state.categories,
                    selectedId: state.categoryId,
                    onSelected: (String? id) {
                      ref
                          .read(inventoryListProvider.notifier)
                          .setCategoryId(id);
                    },
                  ),
                ),
              ],
            ),
          ),
          _StatsRow(
            stats: state.stats,
            loading: state.statsLoading && state.stats.total == 0,
            selectedStock: state.stock,
            onSelect: (String stock) {
              final notifier = ref.read(inventoryListProvider.notifier);
              notifier.setStock(state.stock == stock ? 'all' : stock);
            },
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
          Expanded(child: _body(state)),
        ],
      ),
    );
  }

  Widget _body(InventoryListState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                t('STORE_FORM.POS_NO_PRODUCTS'),
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _create,
                child: Text(t('STORE_FORM.ADD_PRODUCT')),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification note) {
        if (note.metrics.pixels > note.metrics.maxScrollExtent - 200) {
          ref.read(inventoryListProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[index];
          return CatalogProductCard(
            item: item,
            onTap: () => context.push(Routes.staffMedicinesProduct(item.id)),
            onAction: (CatalogProductAction action) => _onAction(item, action),
          );
        },
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<StaffCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = selectedId;
    final knownIds = categories.map((StaffCategory c) => c.id).toSet();
    final effectiveValue =
        value != null && knownIds.contains(value) ? value : null;

    return DropdownButtonFormField<String?>(
      // ignore: deprecated_member_use
      value: effectiveValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: Text(
        t('STORE_FORM.CATALOG_CHIP_ALL'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge,
      ),
      items: <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            t('STORE_FORM.CATALOG_CHIP_ALL'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final category in categories)
          DropdownMenuItem<String?>(
            value: category.id,
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onSelected,
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.loading,
    required this.selectedStock,
    required this.onSelect,
  });

  final InventoryStats stats;
  final bool loading;
  final String selectedStock;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tiles = <_StatTileData>[
      _StatTileData(
        label: t('STORE_FORM.CATALOG_STAT_TOTAL'),
        value: stats.total,
        stock: 'all',
        icon: Icons.inventory_2_outlined,
        tint: Brand.themeColor,
        background: const Color(0xFFCCFBF1),
      ),
      _StatTileData(
        label: t('STOREFRONT.IN_STOCK'),
        value: stats.inStock,
        stock: 'in_stock',
        icon: Icons.check_circle_outline,
        tint: const Color(0xFF2563EB),
        background: const Color(0xFFDBEAFE),
      ),
      _StatTileData(
        label: t('TODAY.LOW_STOCK'),
        value: stats.lowStock,
        stock: 'low_stock',
        icon: Icons.warning_amber_rounded,
        tint: AppTheme.amber,
        background: const Color(0xFFFEF3C7),
      ),
      _StatTileData(
        label: t('STOREFRONT.OUT_OF_STOCK'),
        value: stats.outOfStock,
        stock: 'out_of_stock',
        icon: Icons.cancel_outlined,
        tint: AppTheme.error,
        background: const Color(0xFFFEE2E2),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                data: tiles[i],
                loading: loading,
                selected: selectedStock == tiles[i].stock ||
                    (tiles[i].stock == 'all' && selectedStock == 'all'),
                onTap: () => onSelect(tiles[i].stock),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTileData {
  const _StatTileData({
    required this.label,
    required this.value,
    required this.stock,
    required this.icon,
    required this.tint,
    required this.background,
  });

  final String label;
  final int value;
  final String stock;
  final IconData icon;
  final Color tint;
  final Color background;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.data,
    required this.loading,
    required this.selected,
    required this.onTap,
  });

  final _StatTileData data;
  final bool loading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: data.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: BorderSide(
          color: selected ? data.tint : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(data.icon, size: 18, color: data.tint),
              const SizedBox(height: 8),
              Text(
                loading ? '—' : Format.stock(data.value),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.65),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogFilterSheet extends StatelessWidget {
  const _CatalogFilterSheet({
    required this.stock,
    required this.status,
    required this.onStock,
    required this.onStatus,
    required this.onClear,
  });

  final String stock;
  final String status;
  final ValueChanged<String> onStock;
  final ValueChanged<String> onStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('STORE_FORM.CATALOG_FILTERS_TITLE'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _filterChip(
                  label: t('STOREFRONT.IN_STOCK'),
                  selected: stock == 'in_stock',
                  onTap: () => onStock('in_stock'),
                ),
                _filterChip(
                  label: t('TODAY.LOW_STOCK'),
                  selected: stock == 'low_stock',
                  onTap: () => onStock('low_stock'),
                ),
                _filterChip(
                  label: t('STOREFRONT.OUT_OF_STOCK'),
                  selected: stock == 'out_of_stock',
                  onTap: () => onStock('out_of_stock'),
                ),
                _filterChip(
                  label: t('STORE_FORM.SUPPLIER_STATUS_INACTIVE'),
                  selected: status == 'inactive',
                  onTap: () => onStatus('inactive'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onClear,
              child: Text(t('STORE_FORM.CATALOG_FILTERS_CLEAR')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
