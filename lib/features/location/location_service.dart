import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/local/location_store.dart';

enum LocationFixStatus {
  granted,
  denied,
  deniedForever,
  disabled,
  unsupported,
  error,
}

class LocationFix {
  const LocationFix({required this.status, this.point});

  final LocationFixStatus status;
  final SavedLocation? point;
}

abstract class LocationService {
  Future<LocationFix> requestAndRead();
  Future<LocationFix?> readIfAlreadyGranted();
  Future<void> openSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  static const LocationSettings _defaultSettings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 20),
  );

  static final LocationSettings _androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: const Duration(seconds: 25),
  );

  LocationSettings get _settings =>
      defaultTargetPlatform == TargetPlatform.android
          ? _androidSettings
          : _defaultSettings;

  @override
  Future<LocationFix> requestAndRead() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationFix(status: LocationFixStatus.disabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationFix(status: LocationFixStatus.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationFix(status: LocationFixStatus.deniedForever);
      }
      if (permission == LocationPermission.unableToDetermine) {
        return const LocationFix(status: LocationFixStatus.unsupported);
      }

      return LocationFix(
        status: LocationFixStatus.granted,
        point: await _currentPoint(),
      );
    } catch (error, stack) {
      debugPrint('Location requestAndRead failed: $error\n$stack');
      return const LocationFix(status: LocationFixStatus.error);
    }
  }

  @override
  Future<LocationFix?> readIfAlreadyGranted() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
      try {
        return LocationFix(
          status: LocationFixStatus.granted,
          point: await _currentPoint(),
        );
      } catch (error, stack) {
        debugPrint('Location readIfAlreadyGranted point failed: $error\n$stack');
        return const LocationFix(status: LocationFixStatus.granted);
      }
    } catch (error, stack) {
      debugPrint('Location readIfAlreadyGranted failed: $error\n$stack');
      return null;
    }
  }

  Future<SavedLocation> _currentPoint() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return SavedLocation(lat: position.latitude, lng: position.longitude);
    } catch (error) {
      debugPrint('getCurrentPosition failed, trying last known: $error');
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) rethrow;
      return SavedLocation(lat: last.latitude, lng: last.longitude);
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

final locationServiceProvider = Provider<LocationService>(
  (Ref ref) => GeolocatorLocationService(),
);

final locationStoreProvider = Provider<LocationStore>(
  (Ref ref) => LocationStore(),
);
