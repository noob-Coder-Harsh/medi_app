import 'package:flutter/material.dart';

/// Bundled defaults from web `public/category/*.png` (same slug map).
const Map<String, String> kSystemCategoryImages = <String, String>{
  'tablets-capsules': 'assets/images/category/tablets.png',
  'syrups-liquids': 'assets/images/category/syrups.png',
  'drops': 'assets/images/category/drops.png',
  'injections': 'assets/images/category/injections.png',
  'creams-ointments': 'assets/images/category/creams.png',
  'inhalers-devices': 'assets/images/category/inhalers.png',
  'baby-care': 'assets/images/category/baby.png',
  'personal-care': 'assets/images/category/personal.png',
  'ayurvedic': 'assets/images/category/ayurvedic.png',
  'otc-fmcg': 'assets/images/category/otc.png',
  'others': 'assets/images/category/others.png',
};

const Map<String, String> kSystemCategoryBanners = <String, String>{
  'otc-fmcg': 'assets/images/category/otc-fmcg-banner.png',
  'others': 'assets/images/category/others-banner.png',
  'drops': 'assets/images/category/drops-banner.png',
  'ayurvedic': 'assets/images/category/ayurvedic-banner.png',
  'inhalers-devices': 'assets/images/category/inhalers-devices-banner.png',
  'syrups-liquids': 'assets/images/category/syrups-liquids-banner.png',
  'personal-care': 'assets/images/category/personal-care-banner.png',
  'tablets-capsules': 'assets/images/category/tablets-capsules-banner.png',
  'surgical': 'assets/images/category/surgical-banner.png',
  'injections': 'assets/images/category/injections-banner.png',
  'baby-care': 'assets/images/category/baby-care-banner.png',
  'creams-ointments': 'assets/images/category/creams-ointments-banner.png',
};

class CategoryIconStyle {
  const CategoryIconStyle({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

const Map<String, CategoryIconStyle> kSystemCategoryIconStyles =
    <String, CategoryIconStyle>{
  'tablets-capsules': CategoryIconStyle(
    icon: Icons.medication_outlined,
    background: Color(0xFFF0F9FF),
    foreground: Color(0xFF0284C7),
  ),
  'syrups-liquids': CategoryIconStyle(
    icon: Icons.science_outlined,
    background: Color(0xFFFFF7ED),
    foreground: Color(0xFFEA580C),
  ),
  'drops': CategoryIconStyle(
    icon: Icons.water_drop_outlined,
    background: Color(0xFFEFF6FF),
    foreground: Color(0xFF2563EB),
  ),
  'injections': CategoryIconStyle(
    icon: Icons.vaccines_outlined,
    background: Color(0xFFFFF1F2),
    foreground: Color(0xFFE11D48),
  ),
  'creams-ointments': CategoryIconStyle(
    icon: Icons.spa_outlined,
    background: Color(0xFFECFDF5),
    foreground: Color(0xFF059669),
  ),
  'inhalers-devices': CategoryIconStyle(
    icon: Icons.favorite_outline,
    background: Color(0xFFFEF2F2),
    foreground: Color(0xFFEF4444),
  ),
  'surgical': CategoryIconStyle(
    icon: Icons.medical_services_outlined,
    background: Color(0xFFFEF2F2),
    foreground: Color(0xFFDC2626),
  ),
  'baby-care': CategoryIconStyle(
    icon: Icons.child_care_outlined,
    background: Color(0xFFFFF7ED),
    foreground: Color(0xFFF97316),
  ),
  'personal-care': CategoryIconStyle(
    icon: Icons.soap_outlined,
    background: Color(0xFFFFFBEB),
    foreground: Color(0xFFD97706),
  ),
  'ayurvedic': CategoryIconStyle(
    icon: Icons.eco_outlined,
    background: Color(0xFFF0FDF4),
    foreground: Color(0xFF16A34A),
  ),
  'otc-fmcg': CategoryIconStyle(
    icon: Icons.medication_liquid_outlined,
    background: Color(0xFFF0FDFA),
    foreground: Color(0xFF0D9488),
  ),
  'others': CategoryIconStyle(
    icon: Icons.grid_view_rounded,
    background: Color(0xFFF1F5F9),
    foreground: Color(0xFF64748B),
  ),
};

const CategoryIconStyle kDefaultCategoryIconStyle = CategoryIconStyle(
  icon: Icons.medication_outlined,
  background: Color(0xFFF0FDFA),
  foreground: Color(0xFF0D9488),
);

/// DB / network `iconUrl` wins; else bundled PNG by slug.
String? resolveCategoryImageSrc(String? iconUrl, String? slug) {
  final custom = iconUrl?.trim() ?? '';
  if (custom.isNotEmpty) return custom;
  if (slug == null || slug.isEmpty) return null;
  return kSystemCategoryImages[slug];
}

String? resolveCategoryBannerSrc(String? slug) {
  if (slug == null || slug.isEmpty) return null;
  return kSystemCategoryBanners[slug];
}

CategoryIconStyle categoryIconStyle(String? slug) {
  if (slug == null || slug.isEmpty) return kDefaultCategoryIconStyle;
  return kSystemCategoryIconStyles[slug] ?? kDefaultCategoryIconStyle;
}

bool isNetworkCategoryImage(String src) {
  return src.startsWith('http://') || src.startsWith('https://');
}
