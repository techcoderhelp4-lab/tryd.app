import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final gpsCacheServiceProvider = Provider<GpsCacheService>((ref) {
  final service = GpsCacheService();
  ref.onDispose(service.dispose);
  return service;
});

/// Maintains a background GPS warm-up stream so the Running Screen can skip
/// the "Acquiring GPS…" wait when a fresh fix is already available.
class GpsCacheService {
  Position? _cachedPosition;
  DateTime? _cachedAt;
  StreamSubscription<Position>? _sub;

  static const Duration _freshThreshold = Duration(seconds: 120);
  static const double _acceptableAccuracy = 25.0;

  Position? get cachedPosition => _cachedPosition;

  bool get hasFreshFix {
    if (_cachedPosition == null || _cachedAt == null) return false;
    return DateTime.now().difference(_cachedAt!) < _freshThreshold;
  }

  /// Starts (or restarts) a low-drain background location stream.
  /// Safe to call multiple times — ignores the call if already running.
  Future<void> startWarmUp() async {
    if (_sub != null) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final locationSettings = _buildSettings();
      _sub = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
        _onPosition,
        onError: (Object e) => debugPrint('GpsCacheService stream error: $e'),
        cancelOnError: false,
      );
    } on Exception catch (e) {
      debugPrint('GpsCacheService.startWarmUp error: $e');
    }
  }

  void _onPosition(Position position) {
    if (position.accuracy <= _acceptableAccuracy) {
      _cachedPosition = position;
      _cachedAt = DateTime.now();
    } else if (_cachedPosition == null) {
      // Keep the best available fix even if not ideal yet
      _cachedPosition = position;
      _cachedAt = DateTime.now();
    }
  }

  LocationSettings _buildSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 10,
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
