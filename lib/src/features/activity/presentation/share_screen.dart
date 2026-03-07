import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../main.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../generated/l10n/app_localizations.dart';

class ShareScreen extends ConsumerStatefulWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;
  final List<LatLng> routePoints;
  final String userName;
  final String? profilePictureUrl;

  const ShareScreen({
    super.key,
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
    required this.routePoints,
    required this.userName,
    this.profilePictureUrl,
  });

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _photoCardFullHeight = false;
  final Map<int, String> _pickedImages = {};
  final ImagePicker _imagePicker = ImagePicker();

  final GlobalKey _card0Key = GlobalKey();
  final GlobalKey _card1Key = GlobalKey();
  final GlobalKey _card2Key = GlobalKey();

  // page 0 = dynamic workout card; page 1 = photo card; page 2 = polaroid card; pages 3–10 = template images
  final List<String> _templateImages = [];

  int get _totalPages => 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.80);
    
    // Clear any persistent notifications/snackbars from previous screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
      scaffoldMessengerKey.currentState?.clearSnackBars();
      
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

  Future<void> _captureAndShare() async {
    final GlobalKey key = [_card0Key, _card1Key, _card2Key][_currentPage];
    try {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tryd_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                  l10n.chooseFromGallery,
                  style: isRTL ? GoogleFonts.cairo() : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _pickedImages[_currentPage] = image.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(
                  l10n.takeAPhoto,
                  style: isRTL ? GoogleFonts.cairo() : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _pickedImages[_currentPage] = image.path;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangToggle(double scale) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(localeProvider.notifier).setLocale(Locale(value));
      },
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: Offset(0, 40 * scale),
      constraints: BoxConstraints(minWidth: 170 * scale),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'en',
          height: 44 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 2 * scale),
          child: Row(children: [
            Text('English',
                style: GoogleFonts.lexendDeca(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: !isAr ? const Color(0xFF900EBF) : const Color(0xFF24252C))),
            const Spacer(),
            if (!isAr) Icon(Icons.check_rounded, size: 18 * scale, color: const Color(0xFF900EBF)),
          ]),
        ),
        PopupMenuItem(
          value: 'ar',
          height: 44 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 2 * scale),
          child: Row(children: [
            Text('العربية',
                style: GoogleFonts.cairo(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: isAr ? const Color(0xFF900EBF) : const Color(0xFF24252C))),
            const Spacer(),
            if (isAr) Icon(Icons.check_rounded, size: 18 * scale, color: const Color(0xFF900EBF)),
          ]),
        ),
      ],
      child: SizedBox(
        width: 44 * scale,
        height: 44 * scale,
        child: Center(
          child: Icon(Icons.language_rounded, size: 26 * scale, color: const Color(0xFF24252C)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    final isTablet = screenWidth > 600;

    const double smallScale  = 0.62;
    const double mediumScale = 0.85;
    const double largeScale  = 0.95;
    const double tabletScale = 1.0;

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
            ? 0.58
            : screenHeight < 850
                ? 0.66
                : 0.60;

    if (_pageController.viewportFraction != targetFraction) {
      final oldPage = _currentPage;
      _pageController.dispose();
      _pageController = PageController(viewportFraction: targetFraction, initialPage: oldPage);
    }

    final l10n = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),

          // Page gallery
          SafeArea(
            child: Column(
              children: [
                 SizedBox(height: (screenHeight < 700 ? 50 : 70) * scale),
                Expanded(
                  child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _totalPages,
                    padEnds: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 4 * scale),
                          color: const Color(0xFF900EBF),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double availW = constraints.maxWidth;
                              final double availH = constraints.maxHeight;
                              return Stack(
                                children: [
                                  Center(
                                    child: RepaintBoundary(
                                      key: _card0Key,
                                      child: _photoCardFullHeight
                                        ? SizedBox(
                                            width: availW,
                                            height: availH,
                                            child: _PhotoShareCard(
                                              totalTime: widget.totalTime,
                                              avgPace: widget.avgPace,
                                              distance: widget.distance,
                                              date: widget.date,
                                              pickedImagePath: _pickedImages[0],
                                              onImagePicked: _pickImage,
                                              isFullHeight: true,
                                            ),
                                          )
                                        : AspectRatio(
                                            aspectRatio: 4 / 5,
                                            child: _PhotoShareCard(
                                              totalTime: widget.totalTime,
                                              avgPace: widget.avgPace,
                                              distance: widget.distance,
                                              date: widget.date,
                                              pickedImagePath: _pickedImages[0],
                                              onImagePicked: _pickImage,
                                              isFullHeight: false,
                                            ),
                                          ),
                                    ),
                                  ),
                                  // Toggle inside the page, right side
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: _AspectToggle(
                                      isFullHeight: _photoCardFullHeight,
                                      onFourFive: () => setState(() => _photoCardFullHeight = false),
                                      onFull: () => setState(() => _photoCardFullHeight = true),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }
                      if (index == 1) {
                        return RepaintBoundary(
                          key: _card1Key,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 10 * scale),
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/share.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 4 / 5,
                                child: _PolaroidShareCard(
                                  totalTime: widget.totalTime,
                                  avgPace: widget.avgPace,
                                  distance: widget.distance,
                                  date: widget.date,
                                  pickedImagePath: _pickedImages[1],
                                  onImagePicked: _pickImage,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      if (index == 2) {
                        return RepaintBoundary(
                          key: _card2Key,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 10 * scale),
                            color: const Color(0xFF900EBF),
                            child: _WorkoutShareCard(
                              totalTime: widget.totalTime,
                              avgPace: widget.avgPace,
                              distance: widget.distance,
                              date: widget.date,
                              routePoints: widget.routePoints,
                              userName: widget.userName,
                              profilePictureUrl: widget.profilePictureUrl,
                            ),
                          ),
                        );
                      }
                      return const SizedBox(); // Fallback
                    },
                  ),
                  ),
                ),
                SizedBox(height: 150 * scale),
              ],
            ),
          ),

          // Header overlay
           Positioned(
             top: MediaQuery.of(context).padding.top + 10 * scale,
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
                          scaleX: isRTL ? 1.0 : -1.0,
                          child: CustomArrowIcon(size: 24 * scale, color: const Color(0xFF24252C)),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    l10n.shareButton,
                    style: isRTL
                        ? GoogleFonts.cairo(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: const Color(0xFF24252C))
                        : GoogleFonts.lexend(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: const Color(0xFF24252C)),
                  ),
                  _buildLangToggle(scale),
                ],
              ),
            ),
          ),

          // Footer overlay
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20 * scale,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
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
                      padding: EdgeInsets.symmetric(horizontal: 14 * scale),
                      child: Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: GoogleFonts.lexend(
                          fontSize: 17 * scale,
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
                ),
                SizedBox(height: 8 * scale),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26 * scale),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: isTablet ? 400.0 : double.infinity),
                      child: (_currentPage == 0 || _currentPage == 1)
                          ? Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      height: 46 * scale,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15 * scale),
                                        border: Border.all(color: const Color(0xFF900EBF), width: 1.5),
                                      ),
                                      alignment: Alignment.center,
                                       child: Text(
                                         _pickedImages[_currentPage] == null ? l10n.uploadImage : l10n.changePicture,
                                         style: isRTL
                                             ? GoogleFonts.cairo(fontSize: 14 * scale, fontWeight: FontWeight.w600, color: const Color(0xFF900EBF))
                                             : GoogleFonts.lexendDeca(fontSize: 14 * scale, fontWeight: FontWeight.w600, color: const Color(0xFF900EBF)),
                                       ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Expanded(
                                  child: Opacity(
                                    opacity: _pickedImages[_currentPage] == null ? 0.5 : 1.0,
                                    child: GradientButton(
                                      onPressed: _pickedImages[_currentPage] == null
                                          ? () {}
                                          : _captureAndShare,
                                      text: l10n.shareButton,
                                      width: double.infinity,
                                      height: 46 * scale,
                                      textStyle: isRTL
                                          ? GoogleFonts.cairo(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: Colors.white)
                                          : GoogleFonts.lexendDeca(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: Colors.white),
                                      showIcon: false,
                                      showShadow: false,
                                    ),
                                  ),
                                ),
                              ],
                            )
                           : GradientButton(
                               onPressed: _captureAndShare,
                               text: l10n.shareButton,
                               width: double.infinity,
                               height: 46 * scale,
                               textStyle: isRTL
                                   ? GoogleFonts.cairo(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: Colors.white)
                                   : GoogleFonts.lexendDeca(fontSize: 18 * scale, fontWeight: FontWeight.w600, color: Colors.white),
                               showIcon: false,
                               showShadow: false,
                             ),
                    ),
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

