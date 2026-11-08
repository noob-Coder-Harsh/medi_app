import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../auth/staff_session.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_default_avatar.dart';
import '../workspace_cache.dart';

/// Staff More tab: signed-in profile + store / legal / data cards.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  static const Color _mint = Color(0xFFE6F4F1);
  static const Color _label = Color(0xFF64748B);
  static const Color _ink = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final session = ref.watch(staffSessionProvider);
    final user = session.storeUser;
    final theme = Theme.of(context);
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : (user?.email ?? t('CHROME.STORE_OWNER'));
    final email = user?.email?.trim() ?? '';
    final phone = user?.phone?.trim() ?? '';
    final roleLabel = _roleLabel(user?.role);

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        title: t('NAV.MORE'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          _ProfileHeaderCard(
            name: name,
            email: email,
            phone: phone,
            roleLabel: roleLabel,
            theme: theme,
            onViewProfile: () => context.push(Routes.staffProfile),
          ),
          const SizedBox(height: 14),
          _SectionShell(
            icon: Icons.person_outline,
            title: t('MORE.ACCOUNT_SECTION'),
            child: Column(
              children: <Widget>[
                _AccountTile(
                  keyName: 'more-store-card',
                  icon: Icons.storefront_outlined,
                  title: t('MORE.STORE_DETAILS'),
                  subtitle: t('MORE.STORE_DETAILS_HINT'),
                  onTap: () => context.push(Routes.staffStore),
                ),
                const Divider(height: 1, indent: 62, endIndent: 14),
                _AccountTile(
                  keyName: 'more-privacy-card',
                  icon: Icons.verified_user_outlined,
                  title: t('MORE.PRIVACY'),
                  subtitle: t('MORE.PRIVACY_HINT'),
                  onTap: () => context.push(Routes.staffLegalPrivacy),
                ),
                const Divider(height: 1, indent: 62, endIndent: 14),
                _AccountTile(
                  keyName: 'more-legal-card',
                  icon: Icons.description_outlined,
                  title: t('MORE.LEGAL'),
                  subtitle: t('MORE.LEGAL_HINT'),
                  onTap: () => context.push(Routes.staffLegalTerms),
                ),
                const Divider(height: 1, indent: 62, endIndent: 14),
                _AccountTile(
                  keyName: 'more-data-card',
                  icon: Icons.mail_outline,
                  title: t('MORE.DATA'),
                  subtitle: t('MORE.DATA_HINT'),
                  onTap: () => context.push(Routes.staffLegalData),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionShell(
            icon: Icons.layers_outlined,
            title: t('MORE.WORKSPACE_SECTION'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: _WorkspaceGrid(
                items: <_WorkspaceItem>[
                  _WorkspaceItem(
                    keyName: 'more-purchases-card',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF059669),
                    title: t('STORE_FORM.PURCHASES_TITLE'),
                    onTap: () => context.push(Routes.staffPurchases),
                  ),
                  _WorkspaceItem(
                    keyName: 'more-payments-card',
                    icon: Icons.credit_card_outlined,
                    color: const Color(0xFF2563EB),
                    title: t('STORE_FORM.PAYMENTS_TITLE'),
                    onTap: () => context.push(Routes.staffPayments),
                  ),
                  _WorkspaceItem(
                    keyName: 'more-customers-card',
                    icon: Icons.people_outline,
                    color: const Color(0xFF7C3AED),
                    title: t('STORE_FORM.CUSTOMERS_TITLE'),
                    onTap: () => context.push(Routes.staffCustomers),
                  ),
                  _WorkspaceItem(
                    keyName: 'more-suppliers-card',
                    icon: Icons.storefront_outlined,
                    color: const Color(0xFFEA580C),
                    title: t('STORE_FORM.SUPPLIERS_TITLE'),
                    onTap: () => context.push(Routes.staffSuppliers),
                  ),
                  _WorkspaceItem(
                    keyName: 'more-returns-card',
                    icon: Icons.assignment_return_outlined,
                    color: const Color(0xFFDB2777),
                    title: t('STORE_FORM.RETURNS_TITLE'),
                    onTap: () => context.push(Routes.staffReturns),
                  ),
                  _WorkspaceItem(
                    keyName: 'more-categories-card',
                    icon: Icons.category_outlined,
                    color: const Color(0xFF0891B2),
                    title: t('STORE_FORM.CATEGORIES_TITLE'),
                    onTap: () => context.push(Routes.staffCategories),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _LanguageCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: AppTheme.touchTarget,
            child: OutlinedButton.icon(
              key: const Key('more-sign-out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                backgroundColor: const Color(0xFFFEE2E2),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadius,
                ),
              ),
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: Text(
                t('CHROME.SIGN_OUT'),
                style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _roleLabel(String? role) {
    final normalized = (role ?? 'owner').trim().toLowerCase();
    if (normalized == 'owner' ||
        normalized == 'store_owner' ||
        normalized.isEmpty) {
      return t('CHROME.STORE_OWNER');
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    clearStaffWorkspace(ref);
    await ref.read(staffSessionProvider.notifier).signOut();
    if (!context.mounted) return;
    context.go(Routes.staffLogin);
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.roleLabel,
    required this.theme,
    required this.onViewProfile,
  });

  final String name;
  final String email;
  final String phone;
  final String roleLabel;
  final ThemeData theme;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('more-profile-card'),
      color: MorePage._mint,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadius),
      child: InkWell(
        borderRadius: AppTheme.borderRadius,
        onTap: onViewProfile,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const StaffDefaultAvatar(radius: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: MorePage._ink,
                      ),
                    ),
                    if (email.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MorePage._label,
                        ),
                      ),
                    ],
                    if (phone.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: MorePage._label,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: MorePage._label,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: Brand.themeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            roleLabel,
                            style: const TextStyle(
                              color: Brand.themeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: MorePage._mint,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radius),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: Brand.themeColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Brand.themeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppTheme.radius),
            ),
            side: BorderSide(
              color: AppTheme.hairlineColor,
              width: AppTheme.hairline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key(keyName),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MorePage._mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Brand.themeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MorePage._ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MorePage._label,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MorePage._label),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceItem {
  const _WorkspaceItem({
    required this.keyName,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
}

class _WorkspaceGrid extends StatelessWidget {
  const _WorkspaceGrid({required this.items});

  final List<_WorkspaceItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const gap = 10.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (_WorkspaceItem item) => SizedBox(
                  width: tileWidth,
                  child: _WorkspaceTile(item: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({required this.item});

  final _WorkspaceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      child: InkWell(
        key: Key(item.keyName),
        borderRadius: BorderRadius.circular(12),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MorePage._ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: MorePage._mint,
        borderRadius: AppTheme.borderRadius,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.language, size: 18, color: Brand.themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t('LANGUAGE.LABEL'),
              style: const TextStyle(
                color: Brand.themeColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.hairlineColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _LangChip(
                  buttonKey: const Key('language-en'),
                  label: t('LANGUAGE.EN'),
                  selected: locale == AppLocale.en,
                  onTap: () =>
                      ref.read(localeProvider.notifier).set(AppLocale.en),
                ),
                _LangChip(
                  buttonKey: const Key('language-hi'),
                  label: t('LANGUAGE.SWITCH_TO_HINDI'),
                  selected: locale == AppLocale.hi,
                  onTap: () =>
                      ref.read(localeProvider.notifier).set(AppLocale.hi),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Brand.themeColor : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (selected) ...<Widget>[
                  const Icon(Icons.check, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : MorePage._label,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
