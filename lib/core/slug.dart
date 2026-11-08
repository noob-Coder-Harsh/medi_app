/// Store URL slug helpers — same rules as web `toSlug` / reserved list.
String toSlug(String value) {
  final lowered = value.toLowerCase().trim();
  final stripped = lowered.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
  final dashed = stripped.replaceAll(RegExp(r'[\s_-]+'), '-');
  return dashed.replaceAll(RegExp(r'^-+|-+$'), '');
}

const Set<String> kReservedStoreSlugs = <String>{
  'auth',
  'admin',
  'dashboard',
  'settings',
  'api',
  'cart',
  'checkout',
  'orders',
  'account',
  'prescription',
  'contact',
  'privacy-policy',
  'terms-and-conditions',
  'onboarding',
  'for-pharmacies',
  'medicines',
  'products',
  'purchases',
  'payments',
  'customers',
  'suppliers',
  'categories',
  'returns',
  'login',
  'signup',
  'search',
  'pharmacies',
  'staff',
  'location',
};

bool isReservedStoreSlug(String slug) {
  final normalized = slug.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return kReservedStoreSlugs.contains(normalized);
}
