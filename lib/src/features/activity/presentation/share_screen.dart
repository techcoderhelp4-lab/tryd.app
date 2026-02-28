import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/gradient_button.dart';

class ShareScreen extends StatefulWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;
  final List<LatLng> routePoints;

  const ShareScreen({
    super.key,
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
    required this.routePoints,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Page 0 = custom workout card; pages 1-9 = template images
  final List<String> _templateImages = [
    'assets/images/share-.png',
    'assets/images/share2.png',
    'assets/images/share3.png',
    'assets/images/share4.png',
    'assets/images/share5.png',
    'assets/images/share6.png',
    'assets/images/share7.png',
    'assets/images/share8.png',
    'assets/images/share9.png',
  ];

  int get _totalPages => 1 + _templateImages.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.80);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final img in _templateImages) {
        precacheImage(AssetImage(img), context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    final isTablet = screenWidth > 600;

    const double smallScale  = 0.68;
    const double mediumScale = 0.92;
    const double largeScale  = 1.05;
    const double tabletScale = 1.05;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 700
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    final double targetFraction = isTablet
        ? 0.45
        : screenHeight < 700
            ? 0.59
            : screenHeight < 850
                ? 0.68
                : 0.61;

    if (_pageController.viewportFraction != targetFraction) {
      final oldPage = _currentPage;
      _pageController.dispose();
      _pageController = PageController(viewportFraction: targetFraction, initialPage: oldPage);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // White Background
          Positioned.fill(child: Container(color: Colors.white)),

          // Page gallery
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 70 * scale),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _totalPages,
                    padEnds: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 20 * scale),
                          decoration: const BoxDecoration(
                            color: Color(0xFF900EBF),
                          ),
                          child: _WorkoutShareCard(
                            totalTime: widget.totalTime,
                            avgPace: widget.avgPace,
                            distance: widget.distance,
                            date: widget.date,
                            routePoints: widget.routePoints,
                          ),
                        );
                      }
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 20 * scale),
                        child: _SlideCard(image: _templateImages[index - 1]),
                      );
                    },
                  ),
                ),
                SizedBox(height: 150 * scale),
              ],
            ),
          ),

          // Header overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 26 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44 * scale,
                      height: 44 * scale,
                      color: Colors.transparent,
                      child: Center(
                        child: Transform.scale(
                          scaleX: -1,
                          child: CustomArrowIcon(size: 24 * scale, color: const Color(0xFF24252C)),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "Share",
                    style: GoogleFonts.lexend(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                  ),
                  SizedBox(width: 44 * scale),
                ],
              ),
            ),
          ),

          // Footer overlay
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20 * scale,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _currentPage > 0
                          ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut)
                          : null,
                      child: Transform.scale(
                        scaleX: -1,
                        child: CustomArrowIcon(
                          size: 28 * scale,
                          color: _currentPage > 0 ? Colors.black87 : Colors.black26,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: GoogleFonts.lexend(
                          fontSize: 19 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _currentPage < _totalPages - 1
                          ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut)
                          : null,
                      child: CustomArrowIcon(
                        size: 28 * scale,
                        color: _currentPage < _totalPages - 1 ? Colors.black87 : Colors.black26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26 * scale),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: isTablet ? 400.0 : double.infinity),
                      child: GradientButton(
                        onPressed: () {},
                        text: "Share",
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workout Card (Page 1) ────────────────────────────────────────────────────

class _WorkoutShareCard extends StatefulWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;
  final List<LatLng> routePoints;

  const _WorkoutShareCard({
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
    required this.routePoints,
  });

  @override
  State<_WorkoutShareCard> createState() => _WorkoutShareCardState();
}

class _WorkoutShareCardState extends State<_WorkoutShareCard> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.routePoints.isNotEmpty
        ? widget.routePoints[widget.routePoints.length ~/ 2]
        : const LatLng(29.2882, 47.9015);

    return Center(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Purple glow shadow at bottom of card
          Positioned(
            bottom: -6,
            left: 20,
            right: 20,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF590974).withOpacity(0.9),
                    blurRadius: 18,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),

          // White card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Logo + Date
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          widget.date,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map
                  SizedBox(
                    height: 280,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                        onMapReady: () {
                          if (widget.routePoints.length > 1) {
                            try {
                              _mapController.fitCamera(
                                CameraFit.coordinates(
                                  coordinates: widget.routePoints,
                                  padding: const EdgeInsets.all(32),
                                  maxZoom: 18,
                                ),
                              );
                            } catch (_) {}
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.tryd.app',
                        ),
                        if (widget.routePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: widget.routePoints,
                                strokeWidth: 4,
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                                color: const Color(0xFFF83A71),
                              ),
                            ],
                          ),
                        if (widget.routePoints.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.routePoints.first,
                                width: 14,
                                height: 14,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color(0xFF333333), width: 2.5),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF333333),
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

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(value: widget.totalTime, label: 'Total Time'),
                        _StatItem(value: widget.avgPace, label: 'Avg pace'),
                        _StatItem(value: widget.distance, label: 'Distance'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: const Color(0xFF8B88B5),
          ),
        ),
      ],
    );
  }
}

// ─── Template Slide Card (Pages 2–10) ────────────────────────────────────────

class _SlideCard extends StatefulWidget {
  final String image;
  const _SlideCard({required this.image});

  @override
  State<_SlideCard> createState() => _SlideCardState();
}

class _SlideCardState extends State<_SlideCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Image.asset(
      widget.image,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 800,
      gaplessPlayback: true,
    );
  }
}
