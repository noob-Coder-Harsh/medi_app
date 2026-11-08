import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'brand.dart';
import 'env.dart';
import 'routes.dart';

/// Fallback HTTPS host when [Env.apiBaseUrl] is unset (tests / cold start).
const String kDeepLinkHostFallback = 'medsahayta-iota.vercel.app';

/// Custom scheme fallback (QR may still use HTTPS).
const String kDeepLinkScheme = 'medisync';

/// Host used for HTTPS App / Universal Links ([Env.apiBaseHost]).
String get kDeepLinkHost {
  final fromEnv = Env.apiBaseHost;
  if (fromEnv.isNotEmpty) return fromEnv.toLowerCase();
  return kDeepLinkHostFallback;
}

bool _isDeepLinkHost(String host) {
  final primary = kDeepLinkHost;
  return host == primary || host == 'www.$primary';
}

/// Maps inbound URIs to Flutter go_router locations.
///
/// Web: `https://{API_BASE_URL host}/{slug}` → `/shop/{slug}`
/// Custom: `medisync://shop/{slug}` → `/shop/{slug}`
@visibleForTesting
String? mapDeepLinkToLocation(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();

  if (scheme == 'http' || scheme == 'https') {
    if (!_isDeepLinkHost(host)) {
      return null;
    }
    return _mapPath(uri.pathSegments);
  }

  if (scheme == kDeepLinkScheme) {
    // medisync://shop/slug  OR  medisync:///shop/slug
    final segments = <String>[
      if (host.isNotEmpty && host != 'shop') host,
      ...uri.pathSegments,
    ];
    return _mapPath(segments);
  }

  return null;
}

String? _mapPath(List<String> rawSegments) {
  final segments = rawSegments
      .where((String s) => s.isNotEmpty)
      .map((String s) => Uri.decodeComponent(s))
      .toList(growable: false);
  if (segments.isEmpty) return null;

  // Drop optional leading "shop" so web /{slug} and app /shop/{slug} both work.
  final parts = segments.first == 'shop' ? segments.skip(1).toList() : segments;
  if (parts.isEmpty) return null;

  final slug = parts[0];
  if (!_isShopSlug(slug)) return null;

  if (parts.length == 1) return Routes.shop(slug);

  if (parts.length >= 3 && parts[1] == 'category') {
    return Routes.category(slug, parts[2]);
  }
  if (parts.length >= 3 && parts[1] == 'product') {
    return Routes.product(slug, parts[2]);
  }
  if (parts.length >= 2 && parts[1] == 'info') {
    return Routes.shopInfo(slug);
  }

  // Unknown nested path under a valid slug → shop home.
  return Routes.shop(slug);
}

bool _isShopSlug(String slug) {
  if (slug.isEmpty || slug.length > 64) return false;
  // Marketing / legal paths on the same host must not open as shops.
  const reserved = <String>{
    'for-pharmacies',
    'privacy-policy',
    'terms-and-conditions',
    'contact',
    'login',
    'signup',
    'admin',
    'api',
    'staff',
    '.well-known',
  };
  if (reserved.contains(slug.toLowerCase())) return false;
  return RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*$').hasMatch(slug);
}

/// Listens for initial + runtime links and navigates via [GoRouter].
class DeepLinkController {
  DeepLinkController({
    required GoRouter router,
    AppLinks? appLinks,
  }) : _router = router,
       _appLinks = appLinks ?? AppLinks();

  final GoRouter _router;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _open(initial);
      }
    } catch (error) {
      debugPrint('DeepLink initial failed: $error');
    }

    _sub = _appLinks.uriLinkStream.listen(
      _open,
      onError: (Object error) {
        debugPrint('DeepLink stream error: $error');
      },
    );
  }

  void _open(Uri uri) {
    final location = mapDeepLinkToLocation(uri);
    if (location == null || location.isEmpty) return;
    _router.go(location);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }
}

final deepLinkControllerProvider = Provider<DeepLinkController?>((Ref ref) {
  // Wired from MediApp once a router is available.
  return null;
});

/// Brand website helper for share / QR copy.
String publicShopUrl(String slug) => '${Brand.urls.website}/$slug';
