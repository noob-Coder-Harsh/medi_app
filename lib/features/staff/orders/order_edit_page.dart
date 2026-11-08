import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/models/staff_order.dart';
import '../shell/staff_app_bar.dart';
import '../shell/staff_pop_scope.dart';
import 'orders_controller.dart';

/// Full-screen order edit (status + notes) outside bottom bar.
class StaffOrderEditPage extends ConsumerStatefulWidget {
  const StaffOrderEditPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<StaffOrderEditPage> createState() => _StaffOrderEditPageState();
}

class _StaffOrderEditPageState extends ConsumerState<StaffOrderEditPage> {
  final _notes = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  String _labelStatus(String status) {
    final key = staffOrderStatusLabelKey(status);
    final label = t(key);
    return label == key ? status : label;
  }

  Future<void> _save() async {
    final status = _selectedStatus;
    if (status == null || status.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STORE_FORM.ORDER_STATUS'))),
      );
      return;
    }
    final error = await ref
        .read(staffOrderDetailProvider(widget.orderId).notifier)
        .changeStatus(
          status,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? _labelStatus(status)),
      ),
    );
    if (error == null) {
      staffBack(context, fallback: Routes.staffOrder(widget.orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(staffOrderDetailProvider(widget.orderId));
    final detail = state.detail;
    final theme = Theme.of(context);

    if (detail != null &&
        _selectedStatus == null &&
        detail.nextStatuses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedStatus != null) return;
        setState(() => _selectedStatus = detail.nextStatuses.first);
      });
    }

    return Scaffold(
      appBar: StaffAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => staffBack(
            context,
            fallback: Routes.staffOrder(widget.orderId),
          ),
        ),
        title: t('MORE.EDIT_ORDER'),
      ),
      body: state.loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? Center(child: Text(state.error ?? t('ERROR_GENERIC')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: <Widget>[
                    Text(
                      '#${detail.orderNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('STORE_FORM.ORDER_STATUS')}: ${_labelStatus(detail.status)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    if (state.error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      t('STORE_FORM.ORDER_STATUS'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (detail.nextStatuses.isEmpty)
                      Text(
                        t('STORE_FORM.ORDER_VIEW'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.65),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _selectedStatus != null &&
                                detail.nextStatuses.contains(_selectedStatus)
                            ? _selectedStatus
                            : detail.nextStatuses.first,
                        decoration: InputDecoration(
                          labelText: t('STORE_FORM.ORDER_STATUS'),
                        ),
                        items: detail.nextStatuses
                            .map(
                              (String status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(_labelStatus(status)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: state.busy
                            ? null
                            : (String? value) {
                                if (value == null) return;
                                setState(() => _selectedStatus = value);
                              },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      minLines: 3,
                      maxLines: 5,
                      enabled: !state.busy && detail.nextStatuses.isNotEmpty,
                      decoration: InputDecoration(
                        labelText: t('STORE_FORM.ORDER_NOTES'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.touchTarget,
                      child: FilledButton(
                        onPressed: state.busy || detail.nextStatuses.isEmpty
                            ? null
                            : _save,
                        child: state.busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t('WRITE_LOADING_SAVE')),
                      ),
                    ),
                  ],
                ),
    );
  }
}