// ─── Dynamic Workout Card (Page 1) ───────────────────────────────────────────

class _WorkoutShareCard extends StatefulWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;
  final List<LatLng> routePoints;
  final String userName;
  final String? profilePictureUrl;

  const _WorkoutShareCard({
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
    required this.routePoints,
    required this.userName,
    this.profilePictureUrl,
  });

  @override
  State<_WorkoutShareCard> createState() => _WorkoutShareCardState();
}

class _WorkoutShareCardState extends State<_WorkoutShareCard> {
  final MapController _mapController = MapController();
  late final LatLng _center;
  late final double _navAngle;

  @override
  void initState() {
    super.initState();
    // Pre-compute center once
    _center = widget.routePoints.isNotEmpty
        ? widget.routePoints[widget.routePoints.length ~/ 2]
        : const LatLng(29.2882, 47.9015);

    // Pre-compute navigation bearing once
    if (widget.routePoints.length > 1) {
      final p1 = widget.routePoints[widget.routePoints.length - 2];
      final p2 = widget.routePoints.last;
      final double dLon = (p2.longitude - p1.longitude) * (math.pi / 180);
      final double lat1 = p1.latitude * (math.pi / 180);
      final double lat2 = p2.latitude * (math.pi / 180);
      final y = math.sin(dLon) * math.cos(lat2);
      final x = math.cos(lat1) * math.sin(lat2) -
                math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
      _navAngle = math.atan2(y, x) - (math.pi / 4);
    } else {
      _navAngle = 0.0;
    }

    // Pre-cache profile image
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty) {
        precacheImage(NetworkImage(widget.profilePictureUrl!), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availH = constraints.maxHeight;
        final double availW = constraints.maxWidth;

        final double cardScale  = (availH / 550).clamp(0.60, 1.0);
        final double mapHeight  = availH * 0.35;
        final double logoH      = 40 * cardScale; 
        final double hPad       = 12 * cardScale;
        final double vPad       = 7  * cardScale; 
        final double radius     = 18 * cardScale;
        final double avatarSize = 20 * cardScale;

        final LatLng center = _center;

        return Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 16), // ratio 1.6
            // ── Logo ──
            Image.asset('assets/images/logo-full-white.png', height: logoH, fit: BoxFit.contain),
            SizedBox(height: vPad * 2.8),

            // ── White card ──
            Center(
              child: SizedBox(
                width: availW * 0.90,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Glow shadow
                    Positioned(
                      bottom: -20,
                      left: -15,
                      right: -15,
                      child: Image.asset(
                        'assets/images/shadow.png',
                        width: double.infinity,
                        height: 50,
                        fit: BoxFit.fill,
                      ),
                    ),
                    // Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile + Date row
                            Padding(
                              padding: EdgeInsets.fromLTRB(hPad, vPad * 1.0, hPad, vPad * 0.5),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: avatarSize / 2,
                                    backgroundColor: Colors.black12,
                                    backgroundImage: (widget.profilePictureUrl != null &&
                                            widget.profilePictureUrl!.isNotEmpty)
                                        ? NetworkImage(widget.profilePictureUrl!) as ImageProvider
                                        : const AssetImage('assets/images/profile.png'),
                                  ),
                                  SizedBox(width: 5 * cardScale),
                                  Expanded(
                                    child: Text(
                                      widget.userName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.lexend(
                                        fontSize: 8 * cardScale, 
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6 * cardScale),
                                  Text(
                                    widget.date,
                                    style: GoogleFonts.roboto(
                                      fontSize: 9.5 * cardScale, 
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Map
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: hPad, vertical: vPad * 0.6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(radius * 0.6),
                                child: SizedBox(
                                  height: mapHeight,
                                  child: FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: center,
                                      initialZoom: 15,
                                      interactionOptions: const InteractionOptions(
                                          flags: InteractiveFlag.none),
                                      onMapReady: () {
                                        if (widget.routePoints.length > 1) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            try {
                                              _mapController.fitCamera(
                                                CameraFit.coordinates(
                                                  coordinates: widget.routePoints,
                                                  padding: const EdgeInsets.all(30),
                                                  maxZoom: 17,
                                                ),
                                              );
                                            } catch (_) {}
                                          });
                                        }
                                      },
                                    ),
                                    children: [
                                      ColorFiltered(
                                        colorFilter: const ColorFilter.matrix([
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0.2126, 0.7152, 0.0722, 0, 0,
                                          0,      0,      0,      1, 0,
                                        ]),
                                        child: TileLayer(
                                          urlTemplate:
                                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                          subdomains: const ['a', 'b', 'c', 'd'],
                                          userAgentPackageName: 'com.tryd.app',
                                          maxNativeZoom: 18,
                                          maxZoom: 18,
                                          keepBuffer: 4,
                                          panBuffer: 2,
                                        ),
                                      ),
                                      if (widget.routePoints.length > 1)
                                        PolylineLayer(
                                          polylines: [
                                            Polyline(
                                              points: widget.routePoints,
                                              strokeWidth: 2.0,
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
                                              width: 10,
                                              height: 10,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.transparent,
                                                  border: Border.all(
                                                      color: const Color(0xFF333333),
                                                      width: 2.0),
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 3,
                                                    height: 3,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFF333333),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (widget.routePoints.isNotEmpty)
                                              Marker(
                                                point: widget.routePoints.last,
                                                width: 18,
                                                height: 18,
                                                child: Transform.rotate(
                                                  angle: _navAngle,
                                                  child: const Icon(
                                                    Icons.navigation,
                                                    size: 18,
                                                    color: Color(0xFF333333),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Stats row
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  hPad, vPad * 0.5, hPad, vPad * 1.5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatItem(value: widget.totalTime, label: AppLocalizations.of(context)!.totalTimeLabel, scale: cardScale),
                                  _StatItem(value: widget.avgPace,   label: AppLocalizations.of(context)!.avgPaceShort,   scale: cardScale),
                                  _StatItem(
                                      value: '${widget.distance} ${AppLocalizations.of(context)!.kmSuffix}',
                                      label: AppLocalizations.of(context)!.distanceShort, scale: cardScale),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 30), // ratio 3.0
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final double scale;
  const _StatItem({required this.value, required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 8 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photo Share Card (Page 2) ────────────────────────────────────────────────

class _PhotoShareCard extends StatelessWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;
  final String? pickedImagePath;
  final VoidCallback onImagePicked;
  final bool isFullHeight;

  const _PhotoShareCard({
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
    this.pickedImagePath,
    required this.onImagePicked,
    this.isFullHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        final double s = w / 750;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background placeholder or Image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: pickedImagePath != null 
                        ? FileImage(File(pickedImagePath!)) as ImageProvider
                        : const AssetImage('assets/images/image.png'), 
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Top gradient
                Positioned(
                  left: 0, right: 0, top: 0,
                  height: h * 0.505,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.transparent, Color(0x77000000)], // Reduced opacity
                      ),
                    ),
                  ),
                ),

              // Bottom gradient
                Positioned(
                  left: 0, right: 0,
                  top: h * 0.443,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x77000000)], // Reduced opacity
                      ),
                    ),
                  ),
                ),

              // Logo
              Positioned(
                top: (isFullHeight ? 80 : 50) * s,
                left: 0, right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo-full-white.png',
                    height: (isFullHeight ? 120 : 80) * s,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Date
              Positioned(
                left: 50 * s,
                bottom: 200 * s,
                child: Text(
                  date,
                  style: GoogleFonts.roboto(
                    fontSize: 26 * s,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),

              // Stats row
              Positioned(
                left: 50 * s,
                right: 50 * s,
                bottom: 70 * s,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _BigStat(value: totalTime, label: AppLocalizations.of(context)!.totalTimeLabel, s: s),
                    _BigStat(value: avgPace,   label: AppLocalizations.of(context)!.avgPaceShort,   s: s),
                    _BigStat(value: '$distance${AppLocalizations.of(context)!.kmSuffix}', label: AppLocalizations.of(context)!.distanceShort, s: s),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Template Slide Card (Pages 2–9) ─────────────────────────────────────────

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

// ─── Stats Share Card (Page 2) ────────────────────────────────────────────────

class _StatsShareCard extends StatelessWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;

  const _StatsShareCard({
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight;
        final double w = constraints.maxWidth;
        final double s = h / 1080;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1C1435), Color(0xFF0D1B2A), Color(0xFF0A0F1E)],
                  ),
                ),
              ),

              // Glow blobs
              Positioned(left: w * 0.07, top: h * 0.19, child: _GlowBlob(size: 74 * s, blur: 75 * s, color: const Color(0xFF5F27FF))),
              Positioned(left: w * 0.80, top: h * 0.21, child: _GlowBlob(size: 60 * s, blur: 75 * s, color: const Color(0xFF7C46F0))),
              Positioned(left: w * 0.77, top: h * 0.31, child: _GlowBlob(size: 118 * s, blur: 75 * s, color: const Color(0xFFEDF046))),
              Positioned(left: -10 * s,  top: h * 0.50, child: _GlowBlob(size: 96 * s, blur: 75 * s, color: const Color(0xFF46BDF0))),
              Positioned(left: w * 0.55, top: h * 0.71, child: _GlowBlob(size: 58 * s, blur: 65 * s, color: const Color(0xFFF0B646))),

              // Bottom dark gradient
              Positioned(
                left: 0, right: 0,
                top: h * 0.45,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD000000)],
                    ),
                  ),
                ),
              ),

