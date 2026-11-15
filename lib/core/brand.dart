import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'env.dart';

/// Product identity from `docs/web-source/brand.ts`.
/// UI chrome lives in locale JSON, not here.
abstract final class Brand {
  static const appName = 'MediSync';
  static const appNameFull = 'MediSync - Pharmacy Ordering SaaS';
  static const companyName = 'MediSync';
  static const tagline =
      'Enable local pharmacies to accept online orders in 1 hour';
  static const customerTagline = 'Your Health, Our Priority';
  static const shortDescription =
      'Online pharmacy ordering platform for local medical stores';
  static const longDescription =
      'MediSync empowers local pharmacies to start accepting online orders without requiring technical knowledge. Get a dedicated online storefront, QR code ordering, product catalog, and order dashboard.';

  /// Primary mark used for launcher, splash, and in-app branding.
  static const logoAsset = 'assets/images/app_logo.png';

  static const Color themeColor = AppColors.primary;
  static const Color themeBackground = AppColors.pageBg;
  static const Color splashBackground = AppColors.secondary;

  static const contact = BrandContact();
  static const operator = BrandOperator();
  static const urls = BrandUrls();
  static const social = BrandSocial();
  static const storage = BrandStorage();
  static const legal = BrandLegal();

  static String pageTitle(String page) => '$page | $appName';

  static String metaDescription(String description) {
    if (description.length <= 160) return description;
    return '${description.substring(0, 157)}...';
  }
}

/// Shared MediSync mark for location, auth, and empty store logos.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 72,
    this.showName = false,
    this.nameStyle,
    this.gap = 12,
  });

  final double size;
  final bool showName;
  final TextStyle? nameStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        Brand.logoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );

    if (!showName) return logo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        logo,
        SizedBox(height: gap),
        Text(
          Brand.appName,
          style: nameStyle ?? Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

@immutable
class BrandContact {
  const BrandContact();

  String get email => 'harsh.kushwaha664@gmail.com';
  String get phone => '+91 9871538356';
  String get supportEmail => 'harsh.kushwaha664@gmail.com';
}

@immutable
class BrandOperator {
  const BrandOperator();

  String get name => 'IM7 Digital';
  String get tagline => 'Owned and managed by IM7 Digital';
  String get website => 'https://im7.in';
}

@immutable
class BrandUrls {
  const BrandUrls();

  /// Public site origin — same as [Env.apiBaseUrl] (falls back for tests/docs).
  String get origin {
    final base = Env.apiBaseUrl;
    if (base.isNotEmpty) return base;
    return 'https://medsahayta-iota.vercel.app';
  }

  String get website => origin;
  String get app => origin;
  String get docs => origin;
  String get privacyPolicy => '$origin/privacy-policy';
  String get termsOfService => '$origin/terms-and-conditions';
  String get contact => '$origin/contact';
}

@immutable
class BrandSocial {
  const BrandSocial();

  String get twitter => 'https://twitter.com/medsync';
  String get linkedin => 'https://linkedin.com/company/medsync';
  String get instagram => 'https://instagram.com/medsync';
  String get facebook => 'https://facebook.com/medsync';
  String get youtube => 'https://youtube.com/@medsync';
}

@immutable
class BrandStorage {
  const BrandStorage();

  String get bucketName => 'medsahayta';
  int get maxUploadSizeMb => 10;
}

@immutable
class BrandLegal {
  const BrandLegal();

  String get privacyTitle => 'Privacy Policy';
  String get termsTitle => 'Terms and Conditions';
  String get contactTitle => 'Contact Us';
  String get lastUpdated => 'June 20, 2026';
}
