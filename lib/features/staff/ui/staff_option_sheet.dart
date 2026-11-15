import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/theme.dart';

class StaffSelectOption {
  const StaffSelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _OptionVisual {
  const _OptionVisual({
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
}

_OptionVisual _visualForOption(String label, int index) {
  final key = label.toLowerCase();
  if (key.contains('tablet') || key.contains('capsule')) {
    return const _OptionVisual(
      icon: Icons.medication_outlined,
      fg: Color(0xFF0F766E),
      bg: Color(0xFFCCFBF1),
    );
  }
  if (key.contains('syrup') || key.contains('liquid') || key.contains('bottle')) {
    return const _OptionVisual(
      icon: Icons.science_outlined,
      fg: Color(0xFF2563EB),
      bg: Color(0xFFDBEAFE),
    );
  }
  if (key.contains('drop')) {
    return const _OptionVisual(
      icon: Icons.water_drop_outlined,
      fg: Color(0xFFB45309),
      bg: Color(0xFFFFEDD5),
    );
  }
  if (key.contains('inject') || key.contains('vial') || key.contains('ampoule')) {
    return const _OptionVisual(
      icon: Icons.vaccines_outlined,
      fg: Color(0xFF0F766E),
      bg: Color(0xFFCCFBF1),
    );
  }
  if (key.contains('cream') || key.contains('ointment') || key.contains('gel')) {
    return const _OptionVisual(
      icon: Icons.spa_outlined,
      fg: Color(0xFF7C3AED),
      bg: Color(0xFFEDE9FE),
    );
  }
  if (key.contains('inhal') || key.contains('device')) {
    return const _OptionVisual(
      icon: Icons.air,
      fg: Color(0xFF059669),
      bg: Color(0xFFD1FAE5),
    );
  }
  if (key.contains('surg') || key.contains('dress') || key.contains('bandage')) {
    return const _OptionVisual(
      icon: Icons.medical_services_outlined,
      fg: Color(0xFFEA580C),
      bg: Color(0xFFFFEDD5),
    );
  }
  if (key.contains('baby') || key.contains('infant') || key.contains('paed')) {
    return const _OptionVisual(
      icon: Icons.child_care_outlined,
      fg: Color(0xFFBE123C),
      bg: Color(0xFFFFE4E6),
    );
  }
  if (key.contains('strip') || key.contains('pack') || key.contains('box')) {
    return const _OptionVisual(
      icon: Icons.layers_outlined,
      fg: Color(0xFF0F766E),
      bg: Color(0xFFCCFBF1),
    );
  }
  const palette = <_OptionVisual>[
    _OptionVisual(
      icon: Icons.category_outlined,
      fg: Color(0xFF0F766E),
      bg: Color(0xFFCCFBF1),
    ),
    _OptionVisual(
      icon: Icons.inventory_2_outlined,
      fg: Color(0xFF2563EB),
      bg: Color(0xFFDBEAFE),
    ),
    _OptionVisual(
      icon: Icons.local_pharmacy_outlined,
      fg: Color(0xFF7C3AED),
      bg: Color(0xFFEDE9FE),
    ),
    _OptionVisual(
      icon: Icons.healing_outlined,
      fg: Color(0xFFEA580C),
      bg: Color(0xFFFFEDD5),
    ),
  ];
  return palette[index % palette.length];
}

Future<String?> showStaffOptionSheet({
  required BuildContext context,
  required String title,
  required List<StaffSelectOption> options,
  String? selected,
  String? subtitle,
  String? searchHint,
  IconData? headerIcon,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return _OptionPickerSheet(
        title: title,
        subtitle: subtitle,
        searchHint: searchHint,
        headerIcon: headerIcon ?? Icons.grid_view_rounded,
        options: options,
        selected: selected,
      );
    },
  );
}

class _OptionPickerSheet extends StatefulWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.headerIcon,
    this.subtitle,
    this.searchHint,
    this.selected,
  });

  final String title;
  final String? subtitle;
  final String? searchHint;
  final IconData headerIcon;
  final List<StaffSelectOption> options;
  final String? selected;

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<StaffSelectOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final filtered = _filtered;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFF0FDFA),
                Colors.white,
                Colors.white,
              ],
              stops: <double>[0, 0.18, 1],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Brand.themeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.headerIcon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: AppTheme.ink.withValues(alpha: 0.65),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (String value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.searchHint ?? t('STORE_FORM.SEARCH'),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.ink.withValues(alpha: 0.4),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        color: Brand.themeColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          t('STORE_FORM.OPTION_PICK_EMPTY'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.ink.withValues(alpha: 0.55),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final option = filtered[index];
                          final originalIndex = widget.options.indexWhere(
                            (o) => o.value == option.value,
                          );
                          final visual = _visualForOption(
                            option.label,
                            originalIndex < 0 ? index : originalIndex,
                          );
                          final isSelected = option.value == widget.selected;
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  Navigator.pop(context, option.value),
                              child: Ink(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? Brand.themeColor
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.6 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: visual.bg,
                                          borderRadius:
                                              BorderRadius.circular(11),
                                        ),
                                        child: Icon(
                                          visual.icon,
                                          color: visual.fg,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option.label,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: Brand.themeColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable form field that opens [showStaffOptionSheet].
class StaffSheetSelectField extends FormField<String> {
  StaffSheetSelectField({
    super.key,
    required String? value,
    required List<StaffSelectOption> options,
    required String title,
    required ValueChanged<String> onChanged,
    required InputDecoration decoration,
    String? subtitle,
    String? searchHint,
    IconData? headerIcon,
    super.validator,
    bool enabled = true,
  }) : super(
          initialValue: value,
          builder: (FormFieldState<String> field) {
            final current = value ?? field.value;
            String? label;
            for (final option in options) {
              if (option.value == current) {
                label = option.label;
                break;
              }
            }
            final hintColor = AppTheme.ink.withValues(alpha: 0.38);
            return InkWell(
              borderRadius: AppTheme.borderRadius,
              onTap: !enabled || options.isEmpty
                  ? null
                  : () async {
                      final picked = await showStaffOptionSheet(
                        context: field.context,
                        title: title,
                        options: options,
                        selected: current,
                        subtitle: subtitle,
                        searchHint: searchHint,
                        headerIcon: headerIcon,
                      );
                      if (picked == null) return;
                      field.didChange(picked);
                      onChanged(picked);
                    },
              child: InputDecorator(
                isEmpty: label == null || label.isEmpty,
                decoration: decoration.copyWith(
                  errorText: field.errorText,
                  suffixIcon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled
                        ? AppTheme.ink.withValues(alpha: 0.45)
                        : AppTheme.ink.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  label ?? decoration.hintText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(field.context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        color: label == null ? hintColor : null,
                      ),
                ),
              ),
            );
          },
        );
}
