import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show Point;
import '../widgets/custom_bottom_navigation.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  int _selectedIndex = 1;
  bool isRunning = false;
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(29.3759, 47.9774);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
            height: screenHeight * 0.5,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
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
                MarkerLayer(
                  markers: [
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
                          final newPixel = Point(
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
                  ],
                ),
              ],
            ),
          ),
          // Content section
          Positioned(
            top: screenHeight * 0.5,
            left: 0,
            right: 0,
            bottom: 122,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 72),
                  child: Column(
                    children: [
                      _buildStatsSection(),
                      const SizedBox(height: 20),
                      _buildPaceHeartRateCard(),
                      const SizedBox(height: 16),
                      _buildMediaControlsCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // START button
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 48,
            top: screenHeight * 0.5 - 48,
            child: _buildStartButton(),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          isRunning = !isRunning;
        });
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFF900EBF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 11.9,
              spreadRadius: 6,
              color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'START',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
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
            color: const Color(0xFF6F86B5).withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.04),
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
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.list_rounded, size: 31, color: const Color(0xFF96AAD2)),
          Icon(Icons.skip_previous, size: 29, color: const Color(0xFF96AAD2)),
          _buildPlayPauseButton(),
          Icon(Icons.skip_next, size: 29, color: const Color(0xFF96AAD2)),
          Icon(Icons.volume_off, size: 26, color: const Color(0xFF96AAD2)),
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
            color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
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
