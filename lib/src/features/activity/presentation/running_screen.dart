import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/activity_repository.dart';
import '../domain/activity.dart';
import '../../../../../widgets/custom_bottom_navigation.dart';
import '../../../../../widgets/gradient_button.dart';
import '../../home/presentation/home_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import 'workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import 'activity_screen.dart';
import '../../challenges/data/challenge_repository.dart';
import '../data/health_repository.dart';
import 'package:health/health.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import '../../profile/data/user_repository.dart';

enum RunningState { idle, countdown, running, paused, finished }

class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> {
  int _selectedIndex = 1;
  RunningState _runningState = RunningState.idle;
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  LatLng _currentLocation = const LatLng(29.2882, 47.9015);
  LatLng? _startLocation;
  final List<LatLng> _routePoints = [];
  
  // Real stats
  Timer? _timer;
  int _seconds = 0;
  double _distance = 0.0;
  double _calories = 0.0;
  int _steps = 0;
  double _avgPace = 0.0;
  double _currentPace = 0.0;
  double _avgBpm = 0.0;
  final Distance _distanceCalc = const Distance();
  bool _isHealthConnected = false;
  DateTime? _runStartTime;
  StreamSubscription<Position>? _positionStreamSubscription;
  double? _latOffset;
  double? _lngOffset;
  LatLng? _realGPSLocation;
  
  // Countdown
  Timer? _countdownTimer;
  int _countdownSeconds = 3;

  // Live Motion / Auto-Pause
  bool _isAutoPaused = false;
  final List<double> _recentSpeeds = []; 
  static const int _speedBufferSize = 5;
  static const double _autoPauseThreshold = 1.0; // m/s (~3.6 km/h) - Adjustable
  static const double _autoResumeThreshold = 1.5; // m/s (~5.4 km/h)
  
  // Sheet Heights
  static const double _sheetHeightIdle = 0.75;
  static const double _sheetHeightRunning = 0.50; // Updated to 50%
  static const double _sheetHeightMin = 0.40;

  // Audio
  final FlutterTts _flutterTts = FlutterTts();
  int _lastKmAnnounced = 0;

  // Pace Coloring
  final List<Color> _routeColors = [];
  bool _isMusicPlaying = false;
  bool _isMusicMuted = false;
  
  // Local Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  int _currentSongIndex = 0;
  bool _hasAudioPermission = false;
  DateTime? _lastPersistTime;
  int _autoPauseConfidenceCount = 0; // Confidence check for auto-pause

  @override
  void initState() {
    super.initState();
    _initHealth();
    _initTts();
    _initMusic();
    _fetchInitialLocation();
    _checkPendingRun();
  }
  
  Future<void> _initMusic() async {
    try {
      bool permissionGranted = false;
      if (Platform.isAndroid) {
        // Precise Android permission handling
        if (await Permission.audio.request().isGranted) {
           permissionGranted = true;
        } else if (await Permission.storage.request().isGranted) {
           permissionGranted = true;
        }
      } else {
        permissionGranted = await Permission.storage.request().isGranted;
      }

      if (permissionGranted) {
        _hasAudioPermission = true;
        final songs = await _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        
        if (songs.isNotEmpty) {
          setState(() {
            _songs = songs;
            _currentSongIndex = 0;
          });
          await _loadSong();
        }
      }
    } catch (e) {
      debugPrint("Audio Init Error: $e");
    }
  }
  
