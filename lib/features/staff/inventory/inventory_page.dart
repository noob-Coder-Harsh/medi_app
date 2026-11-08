import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/listing.dart';
import '../shell/staff_app_bar.dart';
import 'inventory_controller.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(inventoryListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffToday),
        ),
        title: t('STORE_FORM.PRODUCTS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () =>
                ref.read(inventoryListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (String value) {
                ref.read(inventoryListProvider.notifier).setQuery(value);
              },
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_PRODUCTS'),
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
                                  .read(inventoryListProvider.notifier)
                                  .setQuery('');
                            },
                            icon: const Icon(Icons.close),
                          )),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: <Widget>[
                _FilterChip(
                  label: t('STOREFRONT.IN_STOCK'),
                  selected: state.stock == 'in_stock',
                  onTap: () => ref
                      .read(inventoryListProvider.notifier)
                      .setStock(state.stock == 'in_stock' ? 'all' : 'in_stock'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: t('STOREFRONT.OUT_OF_STOCK'),
                  selected: state.stock == 'out_of_stock',
                  onTap: () => ref.read(inventoryListProvider.notifier).setStock(
                        state.stock == 'out_of_stock' ? 'all' : 'out_of_stock',
                      ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low',
                  selected: state.stock == 'low_stock',
                  onTap: () => ref
                      .read(inventoryListProvider.notifier)
                      .setStock(state.stock == 'low_stock' ? 'all' : 'low_stock'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactive',
                  selected: state.status == 'inactive',
                  onTap: () => ref.read(inventoryListProvider.notifier).setStatus(
                        state.status == 'inactive' ? 'all' : 'inactive',
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t('STORE_FORM.INVENTORY_TAP_ROW_HINT'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
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
          child: Text(
            t('STORE_FORM.POS_NO_PRODUCTS'),
            textAlign: TextAlign.center,
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[index];
          return _InventoryTile(
            item: item,
            onTap: () => context.go(Routes.staffInventoryProduct(item.id)),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.onTap});

  final ListingCard item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = item.sellingPrice;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(color: AppTheme.hairlineColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                            item.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (item.requiresPrescription)
                          Text(
                            'Rx',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (item.categoryName != null) item.categoryName!,
                        if (item.strength != null && item.strength!.isNotEmpty)
                          item.strength!,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t('STORE_FORM.STOCK_COUNT')}: ${Format.stock(item.availableQuantity)}'
                      '${price == null ? '' : '  ·  ${Format.rupee(price)}'}',
                      style: theme.textTheme.labelLarge,
                    ),
                    if (!item.isActive)
                      Text(
                        'Inactive',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
