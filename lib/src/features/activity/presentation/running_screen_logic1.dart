// running_screen_logic_fixed.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../notifications/data/real_time_notification_service.dart';
import '../../challenges/data/challenge_repository.dart';
import '../data/workout_lock_screen_service.dart';
import '../data/gps_cache_service.dart';
import '../../profile/data/user_repository.dart';
import '../data/activity_repository.dart';
import '../data/health_repository.dart';
import '../domain/activity.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import 'package:tryd/main.dart' show localeProvider;

enum RunningState { idle, countdown, running, paused, finished }

class RunningCoreLogic {
  final WidgetRef ref;
  final BuildContext context;
  final VoidCallback onStateChanged;
  final Function(String, {bool force}) speak;

  RunningCoreLogic({
    required this.ref,
    required this.context,
    required this.onStateChanged,
    required this.speak,
  });

  // ─── State Variables ─────────────────────────────────────────────────────
  String activityType = 'run';
  RunningState runningState = RunningState.idle;
  final MapController mapController = MapController();
  final DraggableScrollableController sheetController = DraggableScrollableController();
  LatLng currentLocation = const LatLng(29.2882, 47.9015);
  LatLng? startLocation;

  // Route tracking
  final List<LatLng> routePoints = [];
  final List<DateTime> routePointTimes = [];
  final List<double> routePointDistances = [];

  // Stats
  Timer? timer;
  int seconds = 0;
  double distance = 0.0;
  double calories = 0.0;
  double avgPace = 0.0;
  double currentPace = 0.0;

  int healthSteps = 0;
  int steps = 0;
  double avgBpm = 0.0;
  double earnedPoints = 0.0;

  bool isAutoFollow = true;
  Timer? autoFollowResumeTimer;
  final Distance distanceCalc = const Distance();
  DateTime? runStartTime;

  // Location Tracking
  StreamSubscription<Position>? positionStreamSubscription;
  DateTime? lastGPSPointTime;
  LatLng? realGPSLocation;
  Position? lastPosition;
  bool isGpsReady = false;
  double currentAccuracy = 0.0;

  // Countdown
  Timer? countdownTimer;
  int countdownSeconds = 3;

  // GPS filtering
  LatLng? _lastValidPosition;
  DateTime? _lastValidPositionTime;
  static const double maxRealisticSpeed = 9.0;
  static const double maxAccuracyMeters = 30.0;

  // Announcements
  int lastKmAnnounced = 0;

  // Strava-style Accuracy & Signal Quality
  final List<double> _accuracyHistory = [];
  bool _driftWarningShown = false;
  Timer? _lostSignalTimer;
  bool _batteryOptimizationChecked = false;

  // Indoor Mode tracking
  bool _isIndoorMode = false;
  DateTime? _lastGoodGPSPoint;
  int _poorAccuracyCount = 0;
  bool get isIndoorMode => _isIndoorMode;

  // User profile
  double _userWeightKg = 70.0;
  double _userHeightCm = 170.0;
  int _userAge = 30;
  String _userGender = 'male';

  // Health Connect
  bool isHealthConnected = false;
  StreamSubscription<double>? heartRateSubscription;
  StreamSubscription<int>? stepsStreamSubscription;
  StreamSubscription<double>? caloriesStreamSubscription;
  double _totalBpmSum = 0.0;
  int _bpmReadingCount = 0;

  // Lock screen workout service
  late final WorkoutLockScreenService lockScreenService = ref.read(workoutLockScreenServiceProvider);
  StreamSubscription<String>? _lockScreenActionSub;

  // Tracking state
  double _rawDistance = 0.0;
  List<LatLng> _rawPoints = [];
  final List<double> _recentSpeeds = [];

  // GPS acquisition
  bool _autoRecenterOnFirstGoodFix = false;
  final List<LatLng> _recentIdleFixes = [];



  // Heading
  static const double headingUpdateThreshold = 0.5;
  double _totalSinceLastHeading = 0.0;
  double _currentHeading = 0.0;
  final List<LatLng> _headingPoints = [];
  double get currentHeading => _currentHeading;

  // Stationary detection
  static const double minSpeedForMovement = 0.8;
  static const double minStartDistance = 5.0;
  static const double minGPSDriftFilter = 0.8;
  static const int requiredMovingSamples = 3;
  static const double stationaryTimeoutSeconds = 15;
  static const int gpsWarmupSeconds = 5;

  // Movement State Tracking
  int _consecutiveMovingSamples = 0;
  bool _isActuallyMoving = false;
  DateTime? _lastMovementTime;
  double _lastValidSpeed = 0.0;
  bool _wasStationaryReported = false;
  bool _isSaving = false;
  int _movingSeconds = 0;

  // ─── SMOOTH DISPLAY POSITION ──────────────────────────────────────────────
  // Separates raw GPS from what the user sees on screen.
  // Dot stays frozen when standing still / drifting.
  // Only moves when real confirmed movement >= movementConfirmThreshold.
  LatLng _smoothedDisplayLocation = const LatLng(29.2882, 47.9015);
  LatLng? _lastConfirmedLocation;
  static const double movementConfirmThreshold = 2.5; // meters

  // ─────────────────────────────────────────────────────────────────────────
  // Sheet Heights
  // ─────────────────────────────────────────────────────────────────────────

  static const double sheetIdleSmall = 0.72;
  static const double sheetIdleMedium = 0.68;
  static const double sheetIdleLarge = 0.70;
  static const double sheetIdleTablet = 0.60;
  static const double sheetRunSmall = 0.60;
  static const double sheetRunMedium = 0.53;
  static const double sheetRunLarge = 0.60;
  static const double sheetRunTablet = 0.50;
  static const double sheetMinSmall = 0.60;
  static const double sheetMinMedium = 0.53;
  static const double sheetMinLarge = 0.60;
  static const double sheetMinTablet = 0.50;

  double get sheetHeightIdle {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return sheetIdleTablet;
    return h < 680 ? sheetIdleSmall : h < 850 ? sheetIdleMedium : sheetIdleLarge;
  }

  double get sheetHeightRunning {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return sheetRunTablet;
    return h < 680 ? sheetRunSmall : h < 850 ? sheetRunMedium : sheetRunLarge;
  }

  double get sheetHeightMin {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return sheetMinTablet;
    return h < 680 ? sheetMinSmall : h < 850 ? sheetMinMedium : sheetMinLarge;
  }