  Future<void> _loadSong() async {
    if (_songs.isEmpty) return;
    try {
      final String? songUri = _songs[_currentSongIndex].uri;
      final String? songPath = _songs[_currentSongIndex].data;
      
      if (songUri != null && songUri.isNotEmpty) {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(songUri)));
      } else if (songPath != null && songPath.isNotEmpty) {
        await _audioPlayer.setAudioSource(AudioSource.file(songPath));
      } else {
        // Try next song if this one is invalid
        _nextSong();
      }
    } catch (e) {
      debugPrint("Load Song Error: $e");
      // Prevent stuck state
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _checkPendingRun() async {
    // Check if there was a crash or unfinished run
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pendingRun = prefs.getString('current_run_state');
      
      if (pendingRun != null) {
        final data = jsonDecode(pendingRun) as Map<String, dynamic>;
        
        // Only restore if less than 12 hours old (simple heuristic)
        final timestamp = DateTime.tryParse(data['timestamp'] ?? '');
        if (timestamp != null && DateTime.now().difference(timestamp).inHours < 12) {
            
            final List<dynamic> pointsJson = data['points'] ?? [];
            final List<LatLng> restoredPoints = pointsJson.map((p) => LatLng(p['lat'], p['lng'])).toList();
            
            if (restoredPoints.isNotEmpty) {
              setState(() {
                _seconds = data['seconds'] ?? 0;
                _distance = data['distance'] ?? 0.0;
                _calories = data['calories'] ?? 0.0;
                _routePoints.addAll(restoredPoints);
                _startLocation = restoredPoints.first;
                _currentLocation = restoredPoints.last;
                
                if (data['runStartTime'] != null) {
                  _runStartTime = DateTime.tryParse(data['runStartTime']);
                }
                
                // Set to paused so user can decide to resume
                _runningState = RunningState.paused;
                
                // Recalculate averages
                _updatePace();
                if (_seconds > 0) _avgBpm = 0; // Reset or persist nicely? 0 is fine.
              });
              
              // Center map
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 try {
                   _centerMap(_currentLocation);
                   _fitMapToRoute();
                 } catch (_) {}
                 
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: const Text("Run restored from crash/close"),
                     action: SnackBarAction(
                       label: "Discard",
                       onPressed: () => _clearPendingRun(),
                     ),
                   ),
                 );
              });
            }
        } else {
           // Too old, clear it
           await _clearPendingRun();
        }
      }
    } catch (e) {
      debugPrint("Error restoring run: $e");
      await _clearPendingRun(); // Corrupt data
    }
  }

  Future<void> _persistCurrentRun() async {
    // Throttle persistence to avoid jank (max once every 10 seconds)
    final now = DateTime.now();
    if (_lastPersistTime != null && now.difference(_lastPersistTime!).inSeconds < 10) {
      return;
    }
    
    if (_runningState != RunningState.running && _runningState != RunningState.paused) return;
    
    try {
       _lastPersistTime = now;
       final prefs = await SharedPreferences.getInstance();
       final state = {
         'timestamp': now.toIso8601String(),
         'runStartTime': _runStartTime?.toIso8601String(),
         'seconds': _seconds,
         'distance': _distance,
         'calories': _calories,
         'points': _getDownsampledPoints(),
       };
       await prefs.setString('current_run_state', jsonEncode(state));
    } catch (e) {
      debugPrint("Throttled persistence error: $e");
    }
  }

  List<Map<String, double>> _getDownsampledPoints() {
    if (_routePoints.length < 500) {
      return _routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
    }
    List<Map<String, double>> downsampled = [];
    for (int i = 0; i < _routePoints.length; i += 5) {
      downsampled.add({'lat': _routePoints[i].latitude, 'lng': _routePoints[i].longitude});
    }
    if (_routePoints.isNotEmpty) {
      downsampled.add({'lat': _routePoints.last.latitude, 'lng': _routePoints.last.longitude});
    }
    return downsampled;
  }

  Future<void> _clearPendingRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_run_state');
  }

  EdgeInsets _getMapPadding() {
    if (!mounted) return EdgeInsets.zero;
    final double sheetRatio = _sheetController.isAttached 
        ? _sheetController.size 
        : (_runningState == RunningState.idle ? _sheetHeightIdle : _sheetHeightRunning);
    
    final screenHeight = MediaQuery.of(context).size.height;
    return EdgeInsets.only(
      top: 80,
      left: 40,
      right: 40,
      bottom: screenHeight * sheetRatio + 20,
    );
  }

  void _centerMap(LatLng loc) {
    if (!mounted) return;
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [loc],
          padding: _getMapPadding(),
          maxZoom: 16.0,
          forceIntegerZoomLevel: false,
        ),
      );
    } catch (_) {}
  }

  Future<void> _fetchInitialLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        // Center map initially
        WidgetsBinding.instance.addPostFrameCallback((_) {
             _centerMap(_currentLocation);
        });
        
        // Start tracking purely for UI updates (User "dot") even in Idle
        _startLocationTracking();
      }
    } catch (e) {
      debugPrint("Error fetching initial location: $e");
    }
  }

  Future<void> _initHealth() async {
    try {
      final healthRepo = ref.read(healthRepositoryProvider);
      
      // Request permissions directly
      bool authorized = await healthRepo.requestPermissions();
      if (mounted) {
        setState(() {
          _isHealthConnected = authorized;
        });
      }
    } catch (e) {
      print("Health init error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }


  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // _startLocation is handled by _startRun or restoration
      if (_routePoints.isEmpty && _runningState == RunningState.running) {
        _routePoints.add(_currentLocation);
      }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy for run tracking
      distanceFilter: 2, // Lower filter for finer granularity (filtering handled manually)
    );

    // Cancel existing to avoid doubles
    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
          _realGPSLocation = LatLng(position.latitude, position.longitude);
          
          double finalLat = position.latitude;
          double finalLng = position.longitude;

          // Apply Offset (Pro Feature Only - Disabled for standard user flow based on request)
          /*
          if (_latOffset != null && _lngOffset != null) {
            finalLat += _latOffset!;
            finalLng += _lngOffset!;
          }
          */

          final newLatLng = LatLng(finalLat, finalLng);
          
          // --- Live Motion Processing (Filtering) ---
          
          // 1. Calculate and Smooth Speed
          double currentSpeed = position.speed; // in m/s
          if (currentSpeed < 0) currentSpeed = 0; // Handle invalid speed
          
          // Add to buffer
          _recentSpeeds.add(currentSpeed);
          if (_recentSpeeds.length > _speedBufferSize) {
            _recentSpeeds.removeAt(0);
          }
          
          // Calculate average recent speed
          double avgSpeed = 0;
          if (_recentSpeeds.isNotEmpty) {
            avgSpeed = _recentSpeeds.reduce((a, b) => a + b) / _recentSpeeds.length;
          }

            // 2. Auto-Pause / Auto-Resume Logic
            if (_runningState == RunningState.running) {
              if (avgSpeed < _autoPauseThreshold && _recentSpeeds.length >= _speedBufferSize) {
                 _autoPauseConfidenceCount++;
                 if (_autoPauseConfidenceCount >= 3) { // Require 3 pings to confirm pause
                    _autoPauseConfidenceCount = 0;
                    setState(() {
                      _runningState = RunningState.paused;
                      _isAutoPaused = true;
                    });
                    _stopTimer();
                    _speak("Pausing workout");
                 }
              } else {
                 _autoPauseConfidenceCount = 0;
              }
            } else if (_runningState == RunningState.paused && _isAutoPaused) {
              if (avgSpeed > _autoResumeThreshold) {
                _autoPauseConfidenceCount = 0;
                _startRun(); // Unified start/resume logic
                _isAutoPaused = false;
                _speak("Resuming workout");
              }
            }

          if (mounted) {
            setState(() {
              _currentLocation = newLatLng;

              // Update Current Pace (using smoothed avgSpeed)
              // 16.666 = 1000 meters / 60 seconds
              if (avgSpeed > 0.3) { 
                 _currentPace = 16.666 / avgSpeed; // min/km
              } else {
                 _currentPace = 0.0;
              }

              // 3. Sanity Cap & Data Accumulation
              if (_runningState == RunningState.running && !_isAutoPaused) {
                 double dist = 0;
                 if (_routePoints.isNotEmpty) {
                    dist = _distanceCalc.as(LengthUnit.Meter, _routePoints.last, newLatLng);
                 } else {
                    // First point logic if needed, but usually 0 dist
                 }
                 
                 // Sanity check: < 30m (approx 100km/h) to filter huge jumps
                 if (dist > 3 && dist < 30) { // 3m filter
                     _distance += dist / 1000.0;
                     _routePoints.add(newLatLng);
                     // Add logic to handle first point color if empty?
                     // Usually _routeColors corresponds to segments.
                     // But Polyline points vs colors.
                     // If I have N points, I can have N colors? Or N-1 segments.
                     // flutter_map gradientColors usually needs colors for points.
                     _routeColors.add(_getSpeedColor(currentSpeed));
                     
                     _updateStats(newLatLng, currentSpeed);
                     
                     // Keep map centered
                     _centerMap(newLatLng);
                 }
              }
            });
          }
      });
    } catch (e) {
      debugPrint("Tracking engine error: $e");
    }
  }

  Future<void> _speak(String text, {bool force = false}) async {
    try {
      if (!force && _runningState == RunningState.countdown) return; // Don't speak stats during countdown unless forced
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }
  
  Color _getSpeedColor(double speed) {
    // Map speed (m/s) to Color (Red -> Yellow -> Green)
    if (speed <= 0.5) return const Color(0xFFF83A71); // Red/Pink (Stop/Slow)
    if (speed >= 3.5) return const Color(0xFF00C853); // Green (Fast ~ 12km/h)
    
    // Simple interpolation
    if (speed < 2.0) {
      // Red to Yellow
      return Color.lerp(const Color(0xFFF83A71), Colors.yellow, speed / 2.0)!;
    } else {
      // Yellow to Green
      return Color.lerp(Colors.yellow, const Color(0xFF00C853), (speed - 2.0) / 1.5)!;
    }
  }

  void _startTimer() {
    _runStartTime ??= DateTime.now();
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_runningState == RunningState.running) {
        setState(() {
          _seconds++;
          _updateCalories();
        });
        
        if (_isHealthConnected && _seconds % 5 == 0) {
           _fetchHeartRate();
        }
      }
    });

    if (_positionStreamSubscription == null) {
      _startLocationTracking();
    } else if (_positionStreamSubscription!.isPaused) {
      _positionStreamSubscription!.resume();
    }
    
    if (_isHealthConnected) {
      // Re-init health poll if needed
    }
  }

  Future<void> _fetchHealthData() async {
    if (_runStartTime == null) return;
    try {
      final now = DateTime.now();
      final healthRepo = ref.read(healthRepositoryProvider);
      
      // Fetch Calories
      final cals = await healthRepo.getEnergyInInterval(_runStartTime!, now);
      // Fetch Steps
      final steps = await healthRepo.getStepsInInterval(_runStartTime!, now);
      // Fetch HR
      await _fetchHeartRate();

      if (mounted) {
        setState(() {
          if (cals > 0) _calories = cals;
          if (steps > 0) _steps = steps;
        });
      }
    } catch (e) {
      debugPrint("Health poll error: $e");
    }
  }

  Future<void> _fetchHeartRate() async {
    if (_runStartTime == null) return;
    try {
      final now = DateTime.now();
      // Fetch data since 5 minutes ago or start of run, to get recent average
      final start = _runStartTime!; // Fetch from start of run for "Average"
      
      final healthRepo = ref.read(healthRepositoryProvider);
      final points = await healthRepo.getHeartRateData(start, now);
      
      if (points.isNotEmpty) {
        double totalBpm = 0;
        int count = 0;
        for (var p in points) {
           if (p.value is NumericHealthValue) {
             totalBpm += (p.value as NumericHealthValue).numericValue.toDouble();
             count++;
           }
        }
        
        if (count > 0) {
          setState(() {
            _avgBpm = totalBpm / count;
          });
        }
      }
    } catch (e) {
      print("HR Fetch error: $e");
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _positionStreamSubscription?.pause();
    // Keep _runStartTime preserved during pause for accurate Health/Summary results
  }

  void _updateStats(LatLng newLocation, double currentSpeed) {
    if (_startLocation == null) return;
    
    // Check KM splits for Audio
    int currentKm = _distance.toInt();
    if (currentKm > _lastKmAnnounced) {
       _lastKmAnnounced = currentKm;
       // Speak stats
       String paceString = _formatPace(_avgPace);
       // Split Pace: "5 30" -> "5 minutes 30 seconds"
       int pMin = _avgPace.toInt();
       int pSec = ((_avgPace - pMin) * 60).toInt();
       
       _speak("Distance $currentKm kilometers. Pace $pMin minutes $pSec seconds per kilometer.");
    }
    
    // Recalculate pace/calories
    _updatePace();
    _updateCalories();
    
    // _fitMapToRoute(); 

    // Persist current run state for crash resilience
    _persistCurrentRun();
  }

  void _updatePace() {
    if (_distance > 0 && _seconds > 0) {
      // Pace in minutes per km
      _avgPace = (_seconds / 60.0) / _distance;
    }
  }

  void _updateCalories() {
    // Only estimate if we haven't got real data from Health Connect
    if (_isHealthConnected && _calories > 0) return;

    // Rough estimate: 60 kcal per km
    _calories = _distance * 60.0;
    // Plus a small amount for time if distance is 0
    if (_distance == 0) {
      _calories = (_seconds / 60.0) * 5.0; // 5 kcal per minute idling
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    if (pace == 0 || pace.isInfinite || pace.isNaN) return '0.0';
    final minutes = pace.toInt();
    final seconds = ((pace - minutes) * 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveActivity() async {
    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'run',
      distance: _distance,
      duration: _seconds,
      calories: _calories,
      averagePace: _avgPace,
      averageBPM: _avgBpm,
      date: DateTime.now(),
    );

    try {
      // 1. Dual Saving: Save to Health Connect / Apple Health
      if (_isHealthConnected && _startLocation != null) {
           final healthRepo = ref.read(healthRepositoryProvider);
           final endTime = DateTime.now();
           final startTime = _runStartTime ?? endTime.subtract(Duration(seconds: _seconds)); // Fallback if null
           
           await healthRepo.saveRunToHealth(
             startTime: startTime,
             endTime: endTime,
             totalDistanceMeters: _distance * 1000,
             totalEnergyBurned: _calories,
           );
      }

      // 2. Dual Saving: Save to API + Local DB (Pending Sync logic inside repository)
      await ref.read(activityRepositoryProvider).logActivity(activity);
      
      // 3. Clear the crash resilience state
      await _clearPendingRun();

      // Invalidate stats to refresh dashboard and activity screens
      ref.invalidate(activityStatsProvider('week'));
      ref.invalidate(activityStatsProvider('month'));
      ref.invalidate(activitySummaryProvider('week'));
      ref.invalidate(activitySummaryProvider('month'));
      ref.invalidate(activityListProvider);
      ref.invalidate(challengesListProvider);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      debugPrint('Error saving activity: $e');
    }
  }

  double _getButtonTopOffset() {
    switch (_runningState) {
      case RunningState.idle:
        return -50.0;
      case RunningState.running:
        return -40.0;
      case RunningState.paused:
        return -30.0;
      case RunningState.finished:
        return 0.0;
      case RunningState.countdown:
        return -50.0;
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;
    
    final padding = _getMapPadding();

    // Use current location and start location to define bounds if route is small
    final points = List<LatLng>.from(_routePoints);
    if (_currentLocation != points.last) {
      points.add(_currentLocation);
    }
    
    // If we only have one point, use fitCamera with coordinates to enforce padding
    if (points.length < 2) {
       try {
         _mapController.fitCamera(
           CameraFit.coordinates(
             coordinates: [_currentLocation],
             padding: padding,
             maxZoom: 16.0, // Comfortable zoom level for running
             forceIntegerZoomLevel: false,
           ),
         );
       } catch (_) {}
       return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: padding,
          ),
        );
      } catch (_) {}
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    // If points are the same or very close, return default bearing (north)
    if ((start.latitude - end.latitude).abs() < 0.00001 &&
        (start.longitude - end.longitude).abs() < 0.00001) {
      return 0;
    }

    final lat1 = start.latitude * (math.pi / 180);
    final lat2 = end.latitude * (math.pi / 180);
    final dLon = (end.longitude - start.longitude) * (math.pi / 180);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  void _startCountdown() {
    setState(() {
      _runningState = RunningState.countdown;
      _countdownSeconds = 3;
    });
    _speak("3", force: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
          _speak(_countdownSeconds.toString(), force: true);
        } else {
          timer.cancel();
          _speak("Go", force: true);
          _startRun();
        }
      });
    });
  }

  void _startRun() {
    setState(() {
      // Only perform a full reset if starting fresh from Idle or Countdown.
      // If we are coming from Paused, this becomes a non-destructive Resume.
      if (_runningState == RunningState.idle || _runningState == RunningState.countdown) {
        _startLocation = _currentLocation;
        _routePoints.clear();
        _routePoints.add(_currentLocation);
        _routeColors.clear();
        _seconds = 0;
        _distance = 0.0;
        _calories = 0.0;
        _avgPace = 0.0;
        _avgBpm = 0.0;
        _lastKmAnnounced = 0;
        _runStartTime = DateTime.now();
      }
      
      _runningState = RunningState.running;
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    // Base design width approx 393 (iPhone 14/15)
    final double scale = (screenWidth / 393.0).clamp(0.8, 1.2); 

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/images/bg-gradient.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Map section (Full screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight,
            child: IgnorePointer(
              ignoring: _runningState == RunningState.running || _runningState == RunningState.countdown, 
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(29.2882, 47.9015),
                  initialZoom: 16.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onMapReady: () {
                    // Center the map in the visible top half immediately
                     try {
                       _mapController.fitCamera(
                         CameraFit.coordinates(
                           coordinates: [_currentLocation],
                           padding: _getMapPadding(),
                           maxZoom: 16.0,
                           forceIntegerZoomLevel: false,
                         ),
                       );
                     } catch (_) {}
                  },
                  onTap: (tapPosition, point) {
                      // Removed manual location setting on tap
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.tryd.app',
                  ),
                  // Route polyline
                  if (_routePoints.isNotEmpty && _routePoints.length > 1 && (_runningState == RunningState.running || _runningState == RunningState.paused))
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          gradientColors: _routeColors.length > 1 
                              ? _routeColors 
                              : [const Color(0xFFF83A71), const Color(0xFFF83A71)],
                        ),
                      ],
                    ),
                  // Current Location Layer (Better Marker)
                  // Show this during run
                  if (_runningState == RunningState.running || _runningState == RunningState.paused)
                    CurrentLocationLayer(
                      style: const LocationMarkerStyle(
                        marker: Icon(
                          Icons.navigation,
                          color: Color(0xFF333333), 
                          size: 32,
                        ),
                        markerSize: Size(40, 40),
                        markerDirection: MarkerDirection.heading,
                        showAccuracyCircle: false, 
                        showHeadingSector: false,
                      ),
                    ),
                  
                  MarkerLayer(
                    markers: [
                      // Start location marker
                      if (_startLocation != null && _runningState != RunningState.idle && _runningState != RunningState.countdown)
                        Marker(
                          point: _startLocation!,
                          width: 20,
                          height: 20,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF333333),
                                width: 4.35419,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 4.35,
                                height: 4.35,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Current location pointer - show when idle or countdown
                      if (_runningState == RunningState.idle || _runningState == RunningState.countdown)
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40, 
                          child: SvgPicture.asset(
                            'assets/images/location_pointer.svg',
                            width: 40,
                            height: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Locate Me Button (Floating) - Anchored to Bottom Sheet
          if (_runningState == RunningState.idle)
             ListenableBuilder(
              listenable: _sheetController,
              builder: (context, child) {
                double sheetSize = _sheetHeightIdle;
                if (_sheetController.isAttached) {
                  sheetSize = _sheetController.size;
                }
                // Position just above the bottom sheet
                final bottomPadding = (MediaQuery.of(context).size.height * sheetSize) + 20;
                
                return Positioned(
                  right: 20,
                  bottom: bottomPadding,
                  child: child!,
                );
              },
              child: GestureDetector(
                onTap: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    final newPos = LatLng(pos.latitude, pos.longitude);
                    setState(() {
                      _currentLocation = newPos;
                      _centerMap(newPos);
                    });
                  } catch (_) {}
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                    ],
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF900EBF)),
                ),
              ),
            ),
          
          // Draggable Content section (Bottom Sheet)
          if (_runningState != RunningState.finished && _runningState != RunningState.countdown)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _runningState == RunningState.idle ? _sheetHeightIdle : _sheetHeightRunning,
              minChildSize: _sheetHeightMin,
              maxChildSize: _sheetHeightIdle,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  clipBehavior: Clip.none,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, -4),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 55),
                    child: Column(
                      children: [
                        _buildStatsSection(scale),
                        const SizedBox(height: 20),
                        _buildPaceHeartRateCard(scale),
                        const SizedBox(height: 16),
                        _buildMediaControlsCard(scale),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Summary View when finished
          if (_runningState == RunningState.finished) _buildSummaryView(scale),

          // Button positioned at top
          if (_runningState != RunningState.finished && _runningState != RunningState.countdown)
            ListenableBuilder(
              listenable: _sheetController,
              builder: (context, child) {
                double size = _runningState == RunningState.idle ? _sheetHeightIdle : _sheetHeightRunning;
                if (_sheetController.isAttached) {
                  size = _sheetController.size;
                }
                final topOffset = _getButtonTopOffset() * scale; // Scale offset!
                final top = screenHeight * (1.0 - size) + topOffset;
                return Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildStartButton(scale),
                  ),
                );
              },
            ),

          // COUNTDOWN OVERLAY
          if (_runningState == RunningState.countdown)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF900EBF).withOpacity(0.95), // Brand color overlay
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_countdownSeconds',
                        style: GoogleFonts.lexend(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ready to run...',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top navigation bar (Hidden during countdown)
          if (_runningState != RunningState.countdown)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBackButton(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ActivityScreen()),
                            );
                          },
                          child: _buildTopIconButton(Icons.history),
                        ),
                        const SizedBox(width: 11),
                        _buildTopIconButton(Icons.share),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Bottom navigation
          if (_runningState != RunningState.countdown) // Hide during countdown
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 1) return;
                
                Widget? page;
                switch (index) {
                  case 0: page = const HomeScreen(); break;
                  case 2: page = const RewardsScreen(); break;
                  case 3: page = const WorkoutScreen(); break;
                  case 4: page = const ClubScreen(); break;
                }
                
                if (page != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page!),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(double scale) {
    // Base sizes
    double buttonSize = 96.0;
    
    // Scale button but cap it reasonable limits
    double scaledButtonSize = (buttonSize * scale).clamp(80.0, 110.0);

    switch (_runningState) {
      case RunningState.idle:
        return _buildCircularButton(
          size: scaledButtonSize,
          onTap: () async {
            // Trigger Countdown instead of immediate start
            _startCountdown();
          },
          child: Text(
            'START',
            style: GoogleFonts.poppins(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        );

      case RunningState.countdown:
        return const SizedBox.shrink();
        
      case RunningState.running:
        return GestureDetector(
          onTap: () {
            setState(() {
              _runningState = RunningState.paused;
              _isAutoPaused = false; 
            });
            _stopTimer();
            _speak("Pausing workout");
          },
          child: Container(
            width: 80 * scale,
            height: 80 * scale,
            decoration: BoxDecoration(
              color: const Color(0xFF900EBF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2D2D2).withOpacity(0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 11.9,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Center(child: _buildPauseIcon(scale)),
          ),
        );
        
      case RunningState.paused:
        // Use Flexible or constraints to prevent overflow
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop button
              Flexible(
                child: GradientButton(
                  text: 'Stop',
                  width: 155 * scale, // Scaled width
                  height: 52 * scale,
                  showIcon: false,
                  onPressed: () async {
                    setState(() {
                      _runningState = RunningState.finished;
                      _fitMapToRoute();
                      _stopTimer();
                    });
                    await _saveActivity();
                    _runStartTime = null;
                  },
                ),
              ),
              const SizedBox(width: 11),
              // Play button
               _buildPlayButton(scale),
            ],
          ),
        );
        
      case RunningState.finished:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCircularButton({
    required double size,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF900EBF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD2D2D2).withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 11.9,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildPauseIcon(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8.92 * scale,
          height: 21.19 * scale,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4.46 * scale),
        Container(
          width: 8.92 * scale,
          height: 21.19 * scale,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(double scale) {
    double size = 52 * scale;
    return GestureDetector(
      onTap: () {
        _startRun(); // Use _startRun to ensure timer/stream logic is centralized
        _speak("Resuming workout");
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB7B7B7).withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 17.5,
            ),
          ],
        ),
        child: Center(
          child: Transform.translate(
            offset: const Offset(2, 0),
            child: Icon(
              Icons.play_arrow,
              color: const Color(0xFF900EBF),
              size: 28 * scale,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(double scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildStatItem('DISTANCE', _distance.toStringAsFixed(2), 'km', scale),
          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),
          _buildStatItem('DURATION', _formatDuration(_seconds), null, scale),
          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),
          _buildStatItem('EST. CALS', _calories.toStringAsFixed(0), null, scale),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String? unit, double scale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w400,
              height: 15 / 12,
              color: const Color(0xFF8B88B5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.lexendDeca(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w600,
                  height: 30 / 24,
                  color: const Color(0xFF1B2D51),
                ),
              ),
              if (unit != null)
                Text(
                  unit,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8B88B5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6F86B5).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildPaceHeartRateCard(double scale) {
    return Container(
      // Responsive width: taking full width minus margins
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 82),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3)),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 32,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPaceHeartItem(_formatPace(_currentPace), 'min/km', 'CURRENT PACE', scale),
          Container(width: 1, height: 50 * scale, color: const Color(0xFFE8ECF4)), // Divider instead of steps? Or just space.

          const SizedBox(width: 20),
          _buildPaceHeartItem(_avgBpm.toStringAsFixed(0), 'bpm', 'HEART RATE', scale),
        ],
      ),
    );
  }

  Widget _buildPaceHeartItem(String value, String unit, String label, double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 27.5 * scale,
                fontWeight: FontWeight.w500,
                height: 1.1, 
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ],
        ),
        SizedBox(height: 9.93 * scale),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11.35 * scale,
            fontWeight: FontWeight.w400,
            height: 1.1,
            color: const Color(0xFF8B88B5),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePlay() async {
    if (_songs.isEmpty) {
       _speak("No local music found");
       return;
    }
    try {
      if (_isMusicPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      setState(() {
        _isMusicPlaying = !_isMusicPlaying;
      });
    } catch (_) {}
  }

  Future<void> _nextSong() async {
     if (_songs.isEmpty) return;
     int next = _currentSongIndex + 1;
     if (next >= _songs.length) next = 0;
     setState(() { _currentSongIndex = next; });
     await _loadSong();
     if (_isMusicPlaying) await _audioPlayer.play();
  }

  Future<void> _prevSong() async {
     if (_songs.isEmpty) return;
     int prev = _currentSongIndex - 1;
     if (prev < 0) prev = _songs.length - 1;
     setState(() { _currentSongIndex = prev; });
     await _loadSong();
     if (_isMusicPlaying) await _audioPlayer.play();
  }

  Widget _buildMediaControlsCard(double scale) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 66),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3)),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 32,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_songs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _songs[_currentSongIndex].title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12 * scale, color: const Color(0xFF6F86B5)),
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                 onTap: () {
                    // Show playlist? For now just indicator
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Playlist: ${_songs.length} songs found")));
                 },
                 child: Icon(Icons.list_rounded, size: 31 * scale, color: const Color(0xFF96AAD2)),
              ),
              GestureDetector(
                 onTap: _prevSong,
                 child: Icon(Icons.skip_previous, size: 29 * scale, color: const Color(0xFF96AAD2)),
              ),
              _buildPlayPauseButton(scale),
              GestureDetector(
                 onTap: _nextSong,
                 child: Icon(Icons.skip_next, size: 29 * scale, color: const Color(0xFF96AAD2)),
              ),
              GestureDetector(
                 onTap: () {
                   setState(() {
                     _isMusicMuted = !_isMusicMuted;
                     _audioPlayer.setVolume(_isMusicMuted ? 0 : 1);
                   });
                 },
                 child: Icon(
                   _isMusicMuted ? Icons.volume_off : Icons.volume_up, 
                   size: 26 * scale, 
                   color: const Color(0xFF96AAD2),
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(double scale) {
    double size = 44 * scale;
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF96AAD2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isMusicPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 24 * scale,
        ),
      ),
    );
  }

  Widget _buildSummaryView(double scale) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stats section
              _buildSummaryStatItem('DISTANCE', _distance.toStringAsFixed(1), 'km', scale),
              const SizedBox(height: 10),
              _buildDivider(),
              const SizedBox(height: 10),
              _buildSummaryStatItem('DURATION', _formatDuration(_seconds), null, scale),
              const SizedBox(height: 10),
              _buildDivider(),
              const SizedBox(height: 10),
              _buildSummaryStatItem('EST. CALS', _calories.toStringAsFixed(0), null, scale),
              const SizedBox(height: 25),
              // Pace / Heart Rate Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 10), // Safe margin
                constraints: const BoxConstraints(minHeight: 82),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  border: Border.all(color: const Color(0xFFE8ECF4)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryPaceHeartItem(_formatPace(_avgPace), 'min/km', 'AVERAGE PACE', scale),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
                    _buildSummaryPaceHeartItem(_avgBpm.toStringAsFixed(0), 'bpm', 'AVG HEART RATE', scale),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Share Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GradientButton(
                  text: 'Share',
                  width: double.infinity, // Full width but with padding
                  height: 52 * scale,
                  showIcon: true,
                  onPressed: () {
                    // Handle share action
                  },
                ),
              ),
              const SizedBox(height: 120), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, String? unit, double scale) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8B88B5),
            textStyle: const TextStyle(letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 40 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.lexend(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8B88B5),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryPaceHeartItem(String value, String unit, String label, double scale) {
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 30.5 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8B88B5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.35 * scale,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8B88B5),
              textStyle: const TextStyle(letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
      child: SizedBox(
        width: 28,
        height: 28,
        child: SvgPicture.asset(
          'assets/images/back_arrow_icon.svg',
          width: 28,
          height: 28,
        ),
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF221F48),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2.95),
            blurRadius: 8.77,
            spreadRadius: 4.42,
            color: const Color(0xFFD2D2D2).withOpacity(0.25),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
