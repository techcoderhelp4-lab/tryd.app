import 'package:dio/dio.dart';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import '../../notifications/data/real_time_notification_service.dart';
import 'workout_screen.dart';
import '../../club/presentation/club_screen.dart';
import 'activity_screen.dart';
import '../../challenges/data/challenge_repository.dart';
import '../data/health_repository.dart';
import 'package:health/health.dart';
import 'share_screen.dart';
import 'package:intl/intl.dart';
import '../../profile/data/user_repository.dart';
import '../../notifications/data/real_time_notification_service.dart';

enum RunningState { idle, countdown, running, paused, finished }

class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> with WidgetsBindingObserver {
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
  double _earnedPoints = 0.0;
  bool _isAutoFollow = true;
  final Distance _distanceCalc = const Distance();
  bool _isHealthConnected = false;
  DateTime? _runStartTime;
  StreamSubscription<Position>? _positionStreamSubscription;
  double? _latOffset;
  double? _lngOffset;
  LatLng? _realGPSLocation;
  bool _isFirstAfterResume = false;
  bool _isLocationInitialized = false; // Track if we've set the initial location for the run
  bool _healthCheckAttempted = false; // Prevent auto-init loop
  bool _healthModalShownThisSession = false; // Prevent modal fatigue
  
  // Countdown
  // Countdown
  Timer? _countdownTimer;
  int _countdownSeconds = 3;

  // Live Motion / Speed Filtering
  final List<double> _recentSpeeds = []; 
  static const int _speedBufferSize = 5;
  static const double _maxRunningSpeed = 6.5; // m/s (~23 km/h) - Max human running speed (world record ~10.4 m/s, but we use 6.5 for safety)
  
  // ── Sheet Heights per device category ──────────────
  // Idle (content sheet when not running)
  static const double _sheetIdleSmall  = 0.72;
  static const double _sheetIdleMedium = 0.68;
  static const double _sheetIdleLarge  = 0.70;
  static const double _sheetIdleTablet = 0.60;
  // Running (sheet during run)
  static const double _sheetRunSmall  = 0.60;
  static const double _sheetRunMedium = 0.53;
  static const double _sheetRunLarge  = 0.60;
  static const double _sheetRunTablet  = 0.50;
  // Min (minimum drag height)
  static const double _sheetMinSmall  = 0.60;
  static const double _sheetMinMedium = 0.53;
  static const double _sheetMinLarge  = 0.60;
  static const double _sheetMinTablet  = 0.50;

  double get _sheetHeightIdle {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return _sheetIdleTablet;
    return h < 680 ? _sheetIdleSmall : h < 850 ? _sheetIdleMedium : _sheetIdleLarge;
  }
  double get _sheetHeightRunning {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return _sheetRunTablet;
    return h < 680 ? _sheetRunSmall : h < 850 ? _sheetRunMedium : _sheetRunLarge;
  }
  double get _sheetHeightMin {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return _sheetMinTablet;
    return h < 680 ? _sheetMinSmall : h < 850 ? _sheetMinMedium : _sheetMinLarge;
  }

  // Audio
  final FlutterTts _flutterTts = FlutterTts();
  int _lastKmAnnounced = 0;

  bool _isMusicPlaying = false;
  bool _isMusicMuted = false;
  
  // Local Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  int _currentSongIndex = 0;
  bool _hasAudioPermission = false;
  String? _currentSongName;

