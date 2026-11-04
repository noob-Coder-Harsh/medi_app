import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand.dart';
import '../../core/i18n.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/local/location_store.dart';
import 'location_service.dart';
import 'store_resolver.dart';

const Duration kStaffLogoLongPress = Duration(milliseconds: 600);

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  Timer? _logoHold;
  bool _busy = false;
  bool _empty = false;
  bool _deniedForever = false;
  String? _messageKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resumeIfPossible());
    });
  }

  @override
  void dispose() {
    _logoHold?.cancel();
    super.dispose();
  }

  void _armStaffEntry() {
    _logoHold?.cancel();
    _logoHold = Timer(kStaffLogoLongPress, () {
      if (!mounted) return;
      context.go(Routes.staffLogin);
    });
  }

  void _cancelStaffEntry() {
    _logoHold?.cancel();
    _logoHold = null;
  }

  Future<void> _resumeIfPossible() async {
    final saved = await ref.read(locationStoreProvider).read();
    if (!mounted || saved == null) return;

    final peek = await ref.read(locationServiceProvider).readIfAlreadyGranted();
    if (!mounted || peek == null) return;

    final point = peek.point ?? saved;
    if (peek.point != null) {
      await ref.read(locationStoreProvider).save(peek.point!);
      if (!mounted) return;
    }
    await _resolve(point);
  }

  Future<void> _onAllow() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _empty = false;
      _messageKey = null;
    });

    final service = ref.read(locationServiceProvider);
    if (_deniedForever) {
      await service.openSettings();
    }

    final fix = await service.requestAndRead();
    if (!mounted) return;

    if (fix.status == LocationFixStatus.disabled) {
      await service.openLocationSettings();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageKey = 'STOREFRONT.LOCATION_SHEET_ERROR';
      });
      return;
    }

    if (fix.status == LocationFixStatus.granted && fix.point != null) {
      await ref.read(locationStoreProvider).save(fix.point!);
      if (!mounted) return;
      await _resolve(fix.point!);
      return;
    }

    setState(() {
      _busy = false;
      _deniedForever = fix.status == LocationFixStatus.deniedForever;
      _messageKey = switch (fix.status) {
        LocationFixStatus.denied ||
        LocationFixStatus.deniedForever =>
          'STOREFRONT.LOCATION_SHEET_DENIED',
        LocationFixStatus.unsupported => 'STOREFRONT.LOCATION_SHEET_UNSUPPORTED',
        LocationFixStatus.disabled ||
        LocationFixStatus.error ||
        LocationFixStatus.granted =>
          'STOREFRONT.LOCATION_SHEET_ERROR',
      };
    });
  }

  Future<void> _resolve(SavedLocation point) async {
    setState(() {
      _busy = true;
      _empty = false;
      _messageKey = null;
    });

    try {
      final lastId = await ref.read(shopSessionStoreProvider).readLastStoreId();
      if (!mounted) return;
      final resolved = await ref.read(storeResolverProvider).resolve(
        lat: point.lat,
        lng: point.lng,
        lastStoreId: lastId,
      );
      if (!mounted) return;
      if (resolved == null) {
        setState(() {
          _busy = false;
          _empty = true;
        });
        return;
      }
      context.go(Routes.shop(resolved.shop.store.slug));
    } catch (error, stack) {
      debugPrint('Store resolve failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageKey = 'STOREFRONT.LOCATION_SHEET_ERROR';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final titleKey = _empty
        ? 'STOREFRONT.MARKETPLACE_NEARBY_EMPTY_TITLE'
        : 'STOREFRONT.LOCATION_SHEET_TITLE';
    final bodyKey = _empty
        ? 'STOREFRONT.MARKETPLACE_NEARBY_EMPTY_BODY'
        : 'STOREFRONT.LOCATION_SHEET_BODY';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Listener(
                key: const Key('location-logo'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _armStaffEntry(),
                onPointerUp: (_) => _cancelStaffEntry(),
                onPointerCancel: (_) => _cancelStaffEntry(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Brand.themeColor,
                        borderRadius: AppTheme.borderRadius,
                      ),
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          Icons.local_pharmacy_outlined,
                          color: AppTheme.onTeal,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Brand.appName,
                      style: textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                t(titleKey),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                t(bodyKey),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              if (_messageKey != null) ...<Widget>[
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.error_outline, color: colors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t(_messageKey!),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('location-allow'),
                  onPressed: _busy ? null : _onAllow,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppTheme.touchTarget),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onTeal,
                          ),
                        )
                      : Text(t('STOREFRONT.LOCATION_SHEET_ALLOW')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
