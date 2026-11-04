import 'package:shared_preferences/shared_preferences.dart';

class SavedLocation {
  const SavedLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

/// Device prefs for last granted lat/lng.
class LocationStore {
  static const latKey = 'location.lat';
  static const lngKey = 'location.lng';

  Future<void> save(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(latKey, location.lat);
    await prefs.setDouble(lngKey, location.lng);
  }

  Future<SavedLocation?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(latKey);
    final lng = prefs.getDouble(lngKey);
    if (lat == null || lng == null) {
      return null;
    }
    return SavedLocation(lat: lat, lng: lng);
  }
}
