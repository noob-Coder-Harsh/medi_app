import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_default_avatar.dart';
import '../shell/staff_pop_scope.dart';
import 'profile_controller.dart';

/// Read-only staff profile (off bottom bar). Edit opens a separate form.
class StaffProfilePage extends ConsumerWidget {
  const StaffProfilePage({super.key});

  static const Color _mint = Color(0xFFE6F4F1);
  static const Color _label = Color(0xFF64748B);
  static const Color _value = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(profileSettingsProvider);
    final user = state.user;
    final theme = Theme.of(context);

    final name = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : (user?.email?.trim().isNotEmpty == true
            ? user!.email!.trim()
            : t('CHROME.STORE_OWNER'));
    final email = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : '—';
    final phone = user?.phone?.trim().isNotEmpty == true
        ? user!.phone!.trim()
        : '—';
    final roleLabel = _roleLabel(user?.role);
    final accessLabel = _accessLabel(user?.role);

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_PANEL_PROFILE'),
      ),
      body: user == null
          ? Center(child: Text(t('ERROR_UNAUTHORIZED')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                _ProfileHeader(
                  name: name,
                  email: email,
                  roleLabel: roleLabel,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  icon: Icons.person_outline,
                  title: t('PROFILE.PERSONAL_INFORMATION'),
                  children: <Widget>[
                    _DetailRow(
                      icon: Icons.person_outline,
                      label: t('AUTH_FULL_NAME_LABEL'),
                      value: name,
                    ),
                    _DetailRow(
                      icon: Icons.mail_outline,
                      label: t('AUTH_EMAIL_LABEL'),
                      value: email,
                    ),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: t('PROFILE.PHONE_NUMBER'),
                      value: phone,
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.storefront_outlined,
                  title: t('PROFILE.ACCOUNT_DETAILS'),
                  children: <Widget>[
                    _DetailRow(
                      icon: Icons.sell_outlined,
                      label: t('PROFILE.YOUR_ROLE'),
                      valueWidget: _RoleBadge(label: roleLabel),
                    ),
                    _DetailRow(
                      icon: Icons.storefront_outlined,
                      label: t('PROFILE.ACCESS'),
                      value: accessLabel,
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.touchTarget,
                  child: FilledButton.icon(
                    onPressed: () => context.push(Routes.staffProfileEdit),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: Text(t('CHROME.EDIT_PROFILE')),
                  ),
                ),
              ],
            ),
    );
  }

  static String _roleLabel(String? role) {
    final normalized = (role ?? 'owner').trim().toLowerCase();
    if (normalized == 'owner' || normalized == 'store_owner') {
      return t('CHROME.STORE_OWNER');
    }
    if (normalized.isEmpty) return t('CHROME.STORE_OWNER');
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  static String _accessLabel(String? role) {
    final normalized = (role ?? 'owner').trim().toLowerCase();
    if (normalized == 'owner' || normalized == 'store_owner') {
      return t('PROFILE.ACCESS_OWNER');
    }
    return t('PROFILE.ACCESS_STAFF');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.theme,
  });

  final String name;
  final String email;
  final String roleLabel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const StaffDefaultAvatar(radius: 40),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: StaffProfilePage._value,
                ),
              ),
              const SizedBox(height: 8),
              _RoleBadge(label: roleLabel, icon: Icons.storefront_outlined),
              if (email != '—') ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: StaffProfilePage._label,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: StaffProfilePage._mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: Brand.themeColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Brand.themeColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadius,
        side: const BorderSide(
          color: AppTheme.hairlineColor,
          width: AppTheme.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: StaffProfilePage._mint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: Brand.themeColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Brand.themeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20, color: StaffProfilePage._label),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: StaffProfilePage._label,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (valueWidget != null)
                      valueWidget!
                    else
                      Text(
                        value ?? '—',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: StaffProfilePage._value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}
