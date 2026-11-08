import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/theme.dart';
import '../../../data/rpc/pos_rpc.dart';
import '../../../data/supabase_client.dart';
import '../pos/pos_product.dart';

Future<PosProduct?> showPurchaseProductPicker(BuildContext context) {
  return showModalBottomSheet<PosProduct>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => const _PurchaseProductPickerSheet(),
  );
}

class _PurchaseProductPickerSheet extends ConsumerStatefulWidget {
  const _PurchaseProductPickerSheet();

  @override
  ConsumerState<_PurchaseProductPickerSheet> createState() =>
      _PurchaseProductPickerSheetState();
}

class _PurchaseProductPickerSheetState
    extends ConsumerState<_PurchaseProductPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<PosProduct> _products = const <PosProduct>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    if (!AppSupabase.isReady) {
      setState(() {
        _loading = false;
        _products = const <PosProduct>[];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rpc = ref.read(posRpcProvider);
      final products = query.trim().isEmpty
          ? await rpc.getPosHome()
          : await rpc.searchPosCatalog(query: query);
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.hairlineColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('STORE_FORM.PURCHASE_ADD_PRODUCT'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (String value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  unawaited(_load(value));
                });
              },
              decoration: InputDecoration(
                hintText: t('STORE_FORM.PURCHASE_SEARCH_PRODUCTS'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? Center(child: Text(t('STOREFRONT.SEARCH_EMPTY')))
                      : ListView.separated(
                          itemCount: _products.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final product = _products[index];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                [
                                  if (product.genericName != null)
                                    product.genericName!,
                                  'Stock ${product.stockCount.round()}',
                                ].join(' · '),
                              ),
                              onTap: () =>
                                  Navigator.of(context).pop(product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
