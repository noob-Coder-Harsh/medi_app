import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/link_opener.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/whatsapp.dart';
import '../../../data/models/staff_store.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'store_settings_controller.dart';

/// Read-only store details (off bottom bar). Edit opens a separate form.
class StoreDetailPage extends ConsumerWidget {
  const StoreDetailPage({super.key});

  static const Color _mint = Color(0xFFE6F4F1);
  static const Color _label = Color(0xFF64748B);
  static const Color _value = Color(0xFF0F172A);
  static const String _defaultStoreAsset = 'assets/images/default_store.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final state = ref.watch(storeSettingsProvider);
    final theme = Theme.of(context);
    final store = state.store;

    return Scaffold(
      backgroundColor: Brand.themeBackground,
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(context),
        ),
        title: t('STORE_FORM.MY_STORE_TITLE'),
        actions: <Widget>[
          StaffAppBarAction.refresh(
            enabled: !state.busy && !state.loading,
            onPressed: () =>
                ref.read(storeSettingsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.loading && store == null
          ? const Center(child: CircularProgressIndicator())
          : store == null
              ? Center(child: Text(state.error ?? t('ERROR_GENERIC')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: <Widget>[
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    _StoreHeader(store: store, theme: theme),
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.person_outline,
                      title: t('STORE_FORM.SUB_CONTACT_DETAILS'),
                      children: <Widget>[
                        _ContactPhoneRow(store: store),
                        _IconDetailRow(
                          icon: Icons.mail_outline,
                          value: _dash(store.email),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      icon: Icons.location_on_outlined,
                      title: t('STORE_FORM.ADDRESS'),
                      children: <Widget>[
                        _AddressRow(store: store),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      icon: Icons.access_time,
                      title: t('STORE_FORM.SUB_STORE_TIMINGS'),
                      children: <Widget>[
                        _TimingsRow(store: store),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      icon: Icons.description_outlined,
                      title: t('STORE_FORM.REGULATORY_DETAILS'),
                      children: <Widget>[
                        _KeyValueRow(
                          icon: Icons.description_outlined,
                          label: t('STORE_FORM.GST_UDYAM_NUMBER'),
                          value: _dash(store.gstNumber),
                        ),
                        _KeyValueRow(
                          icon: Icons.workspace_premium_outlined,
                          label: t('STORE_FORM.DRUG_LICENSE_NUMBER'),
                          value: _dash(store.drugLicenseNumber),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      icon: Icons.tune_outlined,
                      title: t('STORE_FORM.ORDER_SETTINGS'),
                      children: <Widget>[
                        _ToggleRow(
                          icon: Icons.shopping_cart_outlined,
                          title: t('STORE_FORM.ENABLE_ONLINE_ORDERS'),
                          subtitle: t('STORE_FORM.ENABLE_ONLINE_ORDERS_DESC'),
                          value: store.acceptsOnlineOrders,
                        ),
                        _ToggleRow(
                          icon: Icons.storefront_outlined,
                          title: t('STORE_FORM.STORE_OPEN'),
                          value: store.isOpen,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.touchTarget,
                      child: FilledButton.icon(
                        onPressed: () => context.push(Routes.staffStoreEdit),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: Text(t('MORE.EDIT_STORE')),
                      ),
                    ),
                  ],
                ),
    );
  }

  static String _dash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store, required this.theme});

  final StaffStore store;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StoreAvatar(logoUrl: store.logoUrl),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                store.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: StoreDetailPage._value,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.storefront_outlined,
                    size: 14,
                    color: StoreDetailPage._label,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t('STORE_FORM.PHARMACY_CATEGORY'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: StoreDetailPage._label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _StatusPill(
                    filled: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: store.isOpen
                                ? Brand.themeColor
                                : StoreDetailPage._label,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          store.isOpen
                              ? t('TODAY.OPEN')
                              : t('TODAY.CLOSED'),
                          style: TextStyle(
                            color: store.isOpen
                                ? Brand.themeColor
                                : StoreDetailPage._label,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    filled: false,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 14,
                          color: store.acceptsOnlineOrders
                              ? Brand.themeColor
                              : StoreDetailPage._label,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          store.acceptsOnlineOrders
                              ? t('STORE_FORM.TAKING_ORDERS')
                              : t('STORE_FORM.NOT_TAKING_ORDERS'),
                          style: TextStyle(
                            color: store.acceptsOnlineOrders
                                ? StoreDetailPage._value
                                : StoreDetailPage._label,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  const _StoreAvatar({this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url.isEmpty
            ? Image.asset(
                StoreDetailPage._defaultStoreAsset,
                fit: BoxFit.cover,
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (BuildContext context, String _, Object __) {
                  return Image.asset(
                    StoreDetailPage._defaultStoreAsset,
                    fit: BoxFit.cover,
                  );
                },
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.child, required this.filled});

  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? StoreDetailPage._mint : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: filled
            ? null
            : Border.all(color: AppTheme.hairlineColor, width: AppTheme.hairline),
      ),
      child: child,
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
            color: StoreDetailPage._mint,
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

class _ContactPhoneRow extends ConsumerWidget {
  const _ContactPhoneRow({required this.store});

  final StaffStore store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phones = <String>[
      if ((store.phone?.trim().isNotEmpty ?? false)) store.phone!.trim(),
      if ((store.whatsappNumber?.trim().isNotEmpty ?? false) &&
          store.whatsappNumber!.trim() != store.phone?.trim())
        store.whatsappNumber!.trim(),
    ];
    final display = phones.isEmpty ? '—' : phones.join(', ');
    final callNumber = store.phone?.trim().isNotEmpty == true
        ? store.phone!.trim()
        : store.whatsappNumber?.trim();
    final waNumber = store.whatsappNumber?.trim().isNotEmpty == true
        ? store.whatsappNumber!.trim()
        : store.phone?.trim();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.phone_outlined,
                size: 20,
                color: StoreDetailPage._label,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  display,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: StoreDetailPage._value,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.phone_outlined,
                background: Colors.white,
                foreground: Brand.themeColor,
                bordered: true,
                onTap: callNumber == null || callNumber.isEmpty
                    ? null
                    : () {
                        final digits = callNumber.replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return;
                        ref
                            .read(linkOpenerProvider)
                            .open(Uri.parse('tel:$digits'));
                      },
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.chat_outlined,
                background: StoreDetailPage._mint,
                foreground: Brand.themeColor,
                onTap: waNumber == null || waNumber.isEmpty
                    ? null
                    : () {
                        final uri = whatsAppUri(number: waNumber);
                        if (uri == null) return;
                        ref.read(linkOpenerProvider).open(uri);
                      },
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Divider(height: 1),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.background,
    required this.foreground,
    this.bordered = false,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final bool bordered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: bordered
                ? Border.all(
                    color: AppTheme.hairlineColor,
                    width: AppTheme.hairline,
                  )
                : null,
          ),
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  const _IconDetailRow({
    required this.icon,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: StoreDetailPage._label),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: StoreDetailPage._value,
                        fontWeight: FontWeight.w600,
                      ),
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

class _AddressRow extends ConsumerWidget {
  const _AddressRow({required this.store});

  final StaffStore store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = <String?>[
      store.address,
      store.city,
      store.state,
      store.pincode,
    ]
        .map((String? p) => p?.trim() ?? '')
        .where((String p) => p.isNotEmpty)
        .join(', ');
    final hasCoords = store.latitude != null && store.longitude != null;
    final canOpenMap = hasCoords || address.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: StoreDetailPage._label,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              address.isEmpty ? '—' : address,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: StoreDetailPage._value,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: !canOpenMap
                ? null
                : () {
                    final Uri uri;
                    if (hasCoords) {
                      uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}',
                      );
                    } else {
                      uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                      );
                    }
                    ref.read(linkOpenerProvider).open(uri);
                  },
            icon: const Icon(Icons.location_on_outlined, size: 16),
            label: Text(t('STORE_FORM.VIEW_ON_MAP')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Brand.themeColor,
              side: const BorderSide(color: Brand.themeColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingsRow extends StatelessWidget {
  const _TimingsRow({required this.store});

  final StaffStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = _hoursLabel(store);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: _TimingColumn(
                icon: Icons.calendar_today_outlined,
                label: t('STORE_FORM.OPEN_DAILY'),
                child: Text(
                  hours,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: StoreDetailPage._value,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 24, thickness: 1),
            Expanded(
              child: _TimingColumn(
                icon: Icons.calendar_today_outlined,
                label: t('STORE_FORM.STORE_STATUS'),
                child: _StatusPill(
                  filled: true,
                  child: Text(
                    store.isOpen ? t('TODAY.OPEN') : t('TODAY.CLOSED'),
                    style: TextStyle(
                      color: store.isOpen
                          ? Brand.themeColor
                          : StoreDetailPage._label,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hoursLabel(StaffStore store) {
    final opens = _formatClock(store.openingTime);
    final closes = _formatClock(store.closingTime);
    if (opens == null && closes == null) return '—';
    if (opens == null) return closes!;
    if (closes == null) return opens;
    return '$opens – $closes';
  }

  static String? _formatClock(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return value;
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = match.group(2)!;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hh = hour.toString().padLeft(2, '0');
    return '$hh:$minute $period';
  }
}

class _TimingColumn extends StatelessWidget {
  const _TimingColumn({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: StoreDetailPage._label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StoreDetailPage._label,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: StoreDetailPage._label),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: StoreDetailPage._label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: StoreDetailPage._value,
                    fontWeight: FontWeight.w700,
                  ),
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: StoreDetailPage._label),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: StoreDetailPage._value,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: StoreDetailPage._label,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IgnorePointer(
                child: Switch.adaptive(
                  value: value,
                  onChanged: (_) {},
                  activeThumbColor: Colors.white,
                  activeTrackColor: Brand.themeColor,
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