              // Logo
              Positioned(
                top: 25 * s,
                left: 0, right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo-full-white.png',
                    height: 80 * s,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Date
              Positioned(
                left: 50 * s,
                top: h * 0.695,
                child: Text(
                  date,
                  style: GoogleFonts.roboto(
                    fontSize: 26 * s,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),

              // Stats row
              Positioned(
                left: 50 * s,
                right: 50 * s,
                top: h * 0.792,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _BigStat(value: totalTime, label: 'Total Time', s: s),
                    _BigStat(value: avgPace,   label: 'Avg pace',   s: s),
                    _BigStat(value: '${distance}km', label: 'Distance', s: s),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size, blur;
  final Color color;
  const _GlowBlob({required this.size, required this.blur, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value, label;
  final double s;
  const _BigStat({required this.value, required this.label, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: 50 * s,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        SizedBox(height: 6 * s),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 24 * s,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ─── Aspect Ratio Toggle ──────────────────────────────────────────────────────

class _AspectToggle extends StatelessWidget {
  final bool isFullHeight;
  final VoidCallback onFourFive;
  final VoidCallback onFull;

  const _AspectToggle({
    required this.isFullHeight,
    required this.onFourFive,
    required this.onFull,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A1A),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onFourFive,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: !isFullHeight ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 11,
                    height: 13,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: !isFullHeight ? const Color(0xFF900EBF) : Colors.white60,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '4:5',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: !isFullHeight ? const Color(0xFF900EBF) : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          GestureDetector(
            onTap: onFull,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isFullHeight ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 14,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isFullHeight ? const Color(0xFF900EBF) : Colors.white60,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Full',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isFullHeight ? const Color(0xFF900EBF) : Colors.white60,
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

// ─── Polaroid Share Card (Page 3) ────────────────────────────────────────────────

class _PolaroidShareCard extends StatelessWidget {
  final String totalTime;
  final String avgPace;
  final String distance;
  final String date;
  final String? pickedImagePath;
  final VoidCallback onImagePicked;

  const _PolaroidShareCard({
    required this.totalTime,
    required this.avgPace,
    required this.distance,
    required this.date,
    this.pickedImagePath,
    required this.onImagePicked,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        final double s = w / 358.0; // using a base width for scaling

        // Rotation according to user spec (6.84 degrees ~ 0.119 radians)
        const double rotationAngle = 6.84 * (3.1415926535897932 / 180.0);

        return ClipRect(
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Inner content rotated
                Center(
                  child: Transform.rotate(
                    angle: rotationAngle,
                    child: Container(
                      width: 296 * s,
                      height: 337 * s,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.6 * s),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x1F636363), // rgba(99, 99, 99, 0.12)
                            blurRadius: 27.12 * s,
                            spreadRadius: 2.47 * s,
                            offset: Offset(0, 2.47 * s),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // The internal Image Frame
                          Positioned(
                            left: 10 * s,
                            top: 10 * s,
                            right: 10 * s,
                            bottom: 55 * s, // thicker bottom border for polaroid
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12 * s),
                              child: GestureDetector(
                                onTap: onImagePicked,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF333333),
                                    image: DecorationImage(
                                      image: pickedImagePath != null 
                                          ? FileImage(File(pickedImagePath!)) as ImageProvider
                                          : const AssetImage('assets/images/image.png'), 
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                    // Gradient Overlay (top and bottom)
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0x88000000), // Reduced opacity
                                          Colors.transparent, 
                                          Colors.transparent,
                                          Color(0x66000000), // Reduced opacity
                                        ],
                                        stops: [0.0, 0.4, 0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Date
                          Positioned(
                            left: 21 * s,
                            bottom: 125 * s,
                            child: Text(
                              date,
                              style: GoogleFonts.lexend(
                                fontSize: 12 * s, // Slightly smaller
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Stats row overlaying image
                          Positioned(
                            left: 20 * s,
                            right: 20 * s,
                            bottom: 70 * s, // just above the bottom white space
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _PolaroidStatItem(
                                  value: totalTime,
                                  label: AppLocalizations.of(context)!.totalTimeLabel,
                                  fontSize: 20 * s,
                                  labelSize: 10 * s,
                                ),
                                _PolaroidStatItem(
                                  value: avgPace,
                                  label: AppLocalizations.of(context)!.avgPaceShort,
                                  fontSize: 20 * s,
                                  labelSize: 10 * s,
                                ),
                                _PolaroidStatItem(
                                  value: '$distance${AppLocalizations.of(context)!.kmSuffix}',
                                  label: AppLocalizations.of(context)!.distanceShort,
                                  fontSize: 20 * s,
                                  labelSize: 10 * s,
                                ),
                              ],
                            ),
                          ),
                          
                          // Logo at the top
                          Positioned(
                            top: 21 * s,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo-full-white.png',
                                height: 30 * s,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PolaroidStatItem extends StatelessWidget {
  final String value;
  final String label;
  final double fontSize;
  final double labelSize;
  const _PolaroidStatItem({required this.value, required this.label, required this.fontSize, required this.labelSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, // Align like Page 2
      children: [
        Text(
          value,
          style: GoogleFonts.oswald(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        SizedBox(height: 6 * (fontSize / 52)), // proportion based on Page 2
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: labelSize,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
