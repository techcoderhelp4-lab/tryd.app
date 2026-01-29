import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

enum RunningState { idle, running, paused, finished }

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
  double _avgBpm = 0.0;
  final Distance _distanceCalc = const Distance();
  bool _isHealthConnected = false;
  DateTime? _runStartTime;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initHealth();
    _fetchInitialLocation();
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
          try {
             _mapController.move(_currentLocation, 16.0);
          } catch (_) {}
        });
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
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }


  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Capture the chosen/current location as the "Start" if not already set by button logic
    // We do NOT overwrite _currentLocation here with getCurrentPosition() to respect the user's pick
    // if they dragged the marker.
    
    // Ensure bounds are set for the start
    if (_startLocation == null) {
         _startLocation = _currentLocation;
    }
    if (_routePoints.isEmpty) {
        _routePoints.add(_currentLocation);
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
          if (_runningState != RunningState.running) return;
          
          final newLatLng = LatLng(position.latitude, position.longitude);
          
          // If this is the FIRST update and it's far from our chosen start location,
          // we might want to ignore it or smooth it? 
          // For now, we trust the stream but user asked to "Choose Location".
          // If the user is moving, it should be fine.
          
          setState(() {
            _currentLocation = newLatLng;
            _updateStats(newLatLng);
          });
      });
  }

  void _startTimer() {
    _runStartTime ??= DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_runningState == RunningState.running) {
        setState(() {
          _seconds++;
          _updateCalories();
        });
        
        // Poll for Heart Rate every 5 seconds if connected
        if (_isHealthConnected && _seconds % 5 == 0) {
           _fetchHeartRate();
        }
      }
    });

    // Start tracking but respect the location I picked
    _startLocationTracking();
    
    // Poll Health Data
    if (_isHealthConnected) {
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_runningState != RunningState.running) {
          timer.cancel();
          return;
        }
        _fetchHealthData();
      });
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
    _runStartTime = null; // Reset run time
  }

  void _updateStats(LatLng newPoint) {
    if (_routePoints.isNotEmpty) {
      // Only calculate distance if we have moved enough to avoid GPS jitter
      // But distanceFilter on stream handles most of it.
      final lastPoint = _routePoints.last;
      final dist = _distanceCalc.as(LengthUnit.Meter, lastPoint, newPoint);
      
      // Accumulate only positive movement
      if (dist > 0) {
        _distance += dist / 1000.0; // Convert to km
      }
    }
    
    _routePoints.add(newPoint);
    
    // Recalculate pace/calories
    _updatePace();
    _updateCalories();
    
    _fitMapToRoute(); // Dynamic zoom to fit route
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
      await ref.read(activityRepositoryProvider).logActivity(activity);
      // Invalidate stats to refresh dashboard
      ref.invalidate(activityStatsProvider('week'));
      ref.invalidate(activityListProvider);
      ref.invalidate(challengesListProvider);
    } catch (e) {
      debugPrint('Error saving activity: $e');
    }
  }

  double _getButtonTopOffset() {
    switch (_runningState) {
      case RunningState.idle:
        return -50.0;
      case RunningState.running:
        return -30.0;
      case RunningState.paused:
        return -30.0;
      case RunningState.finished:
        return 0.0;
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;
    
    // Large bottom padding to keep route in top half (above the bottom sheet)
    const padding = EdgeInsets.only(top: 80, left: 50, right: 50, bottom: 450);

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
              ignoring: _runningState != RunningState.idle,
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
                           padding: const EdgeInsets.only(top: 50, bottom: 450, left: 20, right: 20),
                           maxZoom: 16.0,
                           forceIntegerZoomLevel: false,
                         ),
                       );
                     } catch (_) {}
                  },
                  onTap: (tapPosition, point) {
                    setState(() {
                      _currentLocation = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.tryd.app',
                  ),
                  // Route polyline
                  if (_routePoints.isNotEmpty && _routePoints.length > 1 && _runningState != RunningState.idle)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: const Color(0xFFF83A71),
                          strokeWidth: 3.0,
                        ),
                      ],
                    ),
                  // Current Location Layer (Better Marker)
                  if (_runningState != RunningState.idle)
                    CurrentLocationLayer(
                      style: const LocationMarkerStyle(
                        marker: Icon(
                          Icons.navigation,
                          color: Color(0xFF333333), // Dark color as requested (ui before)
                          size: 32,
                        ),
                        markerSize: Size(40, 40),
                        markerDirection: MarkerDirection.heading,
                        showAccuracyCircle: false, // No blue light/circle
                        showHeadingSector: false,
                      ),
                    ),
                  MarkerLayer(
                    markers: [
                      // Start location marker
                      if (_startLocation != null)
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
                      // Current location pointer - only show when idle
                      if (_runningState == RunningState.idle)
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40, 
                          child: GestureDetector(
                            onPanUpdate: (details) {
                                // Get the current map camera
                                final camera = _mapController.camera;
                                final currentPixel = camera.project(_currentLocation);
                                final newPixel = math.Point(
                                  currentPixel.x + details.delta.dx,
                                  currentPixel.y + details.delta.dy,
                                );
                                final newLatLng = camera.unproject(newPixel);
                                setState(() {
                                  _currentLocation = newLatLng;
                                });
                            },
                            child: SvgPicture.asset(
                              'assets/images/location_pointer.svg',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Draggable Content section (Bottom Sheet)
          if (_runningState != RunningState.finished)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.50,
              minChildSize: 0.40, // Allow smaller drag
              maxChildSize: 0.85, // Allow larger drag
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
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(top: 55),
                    children: [
                      _buildStatsSection(scale),
                      const SizedBox(height: 20),
                      _buildPaceHeartRateCard(scale),
                      const SizedBox(height: 16),
                      _buildMediaControlsCard(scale),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          
          // Summary View when finished
          if (_runningState == RunningState.finished) _buildSummaryView(scale),

          // Button positioned at top
          if (_runningState != RunningState.finished)
            ListenableBuilder(
              listenable: _sheetController,
              builder: (context, child) {
                double size = 0.50;
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

          // Top navigation bar
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
          onTap: () {
            setState(() {
              _runningState = RunningState.running;
              _startLocation = _currentLocation;
              _routePoints.clear();
              _seconds = 0;
              _distance = 0.0;
              _calories = 0.0;
              _avgPace = 0.0;
              _avgBpm = 0.0;
              _routePoints.add(_currentLocation);
              
              _startTimer();
            });
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
        
      case RunningState.running:
        return _buildCircularButton(
          size: 80 * scale,
          onTap: () {
            setState(() {
              _runningState = RunningState.paused;
            });
          },
          child: _buildPauseIcon(scale),
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
        setState(() {
          _runningState = RunningState.running;
        });
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
          _buildPaceHeartItem(_formatPace(_avgPace), 'min/km', 'AVERAGE PACE', scale),
          const SizedBox(width: 20),
          _buildPaceHeartItem(_avgBpm.toStringAsFixed(0), 'bpm', 'HEART RATE', scale),
          const SizedBox(width: 20),
           _buildPaceHeartItem(_steps.toString(), 'steps', 'STEPS', scale),
        ],
      ),
    );
  }

  Widget _buildPaceHeartItem(String value, String unit, String label, double scale) {
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: 27.5 * scale,
                    fontWeight: FontWeight.w500,
                    height: 16 / 27.5,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 2),
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
              height: 11 / 11.35,
              color: const Color(0xFF8B88B5),
            ),
          ),
        ],
      ),
    );
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.list_rounded, size: 31 * scale, color: const Color(0xFF96AAD2)),
          Icon(Icons.skip_previous, size: 29 * scale, color: const Color(0xFF96AAD2)),
          _buildPlayPauseButton(scale),
          Icon(Icons.skip_next, size: 29 * scale, color: const Color(0xFF96AAD2)),
          Icon(Icons.volume_off, size: 26 * scale, color: const Color(0xFF96AAD2)),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(double scale) {
    double size = 44 * scale;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF96AAD2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.pause,
        color: Colors.white,
        size: 24 * scale,
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
