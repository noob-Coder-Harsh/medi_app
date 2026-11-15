import 'package:flutter/material.dart';

import 'brand.dart';
import 'theme.dart';

/// Empty list / table body: large icon + one short line + optional CTA.
class EmptyListBody extends StatelessWidget {
  const EmptyListBody({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTheme.emptyListMinHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 72,
                color: Brand.themeColor.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  fontSize: 14,
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
