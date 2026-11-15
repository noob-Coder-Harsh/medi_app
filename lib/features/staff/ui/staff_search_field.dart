import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/theme.dart';

/// Staff list search field: clear X when non-empty; optional search spinner
/// only when [showLoading] is true (caller should pass query nonempty + loading).
class StaffSearchField extends StatelessWidget {
  const StaffSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onCleared,
    this.showLoading = false,
    this.height,
    this.fillColor,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCleared;
  final bool showLoading;
  final double? height;
  final Color? fillColor;

  void _clear() {
    controller.clear();
    onChanged('');
    onCleared?.call();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final hasText = controller.text.isNotEmpty;
        Widget? suffix;
        if (showLoading) {
          suffix = const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        } else if (hasText) {
          suffix = IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.close, size: 18),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          );
        }

        final field = TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            filled: fillColor != null,
            fillColor: fillColor,
            hintText: hintText,
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.45),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppTheme.ink.withValues(alpha: 0.55),
            ),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.hairlineColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.hairlineColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Brand.themeColor),
            ),
          ),
        );

        if (height == null) return field;
        return SizedBox(height: height, child: field);
      },
    );
  }
}
