import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/i18n.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../data/supabase_client.dart';
import '../auth/staff_auth_shell.dart';
import '../auth/staff_session.dart';
import 'create_store_input.dart';
import 'store_onboarding_service.dart';

class StaffOnboardingPage extends ConsumerStatefulWidget {
  const StaffOnboardingPage({super.key});

  @override
  ConsumerState<StaffOnboardingPage> createState() =>
      _StaffOnboardingPageState();
}

class _StaffOnboardingPageState extends ConsumerState<StaffOnboardingPage> {
  static const _headerAsset = 'assets/images/big_header.png';
  static const _headerMint = Color(0xFFE8F6F4);
  static const _fieldBorder = Color(0xFF9AA8A3);
  static const _headerAspect = 2.35;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  var _busy = false;
  var _trackStock = true;
  String? _error;
  var _resumeChecked = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final session = ref.watch(staffSessionProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final topInset = MediaQuery.paddingOf(context).top;
    final compact = width < 390;
    final medium = width >= 390 && width < 430;
    final titleSize = compact ? 22.0 : (medium ? 24.0 : 26.0);
    final pagePad = compact ? 16.0 : 20.0;
    final artRightPad = compact ? 96.0 : (medium ? 112.0 : 132.0);

    if (!_resumeChecked && session.ready) {
      _resumeChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !AppSupabase.isReady) return;
        if (!session.isSignedIn) {
          context.go(Routes.staffLogin);
          return;
        }
        if (session.hasStore) {
          context.go(Routes.staffToday);
        }
      });
    }

    final bannerHeight = (width / _headerAspect).clamp(130.0, 210.0);
    final headerHeight = topInset + 12 + bannerHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _headerMint,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Form-page bg: crop/align to bottom so pharmacy art stays visible.
            Positioned(
              top: (headerHeight - 28).clamp(0.0, double.infinity),
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                AppTheme.pageBackgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
              ),
            ),
            ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                SizedBox(
                  height: headerHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: <Widget>[
                      const Positioned.fill(
                        child: ColoredBox(color: _headerMint),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: bannerHeight,
                        child: Image.asset(
                          _headerAsset,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.centerRight,
                          width: width,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      // Soft fade so the header blends into the form (no sharp cut).
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 88,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.45),
                                  Colors.white.withValues(alpha: 0.85),
                                  Colors.white,
                                ],
                                stops: const <double>[0, 0.35, 0.72, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 36,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Brand.themeColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: pagePad,
                        right: artRightPad,
                        top: topInset + (compact ? 10 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              t('STORE_PANEL_ONBOARDING_TITLE'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Brand.themeColor,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                fontSize: titleSize,
                              ),
                            ),
                            SizedBox(height: compact ? 4 : 6),
                            Text(
                              t('STORE_PANEL_ONBOARDING_SUBTITLE'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.ink.withValues(alpha: 0.58),
                                height: 1.3,
                                fontSize: compact ? 13 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Brand.themeColor.withValues(alpha: 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, -10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pagePad, 20, pagePad, 32),
                        child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (_error != null) ...<Widget>[
                            StaffAuthErrorBanner(message: _error!),
                            const SizedBox(height: 16),
                          ],
                          _LabeledField(
                            label: t('STAFF.PHARMACY_NAME'),
                            required: true,
                            child: TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              style: theme.textTheme.bodyLarge,
                              decoration: _fieldDecoration(
                                hint: t('STAFF.PHARMACY_NAME'),
                                prefix: Icons.storefront_outlined,
                              ),
                              validator: (String? value) {
                                if ((value?.trim().length ?? 0) < 2) {
                                  return t('AUTH_REQUIRED');
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _LabeledField(
                                  label: t('STAFF.PHONE'),
                                  required: true,
                                  child: TextFormField(
                                    controller: _phone,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: _fieldDecoration(
                                      hint: t('STAFF.PHONE'),
                                      prefix: Icons.phone_outlined,
                                      dense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _LabeledField(
                                  label: t('STAFF.WHATSAPP'),
                                  child: TextFormField(
                                    controller: _whatsapp,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: _fieldDecoration(
                                      hint: t('STAFF.WHATSAPP'),
                                      prefix: Icons.chat_outlined,
                                      dense: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _LabeledField(
                            label: t('STOREFRONT.ADDRESS_LINE'),
                            required: true,
                            child: TextFormField(
                              controller: _address,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              style: theme.textTheme.bodyLarge,
                              decoration: _fieldDecoration(
                                hint: t('STOREFRONT.ADDRESS_LINE'),
                                prefix: Icons.location_on_outlined,
                              ),
                              validator: (String? value) {
                                if ((value?.trim().length ?? 0) < 3) {
                                  return t(
                                    'STOREFRONT.VALIDATION_ADDRESS_LINE',
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: _LabeledField(
                                  label: t('STOREFRONT.CITY'),
                                  required: true,
                                  child: TextFormField(
                                    controller: _city,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: _fieldDecoration(
                                      hint: t('STOREFRONT.CITY'),
                                      prefix: Icons.location_city_outlined,
                                      dense: true,
                                    ),
                                    validator: (String? value) {
                                      if ((value?.trim().length ?? 0) < 2) {
                                        return t(
                                          'STOREFRONT.VALIDATION_CITY',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _LabeledField(
                                  label: t('STOREFRONT.STATE'),
                                  required: true,
                                  child: TextFormField(
                                    controller: _state,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    style: theme.textTheme.bodyLarge,
                                    decoration: _fieldDecoration(
                                      hint: t('STOREFRONT.STATE'),
                                      prefix: Icons.map_outlined,
                                      dense: true,
                                      suffix: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.ink.withValues(
                                          alpha: 0.38,
                                        ),
                                        size: 18,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      if ((value?.trim().length ?? 0) < 2) {
                                        return t(
                                          'STOREFRONT.VALIDATION_STATE',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _LabeledField(
                                  label: t('STOREFRONT.PINCODE'),
                                  required: true,
                                  child: TextFormField(
                                    controller: _pincode,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    style: theme.textTheme.bodyLarge,
                                    decoration: _fieldDecoration(
                                      hint: t('STOREFRONT.PINCODE'),
                                      prefix: Icons.pin_drop_outlined,
                                      dense: true,
                                    ),
                                    validator: (String? value) {
                                      if (!RegExp(r'^\d{6}$').hasMatch(
                                        value?.trim() ?? '',
                                      )) {
                                        return t(
                                          'STOREFRONT.VALIDATION_PINCODE',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(t('STORE_FORM.TRACK_STOCK')),
                            subtitle: Text(t('STORE_FORM.TRACK_STOCK_HINT')),
                            value: _trackStock,
                            onChanged: _busy
                                ? null
                                : (bool value) =>
                                    setState(() => _trackStock = value),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: AppTheme.chargeHeight,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: AppTheme.charge.copyWith(
                                shape: const WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              child: _busy
                                  ? Text(t('STAFF.ONBOARDING_CREATING'))
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(t('STAFF.ONBOARDING_SUBMIT')),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
    bool dense = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      borderSide: const BorderSide(
        color: _fieldBorder,
        width: AppTheme.hairline,
      ),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.ink.withValues(alpha: 0.35),
        fontWeight: FontWeight.w400,
        fontSize: dense ? 12.5 : 15,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: dense,
      contentPadding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 14,
        vertical: dense ? 14 : 16,
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: dense ? 32 : 48,
        minHeight: dense ? 32 : 48,
      ),
      suffixIconConstraints: dense
          ? const BoxConstraints(minWidth: 24, minHeight: 32)
          : null,
      prefixIcon: Icon(
        prefix,
        color: AppTheme.ink.withValues(alpha: 0.42),
        size: dense ? 16 : 22,
      ),
      suffixIcon: suffix,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(
          color: Brand.themeColor,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(
          color: AppTheme.error,
          width: AppTheme.hairline,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(
          color: AppTheme.error,
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final storeUser = await ref
          .read(storeOnboardingServiceProvider)
          .createStore(
            CreateStoreInput(
              name: _name.text,
              phone: _phone.text,
              whatsappNumber: _whatsapp.text,
              address: _address.text,
              city: _city.text,
              state: _state.text,
              pincode: _pincode.text.trim(),
              trackStock: _trackStock,
            ),
          );
      ref.read(staffSessionProvider.notifier).setStoreUser(storeUser);
      if (!mounted) return;
      context.go(Routes.staffToday);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final message = '$error';
        _error = message.contains('not configured')
            ? t('AUTH_SUPABASE_MISSING')
            : (message.isEmpty ? t('ERROR_GENERIC') : message);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            children: required
                ? const <InlineSpan>[
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