  EdgeInsets getMapPadding() {
    if (!context.mounted) return EdgeInsets.zero;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    double bottomOffset;
    if (runningState == RunningState.finished) {
      bottomOffset = screenHeight * 0.65;
    } else if (runningState == RunningState.running || runningState == RunningState.paused) {
      final double sheetRatio =
          sheetController.isAttached ? sheetController.size : sheetHeightRunning;
      bottomOffset = (screenHeight * sheetRatio) + 40;
    } else if (runningState == RunningState.countdown) {
      bottomOffset = screenHeight * 0.20;
    } else {
      final double sheetRatio =
          sheetController.isAttached ? sheetController.size : sheetHeightIdle;
      bottomOffset = screenHeight * sheetRatio;
    }
    final double topPad = screenHeight * 0.14;
    final double sidePad = isTablet ? 60.0 : 45.0;
    return EdgeInsets.only(top: topPad, left: sidePad, right: sidePad, bottom: bottomOffset);
  }

  void centerMap(LatLng loc) {
    if (!context.mounted) return;
    try {
      mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [loc],
          padding: getMapPadding(),
          maxZoom: 18.8,
          forceIntegerZoomLevel: false,
        ),
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SMOOTH DISPLAY POSITION
  // ─────────────────────────────────────────────────────────────────────────

  LatLng _getSmoothedLocation(LatLng rawGPS) {
    if (_lastConfirmedLocation == null) {
      _lastConfirmedLocation = rawGPS;
      _smoothedDisplayLocation = rawGPS;
      return rawGPS;
    }

    // Use an Exponential Moving Average (EMA) for visual dot.
    // High weight when moving (tracks quick), low weight when stationary (absorbs jitter).
    final double weight = _isActuallyMoving ? 0.8 : 0.15;

    _smoothedDisplayLocation = LatLng(
      _smoothedDisplayLocation.latitude * (1 - weight) + rawGPS.latitude * weight,
      _smoothedDisplayLocation.longitude * (1 - weight) + rawGPS.longitude * weight,
    );

    _lastConfirmedLocation = rawGPS;
    return _smoothedDisplayLocation;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchInitialLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (!context.mounted) return;
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      _autoRecenterOnFirstGoodFix = true;
      await _loadUserProfile();

      // Show last-known position immediately so the map isn't blank while GPS warms up
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (!context.mounted) return;
      if (lastKnown != null) {
        final loc = LatLng(lastKnown.latitude, lastKnown.longitude);
        currentLocation = loc;
        _smoothedDisplayLocation = loc;
        _lastConfirmedLocation = loc;
        realGPSLocation = loc;
        currentAccuracy = lastKnown.accuracy;
        onStateChanged();
        WidgetsBinding.instance.addPostFrameCallback((_) => centerMap(loc));
        debugPrint("Last-known fix shown: ${lastKnown.accuracy}m");
      }

      // Use the pre-warmed fix if it's fresh enough — skips the acquiring wait
      final cache = ref.read(gpsCacheServiceProvider);
      if (cache.hasFreshFix) {
        final pos = cache.cachedPosition!;
        final loc = LatLng(pos.latitude, pos.longitude);
        currentLocation = loc;
        _smoothedDisplayLocation = loc;
        _lastConfirmedLocation = loc;
        realGPSLocation = loc;
        currentAccuracy = pos.accuracy;
        if (pos.accuracy < 35.0) isGpsReady = true;
        _autoRecenterOnFirstGoodFix = false;
        onStateChanged();
        WidgetsBinding.instance.addPostFrameCallback((_) => centerMap(loc));
        debugPrint("Initial fix from cache: ${pos.accuracy}m");
      }

      // Start stream immediately — stream will set isGpsReady once accuracy < 35m
      startLocationTracking();
    } catch (e) {
      debugPrint("Error fetching initial location: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await ref.read(userRepositoryProvider).getProfile();
      _userWeightKg = 70.0;
      _userHeightCm = 170.0;
      _userAge = 30;
      _userGender = user.gender ?? 'male';
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    }
  }

  bool _startingLocationTracking = false;

  Future<void> startLocationTracking() async {
    // Prevent concurrent calls from racing and cancelling each other's stream
    if (_startingLocationTracking) return;
    if (positionStreamSubscription != null && !positionStreamSubscription!.isPaused) return;
    _startingLocationTracking = true;
    try {
      if (!context.mounted) return;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!context.mounted) return;
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (!context.mounted) return;
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      // Re-check: another call may have started the stream while we awaited above
      if (positionStreamSubscription != null && !positionStreamSubscription!.isPaused) {
        return;
      }

      await positionStreamSubscription?.cancel();
      positionStreamSubscription = null;

      // Never request permission here — only check. Permission must be requested
      // before startLocationTracking() is called (in the pre-run permission flow).
      // Requesting inside here causes "one set of permissions at a time" errors
      // when called concurrently, which crashes the geolocator service.

      final LocationSettings locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 1),
              useMSLAltitude: false,
            )
          : AppleSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              activityType: ActivityType.fitness,
              distanceFilter: 0,
              pauseLocationUpdatesAutomatically: false,
              // Required so GPS keeps streaming when the phone is locked or
              // the user switches apps mid-run. Pairs with the `location`
              // entry in UIBackgroundModes (Info.plist).
              allowBackgroundLocationUpdates: true,
              showBackgroundLocationIndicator: true,
            );

      positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _handlePositionUpdate(position);
        },
      );
    } catch (e) {
      debugPrint("Tracking engine error: $e");
    } finally {
      _startingLocationTracking = false;
    }
  }

  void _handlePositionUpdate(Position position) {
    if (!context.mounted) return;

    final newLatLng = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    final double previousAccuracy = currentAccuracy;
    currentAccuracy = position.accuracy;
    _accuracyHistory.add(position.accuracy);
    if (_accuracyHistory.length > 10) _accuracyHistory.removeAt(0);

    if (!isGpsReady && position.accuracy < 35.0) {
      isGpsReady = true;
      onStateChanged();
      debugPrint("GPS Ready: accuracy = ${position.accuracy}m");
    }

    // During idle/countdown: update display dot — but only with good fixes
    if (runningState == RunningState.idle ||
        runningState == RunningState.countdown) {
      // Reject bad fixes — don't let a coarse fix move the dot to a wrong place
      if (position.accuracy > 40.0) {
        onStateChanged(); // still refresh accuracy indicator
        return;
      }

      // Last 3 good fixes collect karo
      _recentIdleFixes.add(newLatLng);
      if (_recentIdleFixes.length > 3) _recentIdleFixes.removeAt(0);

      // Average nikalo — single drifted point ignore ho jaata hai
      final avgLat = _recentIdleFixes
          .map((p) => p.latitude)
          .reduce((a, b) => a + b) / _recentIdleFixes.length;
      final avgLng = _recentIdleFixes
          .map((p) => p.longitude)
          .reduce((a, b) => a + b) / _recentIdleFixes.length;
      final averaged = LatLng(avgLat, avgLng);

      // Accept if it's generally good accuracy, or if it didn't get severely worse
      final bool isBetterFix = previousAccuracy <= 0 || 
                               position.accuracy < 25.0 || 
                               position.accuracy <= previousAccuracy + 5.0;

      if (isBetterFix) {
        realGPSLocation = averaged;
        lastPosition = position;
        currentLocation = averaged;
        _smoothedDisplayLocation = averaged;
        _lastConfirmedLocation = averaged;
      }

      if (_autoRecenterOnFirstGoodFix && position.accuracy < 25.0) {
        _autoRecenterOnFirstGoodFix = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          centerMap(currentLocation);
        });
      }

      onStateChanged();
      return;
    }

    if (!_isValidGPSPoint(position, newLatLng, now)) {
      return;
    }

    if (runningState == RunningState.running && routePoints.length > 10) {
      _checkForGPSDrift(newLatLng);
    }

    _handlePotentialLostSignal();

    // FIX: always route through smoothing — never assign raw GPS to currentLocation directly
    realGPSLocation = newLatLng;
    lastPosition = position;
    currentLocation = _getSmoothedLocation(newLatLng);

    _handleIndoorTransition(position, newLatLng, now);

    if (runningState == RunningState.running) {
      _updateDistanceFromGPS(newLatLng, position, now);
    }
    // FIX: removed else { currentLocation = newLatLng }
    // idle & paused states now also benefit from smooth position above

    onStateChanged();
  }

  Future<void> prepareToRun() async {
    await checkBatteryOptimization();
    await ensureGoodGPSSignal();
  }

  bool _isValidGPSPoint(Position position, LatLng newLatLng, DateTime now) {
    if (position.accuracy > maxAccuracyMeters) {
      return false;
    }

    if (_lastValidPosition != null && _lastValidPositionTime != null) {
      final distanceMeters =
          distanceCalc.as(LengthUnit.Meter, _lastValidPosition!, newLatLng);
      final timeDelta = now.difference(_lastValidPositionTime!).inSeconds;

      if (timeDelta > 0 && timeDelta < 5) {
        final speedMS = distanceMeters / timeDelta;
        if (speedMS > maxRealisticSpeed) {
          debugPrint("Rejected unrealistic speed: ${speedMS.toStringAsFixed(1)} m/s");
          return false;
        }
      }


    }

    _lastValidPosition = newLatLng;
    _lastValidPositionTime = now;
    return true;
  }

  void _updateDistanceFromGPS(LatLng newLatLng, Position position, DateTime now) {
    // GPS warmup: ignore all counts for the first few seconds after run starts
    if (runStartTime != null &&
        now.difference(runStartTime!).inSeconds < gpsWarmupSeconds) {
      return;
    }

    bool isMoving = position.speed > minSpeedForMovement;

    if (position.speed > 0) {
      _lastValidSpeed = position.speed;
    }

    if (isMoving && position.accuracy <= maxAccuracyMeters) {
      _consecutiveMovingSamples++;
      if (_consecutiveMovingSamples >= requiredMovingSamples) {
        if (!_isActuallyMoving) {
          _isActuallyMoving = true;
          _wasStationaryReported = false;
          debugPrint(
              "REAL MOVEMENT CONFIRMED - speed: ${position.speed.toStringAsFixed(1)} m/s");
        }
        _lastMovementTime = now;
      }
    } else {
      _consecutiveMovingSamples = 0;
      if (_lastMovementTime != null &&
          now.difference(_lastMovementTime!) >
              Duration(seconds: stationaryTimeoutSeconds.toInt())) {
        if (_isActuallyMoving) {
          _isActuallyMoving = false;
          debugPrint(
              "STATIONARY DETECTED - no movement for ${stationaryTimeoutSeconds}s");
        }
      }
    }

    if (!_isActuallyMoving || position.accuracy > maxAccuracyMeters) {
      return;
    }

    // Visual map drawing isolated — use visual 'currentLocation' directly
    _addRoutePointIfNeeded(currentLocation);

    if (lastGPSPointTime == null) {
      lastGPSPointTime = now;
      return;
    }

    final timeDelta = now.difference(lastGPSPointTime!).inSeconds;
    if (timeDelta <= 0 || timeDelta > 5) {
      lastGPSPointTime = now;
      return;
    }

    // Median of last 3 speed readings — prevents a single noisy spike from inflating distance
    _recentSpeeds.add(position.speed);
    if (_recentSpeeds.length > 3) _recentSpeeds.removeAt(0);
    final smoothedSpeed = _median(_recentSpeeds);
    final speedDistance = smoothedSpeed * timeDelta;

    if (speedDistance >= 0.5 && speedDistance < 50) {
      _rawDistance += speedDistance;
      distance = _rawDistance / 1000.0;
      _movingSeconds += timeDelta;
      lastGPSPointTime = now;

      _totalSinceLastHeading += speedDistance;
      if (_totalSinceLastHeading >= headingUpdateThreshold &&
          _headingPoints.length >= 2) {
        _updateHeading();
        _totalSinceLastHeading = 0;
        _headingPoints.clear();
        _headingPoints.add(newLatLng);
      }

      _updatePaceWithRealData();
      _updateCalories();
      _updateStepsEstimate();
      _updatePoints();
      _checkAndAnnounceKilometer();

      if (routePoints.length % 5 == 0) {
        _savePendingRun();
      }

      onStateChanged();
    } else {
      lastGPSPointTime = now; 
    }
  }

  void _addRoutePointIfNeeded(LatLng mapPoint) {
    if (routePoints.isEmpty) {
      routePoints.add(mapPoint);
      routePointTimes.add(DateTime.now());
      routePointDistances.add(0.0);
      startLocation = mapPoint;
      _rawPoints.add(mapPoint);
      _headingPoints.add(mapPoint);
      debugPrint("First route point added");
      onStateChanged();
      return;
    }

    final distFromLast = _calculateHaversineDistance(routePoints.last, mapPoint);
    
    if (distFromLast > 4.0 && distFromLast < 50.0) {
      if (routePoints.length >= 2 && distFromLast < 10.0) {
        final bearing = _calculateBearing(routePoints[routePoints.length - 2], routePoints.last);
        final newBearing = _calculateBearing(routePoints.last, mapPoint);
        double diff = (newBearing - bearing).abs();
        if (diff > 180) diff = 360 - diff;
        if (diff > 90) return;
      }

      routePoints.add(mapPoint);
      routePointTimes.add(DateTime.now());
      routePointDistances.add(distance);
      _rawPoints.add(mapPoint);

      if (_headingPoints.isEmpty || _headingPoints.last != mapPoint) {
        _headingPoints.add(mapPoint);
      }
      if (_headingPoints.length >= 2) _updateHeading();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // centerMap is safe from map controller if auto follows
        if (isAutoFollow) centerMap(currentLocation);
      });
    }
  }

  double getDisplayHeading(Position? currentPosition) {
    if (routePoints.length >= 2) {
      final p1 = routePoints[routePoints.length - 2];
      final p2 = routePoints[routePoints.length - 1];

      final dist = _calculateHaversineDistance(p1, p2);
      if (dist > 0.5) {
        final calculatedHeading = _calculateBearing(p1, p2);
        if (calculatedHeading >= 0 && !calculatedHeading.isNaN) {
          return calculatedHeading;
        }
      }
    }

    if (_currentHeading > 0 && !_currentHeading.isNaN) {
      return _currentHeading;
    }

    if (currentPosition != null && currentPosition.heading >= 0) {
      return currentPosition.heading;
    }

    return 0.0;
  }

  String getGPSStatusMessage() {
    if (_isIndoorMode) return "📍 Indoor Mode - Limited Accuracy";
    if (currentAccuracy > 35.0) return "⚠️ Weak GPS Signal";
    if (currentAccuracy > 20.0) return "🟡 GPS Okay";
    return "🟢 GPS Good";
  }

  Color getGPSStatusColor() {
    if (_isIndoorMode) return Colors.blue;
    if (currentAccuracy > 35.0) return Colors.red;
    if (currentAccuracy > 20.0) return Colors.orange;
    return Colors.green;
  }

  double getArrowRotation(Position? currentPosition) {
    final heading = getDisplayHeading(currentPosition);
    return heading * math.pi / 180;
  }

  bool get shouldShowArrow {
    return runningState == RunningState.running ||
        runningState == RunningState.countdown ||
        runningState == RunningState.finished ||
        (runningState == RunningState.paused && routePoints.isNotEmpty);
  }

  String getFormattedAccuracy() {
    if (currentAccuracy <= 0) return "---";
    return "${currentAccuracy.toInt()}m";
  }

  // ─── Strava Advanced GPS Methods ───────────────────────────────────────────

  Future<void> ensureGoodGPSSignal() async {
    if (!isGpsReady) {
      int attempts = 0;
      while (!isGpsReady && attempts < 15) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
        if (lastPosition != null && lastPosition!.accuracy < 20.0) {
          isGpsReady = true;
          break;
        }
      }

      // no GPS status announcements
    }
  }

  Future<void> performAGPSReset() async {
    await Geolocator.openLocationSettings();
  }

  double _calculatePathDeviation(LatLng newPoint) {
    if (routePoints.length < 3) return 0.0;

    final p0 = routePoints[routePoints.length - 2];
    final last = routePoints.last;

    double lastBearing = _calculateBearing(p0, last);
    double lastDist = _calculateHaversineDistance(p0, last);

    LatLng projected = _calculateDestinationPoint(last, lastBearing, lastDist);

    return _calculateHaversineDistance(projected, newPoint);
  }

  void _checkForGPSDrift(LatLng newPoint) {
    double deviation = _calculatePathDeviation(newPoint);
    if (deviation > 40.0) {
      if (!_driftWarningShown) {
        _driftWarningShown = true;
        Timer(const Duration(minutes: 5), () => _driftWarningShown = false);
      }
      debugPrint(
          "⚠️ Potential GPS Drift detected: ${deviation.toStringAsFixed(1)}m");
    }
  }

  LatLng _calculateDestinationPoint(
      LatLng start, double bearing, double distance) {
    const double R = 6371000;
    double b = bearing * math.pi / 180;
    double lat1 = start.latitude * math.pi / 180;
    double lon1 = start.longitude * math.pi / 180;

    double lat2 = math.asin(math.sin(lat1) * math.cos(distance / R) +
        math.cos(lat1) * math.sin(distance / R) * math.cos(b));
    double lon2 = lon1 +
        math.atan2(
            math.sin(b) * math.sin(distance / R) * math.cos(lat1),
            math.cos(distance / R) - math.sin(lat1) * math.sin(lat2));

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  void _handlePotentialLostSignal() {
    if (runningState == RunningState.running && !_isActuallyMoving) {
      if (_lostSignalTimer == null) {
        _lostSignalTimer = Timer(const Duration(seconds: 15), () {
          // no GPS status announcement
        });
      }
    } else {
      _lostSignalTimer?.cancel();
      _lostSignalTimer = null;
    }
  }

  Future<void> checkBatteryOptimization() async {
    if (Platform.isAndroid && !_batteryOptimizationChecked) {
      _batteryOptimizationChecked = true;
      final prefs = await SharedPreferences.getInstance();
      bool prompted = prefs.getBool('battery_optimization_prompted') ?? false;

      if (!prompted) {
        await prefs.setBool('battery_optimization_prompted', true);
      }
    }
  }

  void _handleIndoorTransition(
      Position position, LatLng newLatLng, DateTime now) {
    final bool wasIndoor = _isIndoorMode;
    _isIndoorMode = position.accuracy > maxAccuracyMeters;

    if (!wasIndoor && _isIndoorMode && runningState == RunningState.running) {
      debugPrint("🏠 INDOOR DETECTED - Accuracy: ${position.accuracy}m");
      _poorAccuracyCount = 0;
    }

    if (wasIndoor && !_isIndoorMode && runningState == RunningState.running) {
      debugPrint(
          "🌤️ OUTDOOR DETECTED - Accuracy restored to ${position.accuracy}m");

      _isActuallyMoving = true;
      _consecutiveMovingSamples = requiredMovingSamples;
      _poorAccuracyCount = 0;
    }

    if (position.accuracy > maxAccuracyMeters) {
      _poorAccuracyCount++;
      if (_poorAccuracyCount > 10 && _poorAccuracyCount % 20 == 0) {
        debugPrint("⚠️ Weak GPS signal: ${position.accuracy.toInt()}m");
      }
    } else {
      _poorAccuracyCount = 0;
      _lastGoodGPSPoint = now;
    }
  }

  void _updateHeading() {
    if (_headingPoints.length < 2) return;

    final p1 = _headingPoints[_headingPoints.length - 2];
    final p2 = _headingPoints[_headingPoints.length - 1];

    double newBearing = _calculateBearing(p1, p2);

    if (_currentHeading == 0) {
      _currentHeading = newBearing;
    } else {
      double diff = newBearing - _currentHeading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      _currentHeading = (_currentHeading + (diff * 0.8)) % 360;
    }

    debugPrint("Heading updated: ${_currentHeading.toStringAsFixed(1)}°");
  }

  void forceStopTracking() {
    _isActuallyMoving = false;
    _consecutiveMovingSamples = 0;
    _lastMovementTime = null;
    _wasStationaryReported = false;
  }

  double _calculateBearing(LatLng p1, LatLng p2) {
    final double lat1 = p1.latitude * math.pi / 180;
    final double lon1 = p1.longitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lon2 = p2.longitude * math.pi / 180;

    final double dLon = lon2 - lon1;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  double _calculateHaversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000;
    final double lat1 = p1.latitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double deltaLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final double deltaLon = (p2.longitude - p1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  void _updatePaceWithRealData() {
    if (distance <= 0 || seconds <= 0 || routePointDistances.length < 2) {
      currentPace = 0.0;
      avgPace = 0.0;
      return;
    }

    avgPace = (_movingSeconds / 60.0) / distance;

    final now = DateTime.now();
    // FIX: wider pace window for walkers
    final windowSeconds =
        (_lastValidSpeed < 1.5) ? 60 : (_lastValidSpeed < 2.5) ? 30 : 15;
    final cutoffTime = now.subtract(Duration(seconds: windowSeconds));

    int startIndex = -1;
    for (int i = routePointTimes.length - 1; i >= 0; i--) {
      if (routePointTimes[i].isBefore(cutoffTime)) {
        startIndex = i;
        break;
      }
    }

    if (startIndex != -1 && startIndex < routePointDistances.length - 1) {
      double startDist = -1.0;
      for (int i = startIndex; i >= 0; i--) {
        if (routePointDistances[i] >= 0) {
          startDist = routePointDistances[i];
          break;
        }
      }

      if (startDist >= 0) {
        final distDiff = distance - startDist;
        final timeDiffSeconds =
            now.difference(routePointTimes[startIndex]).inSeconds;

        if (distDiff > 0.005 && timeDiffSeconds > 5) {
          final pace = (timeDiffSeconds / 60.0) / distDiff;
          // FIX: 30 min/km covers slow walking (was 20.0)
          if (pace > 2.0 && pace < 30.0) {
            currentPace = pace;
          } else if (currentPace == 0 && avgPace > 2.0 && avgPace < 30.0) {
            currentPace = avgPace;
          }
        }
      }
    } else if (currentPace == 0 && avgPace > 2.0 && avgPace < 30.0) {
      currentPace = avgPace;
    }

    // FIX: safety check updated to 30.0 for walking support
    if (currentPace.isNaN ||
        currentPace.isInfinite ||
        currentPace < 2.0 ||
        currentPace > 30.0) {
      if (avgPace > 2.0 && avgPace < 30.0) currentPace = avgPace;
    }

    onStateChanged();
  }

  void _updateCalories() {
    if (_movingSeconds <= 0) return;

    final timeHours = _movingSeconds / 3600.0;

    // Keytel (2005) heart rate formula — more accurate when HR is available
    if (avgBpm > 40 && avgBpm < 220) {
      final isMale = _userGender.toLowerCase() == 'male';
      final hrCalories = isMale
          ? ((_userAge * 0.2017) - (_userWeightKg * 0.09036) +
                 (avgBpm * 0.6309) - 55.0969) *
              (timeHours * 60.0) / 4.184
          : ((_userAge * 0.074) - (_userWeightKg * 0.05741) +
                 (avgBpm * 0.4472) - 20.4022) *
              (timeHours * 60.0) / 4.184;
      if (hrCalories > 0) {
        calories = hrCalories;
        return;
      }
    }

    // Fallback: MET table when heart rate is not available
    if (distance <= 0) return;
    final metValue = _calculateMETValue();
    final caloriesFromActivity = metValue * _userWeightKg * timeHours;
    final bmrPerHour = _calculateBMR() / 24.0;
    calories = caloriesFromActivity + (bmrPerHour * timeHours);
  }

  double _calculateMETValue() {
    final speedKmph = _lastValidSpeed * 3.6;
    if (speedKmph <= 0) {
      if (distance <= 0 || seconds <= 0) return 0.0;
      final speed = distance / (seconds / 3600.0);
      return _metFromSpeed(speed);
    }
    return _metFromSpeed(speedKmph);
  }

  double _metFromSpeed(double speedKmph) {
    if (speedKmph < 6.0) return 6.0;
    if (speedKmph < 8.0) return 8.0;
    if (speedKmph < 8.6) return 9.0;
    if (speedKmph < 9.7) return 10.0;
    if (speedKmph < 10.8) return 11.0;
    if (speedKmph < 11.3) return 11.5;
    if (speedKmph < 12.1) return 12.0;
    if (speedKmph < 12.9) return 12.5;
    if (speedKmph < 13.8) return 13.0;
    if (speedKmph < 14.5) return 14.0;
    if (speedKmph < 16.1) return 15.0;
    return 16.0;
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double _calculateBMR() {
    if (_userGender.toLowerCase() == 'male') {
      return (10 * _userWeightKg) + (6.25 * _userHeightCm) - (5 * _userAge) + 5;
    } else {
      return (10 * _userWeightKg) +
          (6.25 * _userHeightCm) -
          (5 * _userAge) -
          161;
    }
  }

  void _updateStepsEstimate() {
    // Real hardware steps from Health Connect take priority
    if (healthSteps > 0) {
      steps = healthSteps;
      return;
    }

    if (_lastValidSpeed <= 0) return;

    final speedKmph = _lastValidSpeed * 3.6;

    // Research-based cadence midpoints (steps per minute), interpolated
    double cadencePerMinute;
    if (speedKmph < 4.0) {
      cadencePerMinute = 115;
    } else if (speedKmph < 6.0) {
      cadencePerMinute = 115 + ((speedKmph - 4.0) / 2.0) * 15; // 115→130
    } else if (speedKmph < 8.0) {
      cadencePerMinute = 130 + ((speedKmph - 6.0) / 2.0) * 30; // 130→160
    } else if (speedKmph < 10.0) {
      cadencePerMinute = 160 + ((speedKmph - 8.0) / 2.0) * 15; // 160→175
    } else {
      cadencePerMinute = 175 + ((speedKmph - 10.0) / 2.0) * 10; // 175→185+
    }

    // Use total seconds for step base — movingSeconds alone underestimates
    // because GPS warmup and median buffer miss real steps at burst starts
    final effectiveSeconds = math.max(_movingSeconds, seconds ~/ 2);
    steps = ((effectiveSeconds / 60.0) * cadencePerMinute).round();
  }

  void _updatePoints() {
    earnedPoints = distance * 10.0;
    if (currentPace > 0 && currentPace < 5.0) {
      earnedPoints += distance * 2.0;
    }
  }

  void _checkAndAnnounceKilometer() {
    final currentKm = distance.floor();
    if (currentKm > lastKmAnnounced && currentKm > 0) {
      lastKmAnnounced = currentKm;
      _announceKilometer(currentKm);
    }
  }

  void _announceKilometer(int km) {
    if (!context.mounted) return;
    final paceMinutes = avgPace.floor();
    final paceSeconds = ((avgPace - paceMinutes) * 60).toInt();
    final paceStr = "$paceMinutes:${paceSeconds.toString().padLeft(2, '0')}";

    final isAr = ref.read(localeProvider).languageCode == 'ar';
    const arNums = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة'];
    String arKm(int k) => k >= 1 && k <= 10 ? arNums[k] : '$k';
    switch (km) {
      case 1:
        speak(isAr
            ? "الكيلومتر الأول، الإيقاع $paceStr لكل كيلومتر"
            : "First kilometer, pace $paceStr per kilometer");
        break;
      case 5:
        speak(isAr
            ? "${arKm(km)} كيلومتر مكتملة، أحسنت! الإيقاع $paceStr"
            : "$km kilometers completed, Keep it up! Pace $paceStr");
        break;
      case 10:
        speak(isAr
            ? "${arKm(km)} كيلومتر مكتملة، إيقاع رائع! $paceStr لكل كيلومتر"
            : "$km kilometers completed, Great pace! $paceStr per kilometer");
        break;
      default:
        if (km % 5 == 0) {
          speak(isAr
              ? "${arKm(km)} كيلومتر مكتملة، ركض قوي! الإيقاع $paceStr"
              : "$km kilometers completed, Strong running! Pace $paceStr");
        } else {
          speak(isAr
              ? "${arKm(km)} كيلومتر، الإيقاع $paceStr"
              : "$km kilometers, pace $paceStr");
        }
    }
  }

  void _fitMapToRoute() {
    if (routePoints.isEmpty) return;
    final padding = getMapPadding();
    final points = List<LatLng>.from(routePoints);
    if (currentLocation != points.last) {
      points.add(currentLocation);
    }
    try {
      mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: padding,
          maxZoom: 18.8,
          forceIntegerZoomLevel: false,
        ),
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Run State Persistence
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _savePendingRun() async {
    if (_isSaving) return;
    if (runningState != RunningState.running &&
        runningState != RunningState.paused) return;
    _isSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'distance': distance,
        'seconds': seconds,
        'calories': calories,
        'steps': steps,
        'avgPace': avgPace,
        'avgBpm': avgBpm,
        'startTime': runStartTime?.toIso8601String(),
        'runningState': runningState.index,
        'activityType': activityType,
        'routePoints': routePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'routePointTimes':
            routePointTimes.map((t) => t.toIso8601String()).toList(),
        'routePointDistances': routePointDistances,
      };
      await prefs.setString('current_run_state', jsonEncode(data));
      debugPrint("Activity auto-saved");
    } catch (e) {
      debugPrint("Auto-save error: $e");
    } finally {
      _isSaving = false;
    }
  }

  Future<void> loadPendingRun(
      Future<bool?> Function() showResumeDialog, {
      void Function(String)? onActivityTypeRestored,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('current_run_state');
    if (json == null) return;
    try {
      final data = jsonDecode(json);
      final int stateIndex = data['runningState'];
      final state = RunningState.values[stateIndex];
      if (!context.mounted) return;
      final resume = await showResumeDialog();
      if (resume == true) {
        distance = data['distance'] ?? 0.0;
        _rawDistance = distance * 1000;
        seconds = data['seconds'] ?? 0;
        calories = data['calories'] ?? 0.0;
        steps = data['steps'] ?? 0;
        avgPace = data['avgPace'] ?? 0.0;
        avgBpm = data['avgBpm'] ?? 0.0;
        activityType = data['activityType'] ?? 'run';
        onActivityTypeRestored?.call(activityType);
        runStartTime = data['startTime'] != null
            ? DateTime.parse(data['startTime'])
            : null;
        final List<dynamic> points = data['routePoints'] ?? [];
        routePoints.clear();
        _rawPoints.clear();
        for (var p in points) {
          final point = LatLng(p['lat'], p['lng']);
          routePoints.add(point);
          _rawPoints.add(point);
        }
        final List<dynamic> times = data['routePointTimes'] ?? [];
        routePointTimes.clear();
        for (var t in times) {
          routePointTimes.add(DateTime.parse(t));
        }
        routePointDistances.clear();
        routePointDistances
            .addAll(List<double>.from(data['routePointDistances'] ?? []));
        if (routePoints.isNotEmpty) {
          startLocation = routePoints.first;
          // Restore smoothed position to last known route point
          _smoothedDisplayLocation = routePoints.last;
          _lastConfirmedLocation = routePoints.last;
        }
        await _loadUserProfile();
        if (state == RunningState.paused) {
          runningState = RunningState.paused;
        } else {
          runningState = RunningState.running;
          _startTimer();
          startLocationTracking();
        }
        onStateChanged();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapToRoute();
        });
      } else {
        await _clearPendingRun();
      }
    } catch (e) {
      debugPrint("Error loading pending run: $e");
      await _clearPendingRun();
    }
  }

  Future<void> _clearPendingRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_run_state');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Run Control
  // ─────────────────────────────────────────────────────────────────────────

  void startCountdown() {
    runningState = RunningState.countdown;
    countdownSeconds = 3;
    onStateChanged();

    // Use the 3-second countdown window to get a fresh GPS fix
    _getFreshGPSBeforeRun();

    final isAr = ref.read(localeProvider).languageCode == 'ar';
    speak(isAr ? "ثلاثة" : "3", force: true);
    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!context.mounted) {
        timer.cancel();
        return;
      }
      if (countdownSeconds > 1) {
        countdownSeconds--;
        onStateChanged();
        final isArNow = ref.read(localeProvider).languageCode == 'ar';
        const arWords = ["صفر", "واحد", "اثنان", "ثلاثة"];
        speak(isArNow ? arWords[countdownSeconds] : countdownSeconds.toString(), force: true);
      } else {
        timer.cancel();
        speak(AppLocalizations.of(context)!.go, force: true);
        startRun();
      }
    });
  }

  void _getFreshGPSBeforeRun() {
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 4),
      ),
    ).then((pos) {
      if (!context.mounted) return;
      if (pos.accuracy < 40.0) {
        final loc = LatLng(pos.latitude, pos.longitude);
        realGPSLocation = loc;
        currentLocation = loc;
        _smoothedDisplayLocation = loc;
        _lastConfirmedLocation = loc;
        lastPosition = pos;
        currentAccuracy = pos.accuracy;
        isGpsReady = true;
        onStateChanged();
        debugPrint("✅ Fresh GPS before run: ${pos.accuracy}m");
      }
    }).ignore();
  }

  void startRun() {
    if (runningState == RunningState.idle ||
        runningState == RunningState.countdown) {
      startLocation = realGPSLocation ?? currentLocation;
      routePoints.clear();
      routePointTimes.clear();
      routePointDistances.clear();
      _rawPoints.clear();
      _headingPoints.clear();

      seconds = 0;
      distance = 0.0;
      _rawDistance = 0.0;
      calories = 0.0;
      avgPace = 0.0;
      currentPace = 0.0;
      lastKmAnnounced = 0;
      runStartTime = DateTime.now();
      lastGPSPointTime = null;

      _totalBpmSum = 0.0;
      _bpmReadingCount = 0;
      avgBpm = 0.0;
      healthSteps = 0;
      steps = 0;
      _movingSeconds = 0;
      _recentSpeeds.clear();
      forceStopTracking();
      _currentHeading = 0.0;
      _totalSinceLastHeading = 0.0;
      _accuracyHistory.clear();
      _poorAccuracyCount = 0;

      // FIX: reset smooth display position to current location on each new run
      _smoothedDisplayLocation = realGPSLocation ?? currentLocation;
      _lastConfirmedLocation = null;

      if (currentAccuracy > maxAccuracyMeters) {
        _isIndoorMode = true;
      } else {
        _isIndoorMode = false;
      }
    }
    runningState = RunningState.running;
    onStateChanged();

    // Start lock screen notification + listen for Pause/Finish actions
    _lockScreenActionSub?.cancel();
    lockScreenService.start(stats: _currentStats(paused: false));
    _lockScreenActionSub = lockScreenService.actionStream.listen((action) {
      if (!context.mounted) return;
      if (action == 'pause') pauseRun();
      if (action == 'resume') resumeRun();
      if (action == 'finish') finishRun();
    });

    // Add anchor point immediately so line exists from second 0
    if (routePoints.isEmpty && startLocation != null) {
      routePoints.add(startLocation!);
      routePointTimes.add(DateTime.now());
      routePointDistances.add(0.0);
      _rawPoints.add(startLocation!);
    }

    startLocationTracking();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (startLocation != null) {
        centerMap(startLocation!);
      }
    });
  }

  void pauseRun() {
    runningState = RunningState.paused;
    onStateChanged();
    _stopTimer();
    lockScreenService.update(stats: _currentStats(paused: true));
    speak(AppLocalizations.of(context)!.paused);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute();
    });
  }

  Future<void> finishRun() async {
    runningState = RunningState.finished;
    onStateChanged();
    _stopTimer();
    lockScreenService.stop();
    _lockScreenActionSub?.cancel();
    _lockScreenActionSub = null;
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null;
    forceStopTracking();

    _applyPostRunSmoothing();

    // Removed the minimum distance check to always save the run as requested.

    final isAr = ref.read(localeProvider).languageCode == 'ar';
    final distStr = distance.toStringAsFixed(1);
    if (distance >= 10) {
      speak(isAr
          ? 'اكتملت الجولة، جهد رائع! $distStr كيلومتر'
          : 'Run complete, Amazing effort! $distStr kilometers');
    } else if (distance >= 5) {
      speak(isAr
          ? 'اكتملت الجولة، عمل رائع! $distStr كيلومتر'
          : 'Run complete, Great job! $distStr kilometers');
    } else {
      speak(isAr
          ? 'اكتملت الجولة، أحسنت! $distStr كيلومتر'
          : 'Run complete, Well done! $distStr kilometers');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToRoute();
    });
    await _saveActivity();
    runStartTime = null;
    // Stats are preserved here so _buildSummaryView can display them.
    // resetToIdle() clears them when the user starts a new run.
  }

  void resetToIdle() {
    _resetForNewRun();
    runningState = RunningState.idle;
    onStateChanged();
  }

  void _applyPostRunSmoothing() {
    if (_rawPoints.length < 3) return;

    final List<double> segments = [];
    for (int i = 1; i < _rawPoints.length; i++) {
      final dist =
          _calculateHaversineDistance(_rawPoints[i - 1], _rawPoints[i]);
      segments.add(dist);
    }

    if (segments.isEmpty) return;

    final mean = segments.reduce((a, b) => a + b) / segments.length;
    final variance = segments
            .map((d) => math.pow(d - mean, 2))
            .reduce((a, b) => a + b) /
        segments.length;
    final stdDev = math.sqrt(variance);

    double smoothedDistance = 0;
    for (int i = 1; i < _rawPoints.length; i++) {
      final dist =
          _calculateHaversineDistance(_rawPoints[i - 1], _rawPoints[i]);
      if (dist <= mean + (2.5 * stdDev)) {
        smoothedDistance += dist;
      }
    }

    final maxReduction = _rawDistance * 0.97;
    _rawDistance = math.max(smoothedDistance, maxReduction);
    distance = _rawDistance / 1000.0;

    if (_movingSeconds > 0 && distance > 0) {
      avgPace = (_movingSeconds / 60.0) / distance;
    }
  }

  void _startTimer() {
    runStartTime ??= DateTime.now();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (runningState == RunningState.running) {
        seconds++;
        _updatePaceWithRealData();
        _updateCalories();
        onStateChanged();
        if (seconds % 5 == 0) {
          lockScreenService.update(stats: _currentStats(paused: false));
        }
        if (seconds % 10 == 0) {
          _savePendingRun();
        }
      }
    });
  }

  void resumeRun() {
    runningState = RunningState.running;
    onStateChanged();
    lockScreenService.update(stats: _currentStats(paused: false));
    // GPS stream is never paused now — just ensure it's running
    if (positionStreamSubscription == null) {
      startLocationTracking();
    }
    _startTimer();
  }

  void _stopTimer() {
    timer?.cancel();
    // Do NOT pause the GPS stream — Android foreground service keeps it alive in background
  }

  Future<void> _saveActivity() async {
    if (!context.mounted) return;

    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: activityType,
      distance: distance,
      duration: seconds,
      calories: calories,
      averagePace: avgPace,
      averageBPM: avgBpm,
      date: DateTime.now(),
    );

    try {
      if (isHealthConnected && startLocation != null) {
        final healthRepo = ref.read(healthRepositoryProvider);
        final endTime = DateTime.now();
        final startTime =
            runStartTime ?? endTime.subtract(Duration(seconds: seconds));
        await healthRepo.saveRunToHealth(
          startTime: startTime,
          endTime: endTime,
          totalDistanceMeters: distance * 1000,
          totalEnergyBurned: calories,
          totalSteps: steps,
          averageHeartRate: avgBpm,
          averagePace: avgPace,
          floorsClimbed: 0,
        );
      }

      await ref.read(activityRepositoryProvider).logActivity(activity);
      ref.read(realTimeNotificationServiceProvider).showInAppBanner(
        'Activity Saved!',
        '${distance.toStringAsFixed(2)} km • $steps steps • ${calories.toInt()} cal',
        showAlert: false,
        showSnackBar: true,
        force: true,
      );
      await _clearPendingRun();
      ref
          .read(challengeRepositoryProvider)
          .updateAllChallengesProgress(
            distanceKm: distance,
            durationSeconds: seconds,
            calories: calories,
          )
          .catchError(
              (e) => debugPrint('Challenge progress update error: $e'));
      ref.invalidate(activityListProvider);
      ref.invalidate(activityStatsProvider('week'));
      ref.invalidate(activityStatsProvider('month'));
      ref.invalidate(activitySummaryProvider('week'));
      ref.invalidate(activitySummaryProvider('month'));
      ref.invalidate(userProfileProvider);
      ref.invalidate(challengesListProvider);
    } catch (e) {
      debugPrint('Error saving activity: $e');
    }
  }

  WorkoutStats _currentStats({required bool paused}) => WorkoutStats(
    elapsedSeconds: seconds,
    distanceKm: distance,
    pacePerKm: currentPace,
    calories: calories,
    steps: displaySteps,
    isPaused: paused,
    workoutType: 'running',
  );

  String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String formatPace(double pace) {
    if (pace <= 0 || pace.isInfinite || pace.isNaN) return '--:--';
    final minutes = pace.toInt();
    final secs = ((pace - minutes) * 60).toInt();
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  double getButtonTopOffset() {
    switch (runningState) {
      case RunningState.idle:
        return -40.0;
      case RunningState.running:
        return -40.0;
      case RunningState.paused:
        return -20.0;
      case RunningState.finished:
        return 0.0;
      case RunningState.countdown:
        return -40.0;
    }
  }

  void toggleAutoFollow() {
    isAutoFollow = true;
    centerMap(currentLocation);
  }

  void locateMe() {
    isAutoFollow = true;

    // Fresh one-shot fix — stream ki cached position pe trust mat karo
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 6),
      ),
    ).then((pos) {
      if (!context.mounted) return;
      if (pos.accuracy > 40.0) return; // coarse fix — reject

      final loc = LatLng(pos.latitude, pos.longitude);
      realGPSLocation = loc;
      currentLocation = loc;
      _smoothedDisplayLocation = loc;
      _lastConfirmedLocation = loc;
      currentAccuracy = pos.accuracy;
      onStateChanged();
      centerMap(loc);
      debugPrint("locateMe fresh fix: ${pos.accuracy}m");
    }).catchError((_) {
      // Fallback to stream position if fresh fix fails
      final loc = realGPSLocation ?? currentLocation;
      centerMap(loc);
    });
  }

  Future<String> getCityName(LatLng point) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': point.latitude,
          'lon': point.longitude,
          'zoom': 10,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'TrydApp/1.0'}),
      );
      if (response.data != null && response.data['address'] != null) {
        final address = response.data['address'];
        return address['city'] ??
            address['town'] ??
            address['suburb'] ??
            address['state'] ??
            "Unknown Location";
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return "Unknown Location";
  }

  Future<HealthSetupStatus> checkHealthSetup() async {
    try {
      final healthRepo = ref.read(healthRepositoryProvider);
      return await healthRepo.getSetupStatus();
    } catch (e) {
      debugPrint('Health setup check error: $e');
      return HealthSetupStatus.notInstalled;
    }
  }

  Future<void> initializeHealthConnect() async {
    try {
      final healthRepo = ref.read(healthRepositoryProvider);
      final status = await healthRepo.getSetupStatus();

      if (status != HealthSetupStatus.ready) {
        debugPrint('Health Connect not ready: $status');
        isHealthConnected = false;
        return;
      }

      await stepsStreamSubscription?.cancel();
      await heartRateSubscription?.cancel();
      await caloriesStreamSubscription?.cancel();

      stepsStreamSubscription =
          healthRepo.getRealtimeSteps().listen((stepDelta) {
        if (runningState == RunningState.running) {
          healthSteps += stepDelta;
          onStateChanged();
        }
      });

      heartRateSubscription =
          healthRepo.getRealtimeHeartRate().listen((heartRate) {
        if (runningState == RunningState.running && heartRate > 0) {
          _totalBpmSum += heartRate;
          _bpmReadingCount++;
          avgBpm = _totalBpmSum / _bpmReadingCount;
          onStateChanged();
        }
      });

      caloriesStreamSubscription =
          healthRepo.getRealtimeCalories().listen((calorieDelta) {
        if (runningState == RunningState.running) {
          onStateChanged();
        }
      });

      isHealthConnected = true;
      debugPrint("Health Connect initialized successfully");
    } catch (e) {
      debugPrint("Error initializing Health Connect: $e");
      isHealthConnected = false;
    }
  }

  int get displaySteps {
    if (isHealthConnected && healthSteps > 0) {
      return healthSteps;
    }
    return steps;
  }

  void _resetForNewRun() {
    _recentIdleFixes.clear(); // ← ADD
    routePoints.clear();
    routePointTimes.clear();
    routePointDistances.clear();
    _rawPoints.clear();
    _headingPoints.clear();

    seconds = 0;
    distance = 0.0;
    _rawDistance = 0.0;
    calories = 0.0;
    avgPace = 0.0;
    currentPace = 0.0;
    earnedPoints = 0.0;
    lastKmAnnounced = 0;
    steps = 0;
    healthSteps = 0;
    avgBpm = 0.0;
    _totalBpmSum = 0.0;
    _bpmReadingCount = 0;

    startLocation = null;
    lastGPSPointTime = null;
    _lastValidPosition = null;
    _lastValidPositionTime = null;
    _lastValidSpeed = 0.0;
    _currentHeading = 0.0;
    _totalSinceLastHeading = 0.0;
    _accuracyHistory.clear();
    _poorAccuracyCount = 0;
    forceStopTracking();

    _lastConfirmedLocation = null;
    debugPrint("Reset complete — ready for new run");
  }

  void dispose() {
    timer?.cancel();
    countdownTimer?.cancel();
    _lostSignalTimer?.cancel();
    autoFollowResumeTimer?.cancel();
    positionStreamSubscription?.cancel();
    stepsStreamSubscription?.cancel();
    caloriesStreamSubscription?.cancel();
    heartRateSubscription?.cancel();
    _lockScreenActionSub?.cancel();
    lockScreenService.dispose();
    mapController.dispose();
    sheetController.dispose();
  }
}
