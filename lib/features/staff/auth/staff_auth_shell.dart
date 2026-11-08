import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/medi_app_bar.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';

/// Quiet staff auth chrome — no marketing hero.
class StaffAuthShell extends ConsumerWidget {
  const StaffAuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MediAppBar(
        titleText: Brand.appName,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t('AUTH_BACK_CUSTOMER'),
          onPressed: () => context.go(Routes.location),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: <Widget>[
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 28),
            child,
            if (footer != null) ...<Widget>[
              const SizedBox(height: 24),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class StaffAuthErrorBanner extends StatelessWidget {
  const StaffAuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadius,
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class StaffAuthFooterLink extends StatelessWidget {
  const StaffAuthFooterLink({
    super.key,
    required this.message,
    required this.linkLabel,
    required this.onTap,
  });

  final String message;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(message),
        TextButton(onPressed: onTap, child: Text(linkLabel)),
      ],
    );
  }
}
