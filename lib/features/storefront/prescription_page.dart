import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/link_opener.dart';
import '../../core/medi_app_bar.dart';
import '../../core/theme.dart';
import '../../core/whatsapp.dart';
import '../../data/models/listing.dart';
import '../location/store_resolver.dart';
import 'store_home_controller.dart';

/// WhatsApp Rx job. Photo upload later; this screen only opens wa.me.
class PrescriptionPage extends ConsumerWidget {
  const PrescriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final store = _store(ref);

    return Scaffold(
      appBar: MediAppBar(titleText: t('STOREFRONT.PRESCRIPTION_TITLE')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t('STOREFRONT.PRESCRIPTION_BODY'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (store == null)
              Text(t('STOREFRONT.PRESCRIPTION_NO_SHOP'))
            else ...<Widget>[
              Text(
                store.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: AppTheme.touchTarget,
                child: FilledButton(
                  key: const Key('rx-send-whatsapp'),
                  onPressed: () => _send(context, ref, store),
                  child: Text(t('STOREFRONT.PRESCRIPTION_SEND')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PublicStore? _store(WidgetRef ref) {
    final active = ref.watch(activeShopProvider);
    final nearby = ref.watch(nearbyShopsProvider);
    if (active != null) {
      for (final item in nearby) {
        if (item.store.id == active.storeId || item.store.slug == active.slug) {
          return item.store;
        }
      }
      return ref.watch(storeHomeProvider(active.slug)).asData?.value.store;
    }
    return null;
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    PublicStore store,
  ) async {
    final uri = whatsAppUri(
      number: store.whatsappNumber,
      text: t('STOREFRONT.PRESCRIPTION_BODY'),
    );
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STOREFRONT.PRESCRIPTION_NO_WHATSAPP'))),
      );
      return;
    }
    final ok = await ref.read(linkOpenerProvider).open(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STOREFRONT.PRESCRIPTION_NO_WHATSAPP'))),
      );
    }
  }
}
