import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/empty_list.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/purchase.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'purchases_controller.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(purchasesListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.PURCHASES_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () =>
                ref.read(purchasesListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.staffPurchaseNew),
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_PURCHASE')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (String value) {
                ref.read(purchasesListProvider.notifier).setQuery(value);
              },
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_PURCHASES'),
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
                    : null,
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
          Expanded(child: _body(state, theme)),
        ],
      ),
    );
  }

  Widget _body(PurchasesListState state, ThemeData theme) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return EmptyListBody(
        message: t('STORE_FORM.PURCHASES_NO_RESULTS'),
        action: FilledButton(
          onPressed: () => context.push(Routes.staffPurchaseNew),
          child: Text(t('STORE_FORM.ADD_PURCHASE')),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final item = state.items[index];
        return _PurchaseTile(
          item: item,
          onTap: () => context.push(Routes.staffPurchase(item.id)),
        );
      },
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.item, required this.onTap});

  final PurchaseListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = switch (item.status) {
      'completed' => t('STORE_FORM.PURCHASE_STATUS_COMPLETED'),
      'cancelled' => t('STORE_FORM.PURCHASE_STATUS_CANCELLED'),
      _ => t('STORE_FORM.PURCHASE_STATUS_DRAFT'),
    };
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
                    Text(item.invoiceNumber, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${item.supplierName} · ${item.invoiceDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${Format.rupee(item.grandTotal)} · $statusLabel · ${item.itemCount} items',
                      style: theme.textTheme.labelLarge,
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
