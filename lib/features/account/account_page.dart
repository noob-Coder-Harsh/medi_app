import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../core/i18n.dart';
import '../../core/language_switcher.dart';
import '../../core/link_opener.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../location/store_resolver.dart';
import 'customer_auth.dart';
import 'sign_in_stub.dart';

/// Account: guest Sign in (Firebase OTP) or signed-in phone. Legal + EN|हिं.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final shop = ref.watch(activeShopProvider);
    final session = ref.watch(customerSessionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('NAV.ACCOUNT'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          if (session.isSignedIn) ...<Widget>[
            Text(
              t('STOREFRONT.SIGNED_IN_AS'),
              key: const Key('account-signed-in'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              session.profile?.phone ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppTheme.touchTarget,
              child: OutlinedButton(
                key: const Key('account-sign-out'),
                onPressed: () => ref.read(customerSessionProvider.notifier).signOut(),
                child: Text(t('CHROME.SIGN_OUT')),
              ),
            ),
          ] else ...<Widget>[
            Text(
              t('STOREFRONT.ACCOUNT_GUEST'),
              key: const Key('account-guest'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppTheme.touchTarget,
              child: FilledButton(
                key: const Key('account-sign-in'),
                onPressed: () => showSignInStub(context),
                child: Text(t('STOREFRONT.SIGN_IN_TO_CHECKOUT')),
              ),
            ),
          ],
          if (shop != null && shop.slug.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _RowTile(
              tileKey: const Key('account-shop-info'),
              icon: Icons.storefront_outlined,
              label: t('STOREFRONT.STORE_INFO'),
              onTap: () => context.push(Routes.shopInfo(shop.slug)),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            t('LANGUAGE.LABEL'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const LanguageSwitcher(),
          const SizedBox(height: 16),
          Text(
            t('STOREFRONT.ACCOUNT_LEGAL'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          _RowTile(
            tileKey: const Key('account-privacy'),
            icon: Icons.privacy_tip_outlined,
            label: t('STOREFRONT.ACCOUNT_PRIVACY'),
            onTap: () => _open(ref, Uri.parse(Brand.urls.privacyPolicy)),
          ),
          _RowTile(
            tileKey: const Key('account-terms'),
            icon: Icons.description_outlined,
            label: t('STOREFRONT.ACCOUNT_TERMS'),
            onTap: () => _open(ref, Uri.parse(Brand.urls.termsOfService)),
          ),
          _RowTile(
            tileKey: const Key('account-contact'),
            icon: Icons.mail_outline,
            label: t('STOREFRONT.ACCOUNT_CONTACT'),
            onTap: () => _open(ref, Uri.parse(Brand.urls.contact)),
          ),
        ],
      ),
    );
  }

  Future<void> _open(WidgetRef ref, Uri uri) async {
    await ref.read(linkOpenerProvider).open(uri);
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      minVerticalPadding: 12,
      onTap: onTap,
    );
  }
}
