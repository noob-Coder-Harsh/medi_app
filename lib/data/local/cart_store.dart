import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_cart.dart';

/// Device cart: ids and quantities only. Never a product dump.
class CartStore {
  static const prefsKey = 'cart';

  Future<LocalCart> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return LocalCart.empty;
    try {
      return LocalCart.fromJson(jsonDecode(raw));
    } catch (_) {
      return LocalCart.empty;
    }
  }

  Future<void> write(LocalCart cart) async {
    final prefs = await SharedPreferences.getInstance();
    if (cart.items.isEmpty) {
      await prefs.remove(prefsKey);
      return;
    }
    await prefs.setString(prefsKey, jsonEncode(cart.toJson()));
  }
}
