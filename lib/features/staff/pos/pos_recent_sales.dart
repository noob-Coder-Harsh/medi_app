import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/i18n.dart';
import '../../../data/models/pos_checkout.dart';
import '../../../data/staff_api_client.dart';
import '../auth/staff_session.dart';

class PosRecentSalesController extends AsyncNotifier<List<PosRecentSale>> {
  @override
  Future<List<PosRecentSale>> build() => _load();

  Future<List<PosRecentSale>> _load() async {
    final session = ref.read(staffSessionProvider).session;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) return const <PosRecentSale>[];
    try {
      return await ref.read(staffWriteApiProvider).recentSales(accessToken: token);
    } catch (_) {
      return const <PosRecentSale>[];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void prepend(PosRecentSale sale) {
    final current = state.asData?.value ?? const <PosRecentSale>[];
    state = AsyncData(<PosRecentSale>[
      sale,
      ...current.where((PosRecentSale s) => s.id != sale.id),
    ]);
  }
}

final posRecentSalesProvider =
    AsyncNotifierProvider<PosRecentSalesController, List<PosRecentSale>>(
      PosRecentSalesController.new,
    );

class PosRecentSalesButton extends ConsumerWidget {
  const PosRecentSalesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final async = ref.watch(posRecentSalesProvider);
    final sales = async.asData?.value ?? const <PosRecentSale>[];

    return IconButton(
      tooltip: t('STORE_FORM.POS_RECENT_SALES'),
      onPressed: () => _open(context, sales),
      icon: Badge(
        isLabelVisible: sales.isNotEmpty,
        label: Text('${sales.length.clamp(0, 9)}'),
        child: const Icon(Icons.history),
      ),
    );
  }

  Future<void> _open(BuildContext context, List<PosRecentSale> sales) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(t('STORE_FORM.POS_RECENT_SALES')),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(sheet),
                  icon: const Icon(Icons.close),
                ),
              ),
              const Divider(height: 1),
              if (sales.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(t('STORE_FORM.POS_NO_RECENT_SALES')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sales.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final sale = sales[index];
                      return ListTile(
                        title: Text('#${sale.orderNumber} · ${sale.customerPhone}'),
                        subtitle: Text(
                          sale.placedAt.isEmpty
                              ? Format.rupee(sale.totalAmount)
                              : '${Format.rupee(sale.totalAmount)} · ${sale.placedAt}',
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
