import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../location/location_screen.dart';
import 'customer_auth.dart';

/// Phone OTP sheet. Opens on write intents only. Long-press logo → staff login.
Future<bool> showOtpSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheet) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheet).bottom,
        ),
        child: const OtpSheet(),
      );
    },
  );
  return result == true;
}

class OtpSheet extends ConsumerStatefulWidget {
  const OtpSheet({super.key});

  @override
  ConsumerState<OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends ConsumerState<OtpSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  var _sent = false;
  var _busy = false;
  String? _error;
  Timer? _logoHold;

  @override
  void dispose() {
    _logoHold?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final e164 = normalizeIndianMobile(_phone.text);
    if (e164 == null) {
      setState(() => _error = t('STOREFRONT.OTP_PHONE_INVALID'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(customerAuthProvider).sendOtp(e164);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('STOREFRONT.OTP_SENT'))),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  Future<void> _verify() async {
    final e164 = normalizeIndianMobile(_phone.text);
    if (e164 == null) {
      setState(() => _error = t('STOREFRONT.OTP_PHONE_INVALID'));
      return;
    }
    if (!isValidOtpCode(_code.text)) {
      setState(() => _error = t('STOREFRONT.OTP_CODE_INVALID'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await ref.read(customerAuthProvider).verifyOtp(
        phoneE164: e164,
        code: _code.text.trim(),
      );
      await ref.read(customerSessionProvider.notifier).signInWithIdToken(token);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTapDown: (_) {
                  _logoHold?.cancel();
                  _logoHold = Timer(kStaffLogoLongPress, () {
                    if (!mounted) return;
                    Navigator.of(context).pop(false);
                    context.go(Routes.staffLogin);
                  });
                },
                onTapUp: (_) => _logoHold?.cancel(),
                onTapCancel: () => _logoHold?.cancel(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    Brand.appName,
                    key: const Key('otp-logo'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            Text(
              t('STOREFRONT.OTP_TITLE'),
              key: const Key('otp-stub-title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(t('STOREFRONT.OTP_HINT')),
            const SizedBox(height: 12),
            TextField(
              key: const Key('otp-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: t('STOREFRONT.OTP_PHONE_LABEL'),
              ),
            ),
            if (_sent) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                key: const Key('otp-code'),
                controller: _code,
                keyboardType: TextInputType.number,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: t('STOREFRONT.OTP_CODE_LABEL'),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const Key('otp-error'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: AppTheme.touchTarget,
              child: FilledButton(
                key: Key(_sent ? 'otp-verify' : 'otp-send'),
                onPressed: _busy ? null : (_sent ? _verify : _send),
                child: Text(
                  _busy
                      ? t('WRITE_LOADING')
                      : (_sent
                            ? t('STOREFRONT.OTP_VERIFY')
                            : t('STOREFRONT.OTP_SEND')),
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: Text(t('STOREFRONT.CLOSE_DRAWER')),
            ),
          ],
        ),
      ),
    );
  }
}
