import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/empty_list.dart';
import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_return.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'returns_controller.dart';

class ReturnsPage extends ConsumerStatefulWidget {
  const ReturnsPage({super.key});

  @override
  ConsumerState<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends ConsumerState<ReturnsPage> {
  final _search = TextEditingController();

  static const _statusFilters = <String>[
    'all',
    'pending',
    'approved',
    'rejected',
    'completed',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _statusChipLabel(String status) {
    if (status == 'all') return t('STORE_FORM.FILTER_ALL_RETURN_STATUS');
    final key = staffReturnStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(returnsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.RETURNS_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            onPressed: () =>
                ref.read(returnsListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.staffReturnNew),
        icon: const Icon(Icons.add),
        label: Text(t('STORE_FORM.ADD_RETURN')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t('STORE_FORM.RETURNS_SUBTITLE'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (String value) =>
                  ref.read(returnsListProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: t('STORE_FORM.SEARCH_RETURNS'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final value = _statusFilters[index];
                return FilterChip(
                  label: Text(_statusChipLabel(value)),
                  selected: state.status == value,
                  onSelected: (_) =>
                      ref.read(returnsListProvider.notifier).setStatus(value),
                );
              },
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

  Widget _body(ReturnsListState state, ThemeData theme) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return EmptyListBody(
        message: t('STORE_FORM.RETURNS_NO_RESULTS'),
        action: FilledButton(
          onPressed: () => context.push(Routes.staffReturnNew),
          child: Text(t('STORE_FORM.ADD_RETURN')),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final item = state.items[index];
        return _ReturnTile(
          item: item,
          onTap: () => context.push(Routes.staffReturn(item.id)),
        );
      },
    );
  }
}

class _ReturnTile extends StatelessWidget {
  const _ReturnTile({required this.item, required this.onTap});

  final StaffReturnListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusKey = staffReturnStatusLabelKey(item.status);
    final statusLabel = t(statusKey);
    final when = DateTime.tryParse(item.createdAt);

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
                    Text(
                      item.orderNumber == null
                          ? item.shortId
                          : '${t('STORE_FORM.RETURN_ORDER')} #${item.orderNumber}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.displayCustomer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${Format.rupee(item.refundAmount)} · '
                      '${statusLabel == statusKey ? item.status : statusLabel} · '
                      '${item.itemCount} ${t('STORE_FORM.RETURN_ITEMS').toLowerCase()}'
                      '${when == null ? '' : ' · ${Format.date(when)}'}',
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
