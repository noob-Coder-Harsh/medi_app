import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n.dart';
import 'theme.dart';

/// EN | हिं. 48dp targets.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Row(
      key: const Key('language-switcher'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LocaleHit(
          buttonKey: const Key('language-en'),
          label: t('LANGUAGE.EN', locale: locale),
          selected: locale == AppLocale.en,
          onTap: () => ref.read(localeProvider.notifier).set(AppLocale.en),
        ),
        Text(
          ' | ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        _LocaleHit(
          buttonKey: const Key('language-hi'),
          label: t('LANGUAGE.HI', locale: locale),
          selected: locale == AppLocale.hi,
          onTap: () => ref.read(localeProvider.notifier).set(AppLocale.hi),
        ),
      ],
    );
  }
}

class _LocaleHit extends StatelessWidget {
  const _LocaleHit({
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
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: AppTheme.borderRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppTheme.touchTarget,
          minHeight: AppTheme.touchTarget,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.primary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