  @override
  void initState() {
    super.initState();
    debugPrint("RunningScreen: Initialized (Version: v2.MovementLock)");
    WidgetsBinding.instance.addObserver(this);
    // Clear any lingering live notifications from previous sessions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
      _initHealth();
    });
    _initTts();
    _initMusic();
    _fetchInitialLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("RunningScreen: App Resumed — checking health and refreshing socket");
      // Re-check health when coming back to the app (e.g. after installing Health Connect)
      if (!_isHealthConnected && !_healthModalShownThisSession) {
        _initHealth(force: true);
      }
      // Reconnect socket if it died in background
      ref.read(realTimeNotificationServiceProvider).reconnect();
    }
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      debugPrint("RunningScreen: App Background — pausing socket and canceling live notification");
      // Pause socket to prevent DNS errors while internet is restricted
      ref.read(realTimeNotificationServiceProvider).pause();
      // App is being closed or hidden, cancel live notification
      ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
    }
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
          
          // Listen to player state for real-time UI sync & Auto-Next
          _audioPlayer.playerStateStream.listen((state) {
            if (mounted) {
              setState(() {
                _isMusicPlaying = state.playing;
              });
              
              // Auto-next when song ends
              if (state.processingState == ProcessingState.completed) {
                _nextSong();
              }
            }
          });

          await _loadSong();
        }
      }
    } catch (e) {
      debugPrint("Audio Init Error: $e");
    }
  }

  Future<void> _pickSong() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        setState(() {
          _currentSongName = fileName;
          _isMusicPlaying = true;
        });

        await _audioPlayer.setAudioSource(AudioSource.file(filePath));
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Pick Song Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking song: $e"))
        );
      }
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







  Future<void> _clearPendingRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_run_state');
  }

  EdgeInsets _getMapPadding() {
    if (!mounted) return EdgeInsets.zero;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    double bottomOffset;

    if (_runningState == RunningState.finished) {
      // For summary view, reserve the bottom 65% of the screen
      bottomOffset = screenHeight * 0.65;
    } else if (_runningState == RunningState.running || _runningState == RunningState.paused) {
      // Reserve space equal to the stats sheet height
      final double sheetRatio = _sheetController.isAttached
          ? _sheetController.size
          : _sheetHeightRunning;
      // Add a buffer to ensure no overlap with the sheet's top portion
      bottomOffset = (screenHeight * sheetRatio) + 40.h;
    } else if (_runningState == RunningState.countdown) {
      // During countdown, center more broadly
      bottomOffset = screenHeight * 0.20;
    } else {
      // Idle - reserve space for the large idle sheet
      final double sheetRatio = _sheetController.isAttached
          ? _sheetController.size
          : _sheetHeightIdle;
      bottomOffset = screenHeight * sheetRatio;
    }

    // Top padding: fixed buffer to avoid header icons/buttons
    final double topPad = screenHeight * 0.14;
    
    // Horizontal padding for margins
    final double sidePad = isTablet ? 60.0 : 45.0;

    return EdgeInsets.only(
      top: topPad,
      left: sidePad,
      right: sidePad,
      bottom: bottomOffset,
    );
  }

  void _centerMap(LatLng loc) {
    if (!mounted) return;
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [loc],
          padding: _getMapPadding(),
          maxZoom: 18.8,
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
      if (!mounted) return;
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // 1. Get last known location for instant map load
      final lastPos = await Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (lastPos != null && mounted) {
        setState(() {
            _currentLocation = LatLng(lastPos.latitude, lastPos.longitude);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerMap(_currentLocation);
        });
      }

      // 2. Immediately start tracking for real-time updates
      _startLocationTracking();

      // (Redundant getCurrentPosition removed to prevent defunct state errors and reduce engine overhead)
    } catch (e) {
      debugPrint("Error fetching initial location: $e");
    }
  }

  Future<void> _initHealth({bool force = false}) async {
    if (_healthCheckAttempted && !force) {
      return;
    }
    
    // Check mounted before starting
    if (!mounted) return;
    
    _healthCheckAttempted = true;

    debugPrint("Health: Starting health check (force: $force)...");
    try {
      // Wait for a short moment to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final healthRepo = ref.read(healthRepositoryProvider);
      
      if (Platform.isAndroid) {
        debugPrint("Health: Checking Android SDK Status...");
        final status = await healthRepo.getSdkStatus();
        debugPrint("Health: SDK Status Result = $status");
        
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          debugPrint("Health: SDK not available ($status), showing modal.");
          if (mounted) {
            _showHealthConnectDialog(status);
          }
          return;
        }

        debugPrint("Health: SDK status is Available. Requesting permissions...");
        
        // RE-ENABLED FAIL-SAFE:
        // Timing check to detect if the permission launcher failed to show (e.g. missing app)
        final stopwatch = Stopwatch()..start();
        final authorized = await healthRepo.requestPermissions();
        stopwatch.stop();
        
        final duration = stopwatch.elapsedMilliseconds;
        debugPrint("Health: Authorization result = $authorized (took ${duration}ms)");

        // If it failed extremely fast (< 300ms) on Android, the dialog likely never showed up.
        // This is exactly what happens when the "Permission launcher" is missing.
        // This counts as an "Installation/Update" issue, not a "User Permission Denied" issue.
        if (!authorized && Platform.isAndroid && duration < 300) {
          debugPrint("Health: Authorization failed instantly. Suspecting broken/missing launcher.");
          if (mounted && !_healthModalShownThisSession) {
            _healthModalShownThisSession = true;
            _showHealthConnectDialog(HealthConnectSdkStatus.sdkUnavailable);
          }
          return;
        }

        if (mounted) {
          setState(() {
            _isHealthConnected = authorized;
          });
        }
      } else if (Platform.isIOS) {
        // iOS: Apple Health is always available, just request permissions
        debugPrint("Health: Requesting iOS permissions...");
        bool authorized = await healthRepo.requestPermissions();
        if (mounted) {
          if (!authorized) {
            debugPrint("Health: iOS permissions denied, showing dialog.");
            _showAppleHealthDialog();
          }
          setState(() {
            _isHealthConnected = authorized;
          });
        }
      }
    } catch (e) {
      debugPrint("Health init error: $e");
      // Allow re-attempt if it crashed
      _healthCheckAttempted = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _countdownTimer?.cancel();
    _positionStreamSubscription?.cancel();
    
    // Safely attempt to cancel notifications - if ref is already disposed, 
    // the system (or background handlers) will handle cleanup.
    try {
       ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
    } catch (_) {
       // Provider/Ref already gone, ignore as it's being disposed anyway
    }
    
    _mapController.dispose();
    _sheetController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }


  Future<void> _startLocationTracking() async {
    if (!mounted) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // --- Battery-Aware Tracking Settings ---
      final Battery _battery = Battery();
      final int batteryLevel = await _battery.batteryLevel;
      if (!mounted) return;
      final bool isLowBattery = batteryLevel < 15;

      final LocationSettings locationSettings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0, // Get every update, we handle filtering
            intervalDuration: const Duration(seconds: 1),
            useMSLAltitude: false,
          )
        : AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
          );


    // Cancel existing to avoid doubles
    await _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
          // --- SPEED FILTERING (Indoor/Noise) ---
          double rawSpeed = position.speed;
          if (rawSpeed < 0) rawSpeed = 0;

          // Update buffer for noise rejection (Moving Average)
          if (rawSpeed < _maxRunningSpeed * 1.5) { // Protect against large GPS jumps
             _recentSpeeds.add(rawSpeed);
             if (_recentSpeeds.length > _speedBufferSize) {
               _recentSpeeds.removeAt(0);
             }
          }
          
          final double avgSpeed = _recentSpeeds.isEmpty 
              ? 0 
              : _recentSpeeds.reduce((a, b) => a + b) / _recentSpeeds.length;
          final double currentSpeed = rawSpeed;

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

          // --- MOTION CONFIDENCE ---
          // Use hardware verified speed (avgSpeed) for all decisions.
          // Jitter/Drift usually has spd=0 even if the lat/lng jumps.
          bool isReallyMoving = avgSpeed > 0.8; 

          // --- 1. VISUAL UPDATE (Uber/Careem Experience) ---
          if (mounted) {
            setState(() {
              _currentLocation = newLatLng;
              
              if (_runningState == RunningState.running && isReallyMoving) {
                if (_routePoints.isEmpty) {
                  _routePoints.add(newLatLng);
                  _startLocation = newLatLng;
                  _isLocationInitialized = true;
                } else {
                  final double visualDist = _distanceCalc.as(LengthUnit.Meter, _routePoints.last, newLatLng);
                  // Only add to map path if we are actually moving and distance is significant
                  if (visualDist > 5.0) { 
                    _routePoints.add(newLatLng);
                    _fitMapToRoute(); 
                  }
                }
              }
            });
          }

          // --- 2. DATA ACCURACY FILTER ---
          if (position.accuracy > 100.0) return; // Stricter accuracy for stats

          if (mounted) {
            setState(() {
              // Update Current Pace: Only if hardware confirms real movement
              if (_runningState == RunningState.running && isReallyMoving) { 
                 _currentPace = 16.666 / avgSpeed; 
              } else {
                 _currentPace = 0.0;
              }
            });
          }

          if (_runningState == RunningState.running && _routePoints.length > 1 && isReallyMoving) {
              final double dist = _distanceCalc.as(LengthUnit.Meter, _routePoints[_routePoints.length - 2], newLatLng);
              
              // Noise Filter: Jump must be larger than noise floor
              double noiseThreshold = math.max(7.0, position.accuracy * 1.2); 
              
              if (dist > noiseThreshold) {
                  // Speed Cap: Human running speed limit
                  if (avgSpeed < 8.5) {
                    if (!_isFirstAfterResume) {
                      setState(() {
                        _distance += dist / 1000.0;
                        _updateStats(newLatLng, currentSpeed);
                      });
                    } else {
                      _isFirstAfterResume = false;
                    }
                  }
              }
          }
      });
    } catch (e) {
      debugPrint("Tracking engine error: $e");
    }
  }

  Future<void> _updateLiveNotification() async {
    if (_runningState != RunningState.running && _runningState != RunningState.paused) {
      ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
      return;
    }

    final String durationStr = _formatDuration(_seconds);
    final String distanceStr = _distance.toStringAsFixed(2);
    final String paceStr = _formatPace(_currentPace);
    final status = _runningState == RunningState.paused ? " (Paused)" : "";

    await ref.read(realTimeNotificationServiceProvider).showLiveStats(
          title: '$distanceStr km$status',
          body: 'Pace: $paceStr • Time: $durationStr',
          summary: 'Running Activity',
        );
  }

  Future<void> _speak(String text, {bool force = false}) async {
    try {
      if (!force && _runningState == RunningState.countdown) return; // Don't speak stats during countdown unless forced
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
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
        
        // Every 5s: HR
        if (_isHealthConnected && _seconds % 5 == 0) {
           _fetchHeartRate();
        }
        // Every 10s: Calories & Steps
        if (_isHealthConnected && _seconds % 10 == 0) {
           _fetchHealthData();
        }

        // --- Nike Style Live Notification Update ---
        _updateLiveNotification();
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
  }

  void _updateStats(LatLng newLocation, double currentSpeed) {
    if (_startLocation == null) return;
    
    // Check KM splits for Audio
    int currentKm = _distance.toInt();
    if (currentKm > _lastKmAnnounced) {
       _lastKmAnnounced = currentKm;
       // Speak split — context-aware like Nike Run Club
       int pMin = _avgPace.toInt();
       int pSec = ((_avgPace - pMin) * 60).toInt();
       final kmWord = currentKm == 1 ? "kilometer" : "kilometers";
       final paceStr = "$pMin ${pSec.toString().padLeft(2, '0')}";

       // Context-aware milestone cues
       if (currentKm == 1) {
         _speak("First kilometer, pace $paceStr");
       } else if (currentKm == 5) {
         _speak("$currentKm $kmWord, Keep it up, pace $paceStr");
       } else if (currentKm == 10) {
         _speak("$currentKm $kmWord, Great pace, $paceStr");
       } else if (currentKm % 5 == 0) {
         _speak("$currentKm $kmWord, Strong, pace $paceStr");
       } else {
         _speak("$currentKm $kmWord, pace $paceStr");
       }
    }
    
    // Recalculate pace/calories/points
    _updatePace();
    _updateCalories();
    _updatePoints();
    
    // Live Notification Pulse
    _updateLiveNotification();
  }

  void _updatePoints() {
    // Real-time point generation: 1 km = 10 Points
    setState(() {
      _earnedPoints = _distance * 10.0;
    });
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

    // Strictly distance-based for Running (approx 65 kcal per km)
    // This prevents "fake" counting while standing still at the start or during pauses
    if (_distance > 0) {
      _calories = _distance * 65.0; 
    } else {
      _calories = 0.0;
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

  Future<String> _getCityName(LatLng point) async {
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
        return address['city'] ?? address['town'] ?? address['suburb'] ?? address['state'] ?? "Unknown Location";
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return "Unknown Location";
  }

  double _calculateHeading(LatLng p1, LatLng p2) {
    final double lat1 = p1.latitude * math.pi / 180;
    final double lon1 = p1.longitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lon2 = p2.longitude * math.pi / 180;
    
    final double dLon = lon2 - lon1;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  Future<void> _saveActivity() async {
    if (!mounted) return;
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

      // Show banner notification
      ref.read(realTimeNotificationServiceProvider).showInAppBanner(
        'Activity Saved!',
        'Your run has been successfully recorded.',
        showAlert: true,
        showSnackBar: false,
      );

      // 3. Clear the crash resilience state
      await _clearPendingRun();

      // 4. Update challenge progress in background (fire-and-forget)
      ref.read(challengeRepositoryProvider).updateAllChallengesProgress(
        distanceKm: _distance,
        durationSeconds: _seconds,
        calories: _calories,
      ).catchError((e) => debugPrint('Challenge progress update error: $e'));

      // 5. Batch invalidate all relevant providers (once, no duplicates)
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

  double _getButtonTopOffset() {
    switch (_runningState) {
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

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;
    
    final padding = _getMapPadding();

    // Collect all points including current location to ensure visibility
    final points = List<LatLng>.from(_routePoints);
    if (_currentLocation != points.last) {
      points.add(_currentLocation);
    }
    
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: padding,
          maxZoom: 18.8, // Slightly more zoomed in
          forceIntegerZoomLevel: false,
        ),
      );
    } catch (_) {}
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
      // Fresh run -> Full reset
      if (_runningState == RunningState.idle || _runningState == RunningState.countdown) {
        _startLocation = _currentLocation;
        _routePoints.clear();
        _routePoints.add(_currentLocation);

        _seconds = 0;
        _distance = 0.0;
        _calories = 0.0;
        _avgPace = 0.0;
        _avgBpm = 0.0;
        _lastKmAnnounced = 0;
        _runStartTime = DateTime.now();
        _isLocationInitialized = false; // Reset flag for fresh run
        _recentSpeeds.clear();
      }
      
      // In both start and resume, ensure timer and state are correct
      if (_runningState == RunningState.paused) {
        _isFirstAfterResume = true; // Flag to prevent distance cheat from last point
      }
      
      _runningState = RunningState.running;
      // Restart location tracking to ensure foreground service notification is active
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _startTimer();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMap(_currentLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    
    // Tablet detection
    final isTablet = screenWidth > 600;
    
    // ── Responsive Scale ──────────────────────────────────
    // Change these 3 values to control ALL component sizes:
    //   small  → phones with height < 680px
    //   medium → phones with height 680–850px
    //   large  → phones with height > 850px
    const double smallScale  = 0.74;
    const double mediumScale = 0.84;
    const double largeScale  = 0.94;
    const double tabletScale = 0.90;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;


    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: _runningState == RunningState.countdown ? null : CustomBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if (index == 1) return;
          
          if (_runningState == RunningState.running || _runningState == RunningState.paused) {
            final result = await _showExitConfirmation();
            if (result == null) return; // "Keep Running" tapped

            // Show summary view instead of navigating away
            setState(() {
              _runningState = RunningState.finished;
              _stopTimer();
              _positionStreamSubscription?.cancel();
              _positionStreamSubscription = null;
            });
            ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
            if (_distance >= 10) {
              _speak('Run complete, Amazing effort');
            } else if (_distance >= 5) {
              _speak('Run complete, Great job');
            } else {
              _speak('Run complete, Well done');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMapToRoute();
            });
            await _saveActivity();
            _runStartTime = null;
            return;
          }

          if (!mounted) return;

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
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_runningState == RunningState.running || _runningState == RunningState.paused) {
            final result = await _showExitConfirmation();
            if (result == null) return; // "Keep Running" tapped

            // Show summary view instead of navigating away
            setState(() {
              _runningState = RunningState.finished;
              _stopTimer();
              _positionStreamSubscription?.cancel();
              _positionStreamSubscription = null;
            });
            ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
            if (_distance >= 10) {
              _speak('Run complete, Amazing effort');
            } else if (_distance >= 5) {
              _speak('Run complete, Great job');
            } else {
              _speak('Run complete, Well done');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMapToRoute();
            });
            await _saveActivity();
            _runStartTime = null;
            return;
          } else if (_runningState == RunningState.finished) {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          } else {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          }
        },
        child: Stack(
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
                  initialZoom: 18.8,
                  minZoom: 5.0,
                  maxZoom: 20.0,
                  onMapReady: () {
                    // Center the map in the visible top half immediately
                     try {
                       _mapController.fitCamera(
                         CameraFit.coordinates(
                           coordinates: [_currentLocation],
                           padding: _getMapPadding(),
                           maxZoom: 18.8,
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
                  // Route polyline - show progressive line during run and full line when finished
                  if (_routePoints.isNotEmpty && _routePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0, // Thicker line for better visibility
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                          color: const Color(0xFFF83A71),
                        ),
                      ],
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
                      // Current/Finish arrow - show during run, paused and finished
                      if (_routePoints.isNotEmpty && (_runningState == RunningState.running || _runningState == RunningState.paused || _runningState == RunningState.finished))
                        Marker(
                          point: _routePoints.last,
                          width: isTablet ? 48.0 : 40.0,
                          height: isTablet ? 48.0 : 40.0,
                          child: Transform.rotate(
                            angle: (_routePoints.length > 1 
                              ? _calculateHeading(_routePoints[_routePoints.length - 2], _routePoints.last)
                              : 0.0) - (math.pi / 4), // Icon points NE (45deg) by default, adjust to North
                            child: Icon(
                              Icons.navigation,
                              color: const Color(0xFF333333),
                              size: isTablet ? 36.0 : 32.0,
                            ),
                          ),
                        ),
                      // Current location pointer - show when idle or countdown
                      if (_runningState == RunningState.idle || _runningState == RunningState.countdown)
                        Marker(
                          point: _currentLocation,
                          width: isTablet ? 48.0 : 40.0,
                          height: isTablet ? 48.0 : 40.0,
                          child: SvgPicture.asset(
                            'assets/images/location_pointer.svg',
                            width: isTablet ? 48.0 : 40.0,
                            height: isTablet ? 48.0 : 40.0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Locate Me Button (Floating)
          if (_runningState != RunningState.finished && _runningState != RunningState.countdown)
             ListenableBuilder(
              listenable: _sheetController,
              builder: (context, child) {
                double sheetSize = _sheetHeightIdle;
                if (_sheetController.isAttached) {
                  sheetSize = _sheetController.size;
                }
                // Position just above the bottom sheet
                final bottomPadding = (MediaQuery.of(context).size.height * sheetSize) + (isTablet ? 24.0 : 16.0);
                
                return Positioned(
                  right: isTablet ? 24.0 : 16.0,
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
                      _isAutoFollow = true; // Re-enable follow
                      _centerMap(newPos);
                    });
                  } catch (_) {}
                },
                child: Container(
                  width: isTablet ? 56.0 : 42.0,
                  height: isTablet ? 56.0 : 42.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(Icons.my_location, color: const Color(0xFF900EBF), size: isTablet ? 28.0 : 20.0),
                ),
              ),
            ),
          
          // Draggable Content section (Bottom Sheet)
          if (_runningState != RunningState.finished && _runningState != RunningState.countdown)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _runningState == RunningState.idle ? _sheetHeightIdle : _sheetHeightRunning,
              minChildSize: math.min(_sheetHeightMin, _runningState == RunningState.idle ? _sheetHeightIdle : _sheetHeightRunning),
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
                    padding: EdgeInsets.only(top: (isTablet ? 72.0 : 62.0) * scale),
                    child: Column(
                      children: [
                        _buildStatsSection(scale, isTablet),
                        SizedBox(height: (isTablet ? 20.0 : 12.0) * scale),
                        _buildPaceHeartRateCard(scale, isTablet),
                        SizedBox(height: (isTablet ? 12.0 : 8.0) * scale),
                        _buildMediaControlsCard(scale, isTablet),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Summary View when finished
          if (_runningState == RunningState.finished) _buildSummaryView(scale, isTablet),

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
                    child: _buildStartButton(scale, isTablet),
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
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_countdownSeconds),
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Text(
                          '$_countdownSeconds',
                          style: GoogleFonts.lexend(
                            fontSize: (isTablet ? 120.0 : 110.0) * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Top navigation bar (Hidden during countdown)
          if (_runningState != RunningState.countdown)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.0 : 22.0 * scale,
                  vertical: isTablet ? 12.0 : 8.0 * scale,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBackButton(scale, isTablet),
                    // GPS indicator hidden
                    const SizedBox.shrink(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ActivityScreen()),
                            );
                          },
                          child: _buildTopIconButton(Icons.history, scale, isTablet),
                        ),
                        SizedBox(width: isTablet ? 12.0 : 11.0),
                        _buildTopIconButton(Icons.share, scale, isTablet),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          

        ],
      ),
    ),
  );
}

  Future<String?> _showExitConfirmation() async {
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    'End Run?',
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Save your progress and exit, or continue your run?',
                    style: GoogleFonts.lexend(
                      fontSize: 14.0,
                      color: const Color(0xFF24252C).withOpacity(0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.pop(context, 'save'),
              borderRadius: BorderRadius.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.center,
                child: Text(
                  'Save & Exit',
                  style: GoogleFonts.lexend(
                    fontSize: 16.0,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.pop(context, null),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20.0), bottomRight: Radius.circular(20.0)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.center,
                child: Text(
                  'Keep Running',
                  style: GoogleFonts.lexend(
                    fontSize: 16.0,
                    color: const Color(0xFF8B88B5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(double scale, bool isTablet) {
    // Base sizes per device category
    final screenHeight = MediaQuery.of(context).size.height;
    double buttonSize = isTablet ? 80.0 : screenHeight < 680
        ? 88.0   // small
        : screenHeight < 850
            ? 85.0   // medium
            : 80.0;  // large

    double scaledButtonSize = buttonSize * scale;

    switch (_runningState) {
      case RunningState.idle:
        return _buildCircularButton(
          size: scaledButtonSize,
          isTablet: isTablet,
          onTap: () async {
            // Trigger Countdown instead of immediate start
            _startCountdown();
          },
          child: Text(
            'START',
            style: GoogleFonts.poppins(
              fontSize: 18.0 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        );

      case RunningState.countdown:
        return const SizedBox.shrink();
        
      case RunningState.running:
        final runningButtonSize = 75.0 * scale;
        return GestureDetector(
          onTap: () {
            setState(() {
              _runningState = RunningState.paused;
            });
            _stopTimer();
            _speak('Paused');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMapToRoute();
            });
          },
          child: Container(
            width: runningButtonSize,
            height: runningButtonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF900EBF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2D2D2).withOpacity(0.25),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(child: _buildPauseIcon(scale, isTablet)),
          ),
        );
        
      case RunningState.paused:
        // Use Flexible or constraints to prevent overflow
        final stopWidth = 140.0 * scale;
        final stopHeight = 48.0 * scale;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18.0 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop button
              Flexible(
                child: GradientButton(
                  text: 'Stop',
                  width: stopWidth,
                  height: stopHeight,
                  showIcon: false,
                  onPressed: () async {
                    setState(() {
                      _runningState = RunningState.finished;
                      _stopTimer();
                      _positionStreamSubscription?.cancel();
                      _positionStreamSubscription = null;
                    });
                    ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
                    // Context-aware finish cue
                    if (_distance >= 10) {
                      _speak('Run complete, Amazing effort');
                    } else if (_distance >= 5) {
                      _speak('Run complete, Great job');
                    } else {
                      _speak('Run complete, Well done');
                    }
                    // Recenter map after summary renders
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitMapToRoute();
                    });
                    await _saveActivity();
                    _runStartTime = null;
                  },
                ),
              ),
              SizedBox(width: 11.0 * scale),
              // Play button
               _buildPlayButton(scale, isTablet),
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
    required bool isTablet,
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
              spreadRadius: isTablet ? 8 : 6,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildPauseIcon(double scale, bool isTablet) {
    final barWidth = (isTablet ? 9.0 : 8.0) * scale;
    final barHeight = (isTablet ? 22.0 : 19.0) * scale;
    final gap = (isTablet ? 6.0 : 4.0) * scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: gap),
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(double scale, bool isTablet) {
    final size = (isTablet ? 56.0 : 48.0) * scale;
    final iconSize = (isTablet ? 32.0 : 26.0) * scale;
    return GestureDetector(
      onTap: () {
        _speak("Let's go");
        _startRun(); // Use _startRun to ensure timer/stream logic is centralized
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB7B7B7).withOpacity(0.25),
              offset: const Offset(0, 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: Transform.translate(
            offset: const Offset(1.5, 0),
            child: Icon(
              Icons.play_arrow,
              color: const Color(0xFF900EBF),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(double scale, bool isTablet) {
    final spacing = isTablet ? 10.0 * scale : 8.0 * scale;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 15.0 * scale : 12.0 * scale),
      child: Column(
        children: [
          _buildStatItem('DISTANCE', _distance.toStringAsFixed(2), 'km', scale, isTablet),
          SizedBox(height: spacing),
          _buildDivider(),
          SizedBox(height: spacing),
          _buildStatItem('DURATION', _formatDuration(_seconds), null, scale, isTablet),
          SizedBox(height: spacing),
          _buildDivider(),
          SizedBox(height: spacing),
          _buildStatItem('EST. CALS', _calories.toStringAsFixed(0), null, scale, isTablet),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String? unit, double scale, bool isTablet) {
    final labelSize = (isTablet ? 12.0 : 12.0) * scale;
    final valueSize = (isTablet ? 24.0 : 26.0) * scale;
    final unitSize = (isTablet ? 16.0 : 15.0) * scale;
    final verticalPadding = (isTablet ? 6.0 : 5.0) * scale;
    final gap = (isTablet ? 6.0 : 5.0) * scale;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: labelSize,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: const Color(0xFF8B88B5),
            ),
          ),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.lexendDeca(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: const Color(0xFF1B2D51),
                ),
              ),
              if (unit != null)
                Text(
                  unit,
                  style: GoogleFonts.lexendDeca(
                    fontSize: unitSize,
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

  Widget _buildPaceHeartRateCard(double scale, bool isTablet) {
    final minHeight = isTablet ? 82.0 * scale : 72.0 * scale;
    final margin = isTablet ? 15.0 * scale : 12.0 * scale;
    final padding = isTablet ? 15.0 * scale : 12.0 * scale;
    final dividerHeight = isTablet ? 50.0 * scale : 40.0 * scale;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      margin: EdgeInsets.symmetric(horizontal: margin),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3)),
        borderRadius: BorderRadius.circular(isTablet ? 15.0 : 12.0),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 3),
            blurRadius: 20,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPaceHeartItem(_formatPace(_currentPace), 'min/km', 'CURRENT PACE', scale, isTablet),
          Container(width: 1, height: dividerHeight, color: const Color(0xFFE8ECF4)),
          SizedBox(width: isTablet ? 20.0 : 12.0),
          _buildPaceHeartItem(_avgBpm > 0 ? _avgBpm.toStringAsFixed(0) : '--', 'bpm', 'HEART RATE', scale, isTablet),
        ],
      ),
    );
  }
  void _showHealthConnectDialog(HealthConnectSdkStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired 
                        ? 'Update Required' 
                        : 'Health Connect Required',
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired 
                        ? 'Your Google Health Connect app needs an update to sync workout data properly.' 
                        : 'To track your steps and heart rate accurately, you need to install the Google Health Connect app.',
                    style: GoogleFonts.lexend(
                      fontSize: 14.0,
                      color: const Color(0xFF24252C).withOpacity(0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      alignment: Alignment.center,
                      child: Text(
                        'Later',
                        style: GoogleFonts.lexend(
                          fontSize: 16.0,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: const Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(healthRepositoryProvider).installHealthConnect();
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      alignment: Alignment.center,
                      child: Text(
                        'Install / Update',
                        style: GoogleFonts.lexend(
                          fontSize: 16.0,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  void _showAppleHealthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    'Apple Health Access',
                    style: GoogleFonts.lexend(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Tryd needs access to Apple Health to track your steps, distance, and heart rate during runs.\n\nPlease go to:',
                    style: GoogleFonts.lexend(
                      fontSize: 14.0,
                      color: const Color(0xFF24252C).withOpacity(0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Settings → Health → Data Access → Tryd',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        color: const Color(0xFF1B2D51),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Turn on all categories to get the best experience.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      color: const Color(0xFF24252C).withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      alignment: Alignment.center,
                      child: Text(
                        'Later',
                        style: GoogleFonts.lexend(
                          fontSize: 16.0,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: const Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      openAppSettings();
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      alignment: Alignment.center,
                      child: Text(
                        'Open Settings',
                        style: GoogleFonts.lexend(
                          fontSize: 16.0,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaceHeartItem(String value, String unit, String label, double scale, bool isTablet) {
    final valueSize = (isTablet ? 27.5 : 26.0) * scale;
    final unitSize = (isTablet ? 14.0 : 13.0) * scale;
    final labelSize = (isTablet ? 11.35 : 11.0) * scale;
    final gap = (isTablet ? 9.93 : 6.0) * scale;
    
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
                fontSize: valueSize,
                fontWeight: FontWeight.w500,
                height: 1.1, 
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: unitSize,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: labelSize,
            fontWeight: FontWeight.w400,
            height: 1.1,
            color: const Color(0xFF8B88B5),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePlay() async {
    if (_songs.isEmpty) return;
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Toggle Play Error: $e");
    }
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

  Widget _buildMediaControlsCard(double scale, bool isTablet) {
    final minHeight = isTablet ? 66.0 * scale : 56.0 * scale;
    final margin = isTablet ? 15.0 * scale : 12.0 * scale;
    final hPadding = isTablet ? 15.0 * scale : 12.0 * scale;
    final vPadding = isTablet ? 11.0 * scale : 9.0 * scale;
    final listIconSize = (isTablet ? 31.0 : 28.0) * scale;
    final skipIconSize = (isTablet ? 29.0 : 26.0) * scale;
    final volumeIconSize = (isTablet ? 26.0 : 24.0) * scale;
    final titleFontSize = (isTablet ? 12.0 : 12.0) * scale;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      margin: EdgeInsets.symmetric(horizontal: margin),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F3F3)),
        borderRadius: BorderRadius.circular(isTablet ? 15.0 : 12.0),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 3),
            blurRadius: 20,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_songs.isNotEmpty || _currentSongName != null)
            Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 8.0 : 5.0),
              child: Text(
                _currentSongName ?? _songs[_currentSongIndex].title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: titleFontSize, color: const Color(0xFF6F86B5)),
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                 onTap: _pickSong,
                 child: Icon(Icons.list_rounded, size: listIconSize, color: const Color(0xFF96AAD2)),
              ),
              GestureDetector(
                 onTap: _prevSong,
                 child: Icon(Icons.skip_previous, size: skipIconSize, color: const Color(0xFF96AAD2)),
              ),
              _buildPlayPauseButton(scale, isTablet),
              GestureDetector(
                 onTap: _nextSong,
                 child: Icon(Icons.skip_next, size: skipIconSize, color: const Color(0xFF96AAD2)),
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
                   size: volumeIconSize, 
                   color: const Color(0xFF96AAD2),
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(double scale, bool isTablet) {
    final size = (isTablet ? 44.0 : 44.0) * scale;
    final iconSize = (isTablet ? 24.0 : 24.0) * scale;
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
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildSummaryView(double scale, bool isTablet) {
    final screenHeight = MediaQuery.of(context).size.height;

    // ── Summary Responsive Scale ──────────────────────────
    // Change these 3 values to control ALL summary sizes:
    //   small  → phones with height < 680px
    //   medium → phones with height 680–850px
    //   large  → phones with height > 850px
    //   tablet → devices with width > 600px
    const double summarySmall  = 0.55;
    const double summaryMedium = 0.75;
    const double summaryLarge  = 0.85;
    const double summaryTablet = 0.55;

    final double sScale = isTablet
        ? summaryTablet
        : screenHeight < 680
            ? summarySmall
            : screenHeight < 850
                ? summaryMedium
                : summaryLarge;

    final horizontalPadding = (isTablet ? 40.0 : 10.0) * sScale;
    final verticalGap = (isTablet ? 15.0 : 10.0) * sScale;
    final sectionGap = (isTablet ? 30.0 : 25.0) * sScale;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stats section
              _buildSummaryStatItem('DISTANCE', _distance.toStringAsFixed(2), 'km', sScale, isTablet),
              SizedBox(height: verticalGap),
              _buildDivider(),
              SizedBox(height: verticalGap),
              _buildSummaryStatItem('DURATION', _formatDuration(_seconds), null, sScale, isTablet),
              SizedBox(height: verticalGap),
              _buildDivider(),
              SizedBox(height: verticalGap),
              _buildSummaryStatItem('EST. CALS', _calories.toStringAsFixed(0), null, sScale, isTablet),
              SizedBox(height: sectionGap),
              // Pace / Heart Rate Card
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: (isTablet ? 20.0 : 10.0) * sScale),
                constraints: BoxConstraints(minHeight: (isTablet ? 100.0 : 82.0) * sScale),
                padding: EdgeInsets.all((isTablet ? 20.0 : 12.0) * sScale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  border: Border.all(color: const Color(0xFFE8ECF4)),
                  borderRadius: BorderRadius.circular(15.0 * sScale),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryPaceHeartItem(_formatPace(_avgPace), 'min/km', 'AVERAGE PACE', sScale, isTablet),
                    Container(width: 1, height: (isTablet ? 60.0 : 40.0) * sScale, color: Colors.grey.withValues(alpha: 0.2)),
                    _buildSummaryPaceHeartItem(_avgBpm > 0 ? _avgBpm.toStringAsFixed(0) : '--', 'bpm', 'HEART RATE', sScale, isTablet),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),
              // Share Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: (isTablet ? 40.0 : 20.0) * sScale),
                child: GradientButton(
                  text: 'Share',
                  width: double.infinity,
                  height: isTablet ? 60.0 : 52.0,
                  showIcon: true,
                  onPressed: () {
                    // Share Button logic
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShareScreen(
                          totalTime: _formatDuration(_seconds),
                          avgPace: _formatPace(_avgPace),
                          distance: _distance.toStringAsFixed(2),
                          date: DateFormat('dd MMM yyyy').format(DateTime.now()),
                          routePoints: _routePoints,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom spacing per device category
              SizedBox(height: isTablet ? 180.0 : screenHeight < 680
                  ? 125.0   // small
                  : screenHeight < 850
                      ? 145.0   // medium
                      : 155.0), // large
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, String? unit, double scale, bool isTablet) {
    final labelSize = isTablet ? 14.0 : 13.0 * scale;
    final valueSize = isTablet ? 45.0 : 40.0 * scale;
    final unitSize = isTablet ? 18.0 : 16.0 * scale;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: labelSize,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8B88B5),
            textStyle: const TextStyle(letterSpacing: 0.5),
          ),
        ),
        SizedBox(height: 5 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: valueSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: 4 * scale),
              Text(
                unit,
                style: GoogleFonts.lexend(
                  fontSize: unitSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1B2D51),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryPaceHeartItem(String value, String unit, String label, double scale, bool isTablet) {
    final valueSize = isTablet ? 35.0 : 30.5 * scale;
    final unitSize = isTablet ? 16.0 : 14.0 * scale;
    final labelSize = isTablet ? 12.0 : 10.0 * scale;

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
                      fontSize: valueSize,
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
                  fontSize: unitSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8B88B5),
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: labelSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8B88B5),
              textStyle: const TextStyle(letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(double scale, bool isTablet) {
    final size = (isTablet ? 42.0 : 32.0) * scale;
    return GestureDetector(
      onTap: () async {
        if (_runningState == RunningState.running || _runningState == RunningState.paused) {
          final result = await _showExitConfirmation();
          if (result == null) return; // "Keep Running" tapped

          // Show summary view instead of navigating away
          setState(() {
            _runningState = RunningState.finished;
            _stopTimer();
            _positionStreamSubscription?.cancel();
            _positionStreamSubscription = null;
          });
          ref.read(realTimeNotificationServiceProvider).cancelLiveStats();
          if (_distance >= 10) {
            _speak('Run complete, Amazing effort');
          } else if (_distance >= 5) {
            _speak('Run complete, Great job');
          } else {
            _speak('Run complete, Well done');
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapToRoute();
          });
          await _saveActivity();
          _runStartTime = null;
          return;
        }

        if (_runningState == RunningState.finished) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      },
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/images/back_arrow_icon.svg',
          width: size,
          height: size,
        ),
      ),
    );
  }

  Widget _buildTopIconButton(IconData icon, double scale, bool isTablet) {
    final size = (isTablet ? 48.0 : 44.0) * scale;
    final iconSize = (isTablet ? 26.0 : 24.0) * scale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF221F48),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 3,
            color: const Color(0xFFD2D2D2).withOpacity(0.25),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}
