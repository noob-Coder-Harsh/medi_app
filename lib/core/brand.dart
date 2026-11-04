import 'package:flutter/material.dart';

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

  static const Color themeColor = Color(0xFF0F766E);
  static const Color themeBackground = Color(0xFFF7FAF9);

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

  String get website => 'https://med.im7.in';
  String get app => 'https://med.im7.in';
  String get docs => 'https://med.im7.in';
  String get privacyPolicy => 'https://med.im7.in/privacy-policy';
  String get termsOfService => 'https://med.im7.in/terms-and-conditions';
  String get contact => 'https://med.im7.in/contact';
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
