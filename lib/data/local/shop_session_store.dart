import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/listing.dart';

/// Last resolved shop + nearby list for the home shop-switcher.
class ShopSessionStore {
  static const storeIdKey = 'lastStoreId';
  static const slugKey = 'lastStoreSlug';
  static const nearbyKey = 'nearbyStores';

  Future<void> save({
    required String storeId,
    required String slug,
    required List<NearbyStore> nearby,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeIdKey, storeId);
    await prefs.setString(slugKey, slug);
    await prefs.setString(
      nearbyKey,
      jsonEncode(nearby.map(nearbyStoreToJson).toList()),
    );
  }

  Future<String?> readLastStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storeIdKey);
  }

  Future<String?> readLastSlug() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(slugKey);
  }

  Future<List<NearbyStore>> readNearby() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(nearbyKey);
    if (raw == null || raw.isEmpty) return const <NearbyStore>[];
    try {
      return parseNearbyStores(jsonDecode(raw));
    } catch (_) {
      return const <NearbyStore>[];
    }
  }
}
