import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../../../../widgets/custom_bottom_navigation.dart';
import '../../../../../widgets/gradient_button.dart';

enum RunningState { idle, running, paused, finished }

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  int _selectedIndex = 1;
  RunningState _runningState = RunningState.idle;
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  LatLng _currentLocation = const LatLng(29.2882, 47.9015);
  LatLng? _startLocation;
  final List<LatLng> _routePoints = [];

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
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
    if (_routePoints.length < 2) return;

    final bounds = LatLngBounds.fromPoints(_routePoints);
    
    // Force the route into the top half of the screen by using a very large bottom padding
    final padding = _runningState == RunningState.finished
        ? const EdgeInsets.only(top: 100, left: 50, right: 50, bottom: 650)
        : const EdgeInsets.only(top: 100, left: 50, right: 50, bottom: 550);
        
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: padding,
        ),
      );
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
    final screenHeight = MediaQuery.of(context).size.height;

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
          
          // Map section (half screen)
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

                              // Calculate the new position based on drag
                              final currentPixel = camera.project(_currentLocation);
                              final newPixel = math.Point(
                                currentPixel.x + details.delta.dx,
                                currentPixel.y + details.delta.dy,
                              );

                              // Convert back to LatLng
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
                      // Direction arrow
                      if (_runningState != RunningState.idle && _startLocation != null)
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              // Get the current map camera
                              final camera = _mapController.camera;

                              // Calculate the new position based on drag
                              final currentPixel = camera.project(_currentLocation);
                              final newPixel = math.Point(
                                currentPixel.x + details.delta.dx,
                                currentPixel.y + details.delta.dy,
                              );

                              // Convert back to LatLng
                              final newLatLng = camera.unproject(newPixel);

                              setState(() {
                                _currentLocation = newLatLng;
                                if (_runningState == RunningState.running) {
                                  _routePoints.add(newLatLng);
                                }
                              });
                            },
                            child: Transform.rotate(
                              angle: _calculateBearing(_startLocation!, _currentLocation) + (math.pi * 75 / 180),
                              child: const Icon(
                                Icons.navigation,
                                color: Color(0xFF333333),
                                size: 32,
                              ),
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
              minChildSize: 0.50,
              maxChildSize: 0.70,
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
                      _buildStatsSection(),
                      const SizedBox(height: 20),
                      _buildPaceHeartRateCard(),
                      const SizedBox(height: 16),
                      _buildMediaControlsCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          
          // Summary View when finished
          if (_runningState == RunningState.finished) _buildSummaryView(),

          // Button positioned at top
          if (_runningState != RunningState.finished)
            ListenableBuilder(
              listenable: _sheetController,
              builder: (context, child) {
                double size = 0.50;
                if (_sheetController.isAttached) {
                  size = _sheetController.size;
                }
                final topOffset = _getButtonTopOffset();
                final top = screenHeight * (1.0 - size) + topOffset;
                return Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildStartButton(),
                  ),
                );
              },
            ),

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, top: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(),
                  Row(
                    children: [
                      _buildTopIconButton(Icons.history),
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
                if (index == 0) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;

    switch (_runningState) {
      case RunningState.idle:
        return _buildCircularButton(
          size: isSmallScreen ? 80.0 : 96.0,
          onTap: () {
            setState(() {
              _runningState = RunningState.running;
              _startLocation = _currentLocation;
              _routePoints.clear();
              
              // Create zigzag route pattern staying on roads
              final startLat = _currentLocation.latitude;
              final startLng = _currentLocation.longitude;
              
              _routePoints.add(_currentLocation); // Start
              _routePoints.add(LatLng(startLat + 0.0015, startLng - 0.0010));
              _routePoints.add(LatLng(startLat + 0.0025, startLng - 0.0020)); // Zig left
              _routePoints.add(LatLng(startLat + 0.0040, startLng - 0.0010));
              _routePoints.add(LatLng(startLat + 0.0050, startLng - 0.0020)); // Zig left
              _routePoints.add(LatLng(startLat + 0.0065, startLng - 0.0005));
              _routePoints.add(LatLng(startLat + 0.0075, startLng - 0.0015)); // Zig left
              _routePoints.add(LatLng(startLat + 0.0090, startLng - 0.0000));
              _routePoints.add(LatLng(startLat + 0.0100, startLng - 0.0010)); // Zig left
              _routePoints.add(LatLng(startLat + 0.0115, startLng + 0.0005));
              _routePoints.add(LatLng(startLat + 0.0125, startLng - 0.0005));
              _routePoints.add(LatLng(startLat + 0.0140, startLng + 0.0010));
              _routePoints.add(LatLng(startLat + 0.0150, startLng + 0.0000)); // Zig left
              _routePoints.add(LatLng(startLat + 0.0165, startLng + 0.0015));
              _routePoints.add(LatLng(startLat + 0.0175, startLng + 0.0020));
              _routePoints.add(LatLng(startLat + 0.0185, startLng + 0.0025));
              _routePoints.add(LatLng(startLat + 0.0195, startLng + 0.0030));
              _routePoints.add(LatLng(startLat + 0.0205, startLng + 0.0035));
              _routePoints.add(LatLng(startLat + 0.0215, startLng + 0.0040)); // End
              
              // Update current location to end point
              _currentLocation = LatLng(startLat + 0.0215, startLng + 0.0040);
              
              // Calculate center point and adjust map to show full route
              final centerLat = startLat + 0.0107;
              final centerLng = startLng + 0.0010;
              
              // Move map to show full route
              Future.delayed(const Duration(milliseconds: 100), () {
                _mapController.move(
                  LatLng(centerLat, centerLng),
                  13.5,
                );
              });
              
              _fitMapToRoute();
            });
          },
          child: Text(
            'START',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        );
        
      case RunningState.running:
        return _buildCircularButton(
          size: 80,
          onTap: () {
            setState(() {
              _runningState = RunningState.paused;
            });
          },
          child: _buildPauseIcon(),
        );
        
      case RunningState.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stop button
            GradientButton(
              text: 'Stop',
              width: 155,
              height: 52,
              showIcon: false,
              onPressed: () {
                setState(() {
                  _runningState = RunningState.finished;
                  _fitMapToRoute();
                });
              },
            ),
            const SizedBox(width: 11),
            // Play button
            _buildPlayButton(),
          ],
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

  Widget _buildPauseIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8.92,
          height: 21.19,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4.46),
        Container(
          width: 8.92,
          height: 21.19,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _runningState = RunningState.running;
        });
      },
      child: Container(
        width: 52,
        height: 52,
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
            child: const Icon(
              Icons.play_arrow,
              color: Color(0xFF900EBF),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          _buildStatItem('DISTANCE', '0.0', 'km'),
          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),
          _buildStatItem('DURATION', '00:00:00', null),
          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),
          _buildStatItem('EST. CALS', '000', null),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String? unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12,
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
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 30 / 24,
                  color: const Color(0xFF1B2D51),
                ),
              ),
              if (unit != null)
                Text(
                  unit,
                  style: GoogleFonts.lexendDeca(
                    fontSize: 16,
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

  Widget _buildPaceHeartRateCard() {
    return Container(
      width: 372,
      height: 82,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPaceHeartItem('0.0', 'min/km', 'AVERAGE PACE'),
          const SizedBox(width: 68),
          _buildPaceHeartItem('0', 'bpm', 'AVERAGE HEART RATE'),
        ],
      ),
    );
  }

  Widget _buildPaceHeartItem(String value, String unit, String label) {
    return SizedBox(
      width: 122,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.lexend(
                  fontSize: 27.5,
                  fontWeight: FontWeight.w500,
                  height: 16 / 27.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8B88B5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9.93),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.35,
              fontWeight: FontWeight.w400,
              height: 11 / 11.35,
              color: const Color(0xFF8B88B5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaControlsCard() {
    return Container(
      width: 372,
      height: 66,
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
          const Icon(Icons.list_rounded, size: 31, color: Color(0xFF96AAD2)),
          const Icon(Icons.skip_previous, size: 29, color: Color(0xFF96AAD2)),
          _buildPlayPauseButton(),
          const Icon(Icons.skip_next, size: 29, color: Color(0xFF96AAD2)),
          const Icon(Icons.volume_off, size: 26, color: Color(0xFF96AAD2)),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF96AAD2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pause,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildSummaryView() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 11),
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
              _buildSummaryStatItem('DISTANCE', '5.6', 'km'),
              const SizedBox(height: 10),
              _buildDivider(),
              const SizedBox(height: 10),
              _buildSummaryStatItem('DURATION', '10:24:06', null),
              const SizedBox(height: 10),
              _buildDivider(),
              const SizedBox(height: 10),
              _buildSummaryStatItem('EST. CALS', '234', null),
              const SizedBox(height: 25),
              // Pace / Heart Rate Card
              Container(
                width: 372,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  border: Border.all(color: const Color(0xFFE8ECF4)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSummaryPaceHeartItem('6.2', 'min/km', 'AVERAGE PACE'),
                    const SizedBox(width: 68),
                    _buildSummaryPaceHeartItem('105', 'bpm', 'AVERAGE HEART RATE'),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Share Button
              GradientButton(
                text: 'Share',
                width: 342,
                height: 52,
                showIcon: true,
                onPressed: () {
                  // Handle share action
                },
              ),
              const SizedBox(height: 140), // Pushes content further up
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, String? unit) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 13,
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
                fontSize: 40,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.lexend(
                  fontSize: 24,
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

  Widget _buildSummaryPaceHeartItem(String value, String unit, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 30.5,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.35,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8B88B5),
            textStyle: const TextStyle(letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
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
