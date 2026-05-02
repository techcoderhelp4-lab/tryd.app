// running_screen.dart
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../widgets/gradient_button.dart';
import '../../../../../widgets/custom_gradient_button.dart';
import '../../../shell/main_shell.dart' show isCountdownActiveProvider, isWorkoutActiveProvider, mainTabProvider, workoutNavGuardProvider;
import '../../notifications/data/real_time_notification_service.dart';
import '../../profile/data/user_repository.dart';
import '../data/gps_cache_service.dart';
import 'running_screen_logic1.dart';
import 'running_screen_logic2.dart';
import 'share_screen.dart';
import 'activity_screen.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';

class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

enum ActivityType { running, walking, cycling }

class _RunningScreenState extends ConsumerState<RunningScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late RunningCoreLogic _coreLogic;
  late RunningSupportLogic _supportLogic;

  ActivityType _selectedActivity = ActivityType.running;

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = _coreLogic.runningState;
      ref.read(isCountdownActiveProvider.notifier).state =
          state == RunningState.countdown;
      // Lock tab-switches and swipes while run is in progress.
      ref.read(isWorkoutActiveProvider.notifier).state =
          state == RunningState.running || state == RunningState.paused;
    });
  }

  @override
  void initState() {
    super.initState();

    _supportLogic = RunningSupportLogic(
      ref: ref,
      context: context,
      isMounted: () => mounted,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    _coreLogic = RunningCoreLogic(
      ref: ref,
      context: context,
      onStateChanged: _onStateChanged,
      speak: _supportLogic.speak,
    );

    // LINK core to support for health init
    _supportLogic.setCoreLogic(_coreLogic);

    _supportLogic.init(
      onResumed: _onAppResumed,
      onPaused: _onAppPaused,
    );

    _coreLogic.loadPendingRun(
      _supportLogic.showResumeDialog,
      onActivityTypeRestored: (type) {
        if (!mounted) return;
        setState(() {
          _selectedActivity = switch (type) {
            'walk' => ActivityType.walking,
            'cycling' => ActivityType.cycling,
            _ => ActivityType.running,
          };
        });
      },
    );

    // Register the end-run guard so the shell can show the modal when
    // the user tries to swipe or tap away while running.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(workoutNavGuardProvider.notifier).state = () async {
        final result = await _supportLogic.showExitConfirmation();
        if (result == null) return false;
        await _coreLogic.finishRun();
        return true;
      };
      // First-visit permission checks — subsequent visits handled via ref.listen in build
      _supportLogic.checkAllPermissions();
    });
  }

  void _onAppResumed() {
    if (_coreLogic.runningState == RunningState.running) {
      _coreLogic.startLocationTracking();
    }
    if (mounted) _supportLogic.checkAllPermissions();
  }

  void _onAppPaused() {
    // Handle background transitions if needed
  }

  @override
  void dispose() {
    // Unregister the nav guard and clear workout-active flags.
    ref.read(workoutNavGuardProvider.notifier).state = null;
    ref.read(isWorkoutActiveProvider.notifier).state = false;
    ref.read(isCountdownActiveProvider.notifier).state = false;
    _coreLogic.dispose();
    _supportLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Fire permission checks every time this tab becomes active (swipe, tap, or deep-link).
    // index 1 = RunningScreen in the PageView.
    ref.listen<int>(mainTabProvider, (previous, current) {
      if (current == 1 && previous != 1 && mounted) {
        ref.read(gpsCacheServiceProvider).startWarmUp();
        _supportLogic.checkAllPermissions();
      }
    });

    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    final isTablet = screenWidth > 600;

    const double smallScale = 0.74;
    const double mediumScale = 0.84;
    const double largeScale = 0.94;
    const double tabletScale = 0.90;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _supportLogic.onPopInvoked(
            isRunning: _coreLogic.runningState == RunningState.running ||
                _coreLogic.runningState == RunningState.paused,
            isFinished: _coreLogic.runningState == RunningState.finished,
            finishRun: _coreLogic.finishRun,
          );
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
                ignoring: _coreLogic.runningState == RunningState.running ||
                    _coreLogic.runningState == RunningState.countdown,
                child: FlutterMap(
                  mapController: _coreLogic.mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(29.2882, 47.9015),
                    initialZoom: 18.8,
                    minZoom: 5.0,
                    maxZoom: 20.0,
                    onMapReady: () {
                      try {
                        _coreLogic.mapController.fitCamera(
                          CameraFit.coordinates(
                            coordinates: [_coreLogic.currentLocation],
                            padding: _coreLogic.getMapPadding(),
                            maxZoom: 18.8,
                            forceIntegerZoomLevel: false,
                          ),
                        );
                      } catch (_) {}
                    },
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && _coreLogic.isAutoFollow) {
                        _coreLogic.isAutoFollow = false;
                        _coreLogic.onStateChanged();

                        _coreLogic.autoFollowResumeTimer?.cancel();
                        _coreLogic.autoFollowResumeTimer = Timer(const Duration(seconds: 5), () {
                          if (mounted && _coreLogic.runningState == RunningState.running) {
                            _coreLogic.isAutoFollow = true;
                            _coreLogic.onStateChanged();
                          }
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.tryd.app',
                    ),
                    if (_coreLogic.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              ..._coreLogic.routePoints,
                              _coreLogic.currentLocation,
                            ],
                            strokeWidth: 5.0,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                            color: const Color(0xFFF83A71),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_coreLogic.startLocation != null &&
                            _coreLogic.runningState != RunningState.idle &&
                            _coreLogic.runningState != RunningState.countdown)
                          Marker(
                            point: _coreLogic.startLocation!,
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
                        if (_coreLogic.shouldShowArrow)
                          Marker(
                            point: _coreLogic.currentLocation,
                            width: isTablet ? 48.0 : 40.0,
                            height: isTablet ? 48.0 : 40.0,
                            child: Transform.rotate(
                              angle: _coreLogic.getArrowRotation(_coreLogic.lastPosition),
                              child: Icon(
                                Icons.navigation,
                                color: const Color(0xFF333333),
                                size: isTablet ? 36.0 : 32.0,
                              ),
                            ),
                          ),
                        if (_coreLogic.runningState == RunningState.idle ||
                            _coreLogic.runningState == RunningState.countdown)
                          Marker(
                            point: _coreLogic.currentLocation,
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

            // Locate Me Button
            if (_coreLogic.runningState != RunningState.finished &&
                _coreLogic.runningState != RunningState.countdown)
              ListenableBuilder(
                listenable: _coreLogic.sheetController,
                builder: (context, child) {
                  double sheetSize = _coreLogic.sheetHeightIdle;
                  if (_coreLogic.sheetController.isAttached) {
                    sheetSize = _coreLogic.sheetController.size;
                  }
                  final bottomPadding =
                      (MediaQuery.of(context).size.height * sheetSize) + (isTablet ? 24.0 : 16.0);

                  return Positioned(
                    right: isTablet ? 24.0 : 16.0,
                    bottom: bottomPadding,
                    child: child!,
                  );
                },
                child: GestureDetector(
                  onTap: _coreLogic.locateMe,
                  child: Container(
                    width: isTablet ? 56.0 : 42.0,
                    height: isTablet ? 56.0 : 42.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(Icons.my_location,
                        color: const Color(0xFF900EBF), size: isTablet ? 28.0 : 20.0),
                  ),
                ),
              ),

            // Draggable Content section
            if (_coreLogic.runningState != RunningState.finished &&
                _coreLogic.runningState != RunningState.countdown)
              DraggableScrollableSheet(
                controller: _coreLogic.sheetController,
                initialChildSize: _coreLogic.runningState == RunningState.idle
                    ? _coreLogic.sheetHeightIdle
                    : _coreLogic.sheetHeightRunning,
                minChildSize: math.min(
                    _coreLogic.sheetHeightMin,
                    _coreLogic.runningState == RunningState.idle
                        ? _coreLogic.sheetHeightIdle
                        : _coreLogic.sheetHeightRunning),
                maxChildSize: _coreLogic.sheetHeightIdle,
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
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, -4),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: _coreLogic.runningState == RunningState.idle
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(top: (isTablet ? 28.0 : 22.0) * scale),
                        child: Column(
                          children: [
                            _buildStatsSection(scale, isTablet, l10n, fontScale),
                            SizedBox(height: (isTablet ? 20.0 : 16.0) * scale),
                            _buildPaceHeartRateCard(scale, isTablet, l10n, fontScale),
                            SizedBox(height: (isTablet ? 20.0 : 16.0) * scale),
                            _buildActivityTypeSelector(scale, isTablet, fontScale),
                            SizedBox(height: (isTablet ? 20.0 : 16.0) * scale),
                            _buildStartButton(scale, isTablet, l10n, fontScale),
                            SizedBox(height: (isTablet ? 14.0 : 10.0) * scale),
                            _buildMediaControlsCard(scale, isTablet),
                            SizedBox(height: (isTablet ? 40.0 : 32.0) * scale),
                          ],
                        ),
                      ),
                    );
                },
              ),

            // Summary View
            if (_coreLogic.runningState == RunningState.finished)
              _buildSummaryView(scale, isTablet, l10n, fontScale),

            // COUNTDOWN OVERLAY
            if (_coreLogic.runningState == RunningState.countdown)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF900EBF).withValues(alpha: 0.95),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_coreLogic.countdownSeconds),
                      tween: Tween(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            '${_coreLogic.countdownSeconds}',
                            style: GoogleFonts.tajawal(
                              fontSize: (isTablet ? 120.0 : 110.0) * scale,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Top navigation bar
            if (_coreLogic.runningState != RunningState.countdown)
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24.0 : 22.0 * scale,
                    vertical: isTablet ? 12.0 : 8.0 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBackButton(scale, isTablet, isAr),
                      const SizedBox.shrink(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final isActive = ref.read(isWorkoutActiveProvider);
                              if (isActive) {
                                final guard = ref.read(workoutNavGuardProvider);
                                if (guard != null) {
                                  final shouldLeave = await guard();
                                  if (!shouldLeave || !mounted) return;
                                }
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ActivityScreen()),
                              );
                            },
                            child: _buildTopIconButton(Icons.history, scale, isTablet),
                          ),
                          if (_coreLogic.runningState == RunningState.finished) ...[
                            SizedBox(width: isTablet ? 12.0 : 11.0),
                            GestureDetector(
                              onTap: () {
                                final now = DateTime.now();
                                const months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
                                final user = ref.read(userProfileProvider).value;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShareScreen(
                                      totalTime: _coreLogic.formatDuration(_coreLogic.seconds),
                                      avgPace: _coreLogic.formatPace(_coreLogic.avgPace),
                                      distance: _coreLogic.distance.toStringAsFixed(2),
                                      date: dateStr,
                                      routePoints: _coreLogic.routePoints,
                                      userName: user?.name ?? '',
                                      profilePictureUrl: user?.profilePicture,
                                    ),
                                  ),
                                );
                              },
                              child: _buildTopIconButton(Icons.share, scale, isTablet),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            if (_coreLogic.runningState != RunningState.finished &&
                _coreLogic.currentAccuracy > 35.0 &&
                _coreLogic.runningState != RunningState.idle)
              Positioned(
                top: MediaQuery.of(context).padding.top + (isTablet ? 70.0 : 60.0) * scale,
                left: isTablet ? 24.0 : 16.0,
                right: isTablet ? 24.0 : 16.0,
                child: _buildGPSStatusIndicator(scale, isTablet),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI Widget Builders
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStartButton(double scale, bool isTablet, AppLocalizations l10n, double fontScale) {
    final screenHeight = MediaQuery.of(context).size.height;
    double buttonSize = isTablet
        ? 80.0
        : screenHeight < 680
            ? 88.0
            : screenHeight < 850
                ? 85.0
                : 80.0;

    double scaledButtonSize = buttonSize * scale;

    switch (_coreLogic.runningState) {
      case RunningState.idle:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final hasLocation = await _supportLogic.checkLocationForStart();
            if (!hasLocation) return;
            _coreLogic.startCountdown();
          },
          child: Container(
            width: scaledButtonSize,
            height: scaledButtonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF900EBF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 11.9,
                  spreadRadius: isTablet ? 8 : 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                l10n.startRun,
                style: GoogleFonts.tajawal(
                  fontSize: 17.0 * scale * fontScale,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );

      case RunningState.countdown:
        return const SizedBox.shrink();

      case RunningState.running:
        final runningButtonSize = 75.0 * scale;
        return _RunHoldGradient(
          onAction: _coreLogic.pauseRun,
          child: Container(
            width: runningButtonSize,
            height: runningButtonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF900EBF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
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
        final stopWidth = 140.0 * scale;
        final stopHeight = 58.0 * scale;
        final playSize = 75.0 * scale;
        final playIconSize = (isTablet ? 38.0 : 34.0) * scale;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18.0 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomGradientButton(
                text: l10n.stopButton,
                onAction: _coreLogic.finishRun,
                width: stopWidth,
                height: stopHeight,
                textStyle: GoogleFonts.tajawal(
                  fontSize: 20.0 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 11.0 * scale),
              _RunHoldGradient(
                onAction: () {
                  _supportLogic.speak(l10n.letsGo);
                  _coreLogic.startRun();
                },
                child: Container(
                  width: playSize,
                  height: playSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB7B7B7).withValues(alpha: 0.25),
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
                        size: playIconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case RunningState.finished:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPauseIcon(double scale, bool isTablet) {
    final barWidth = (isTablet ? 9.0 : 8.0) * scale;
    final barHeight = (isTablet ? 22.0 : 19.0) * scale;
    final gap = (isTablet ? 6.0 : 4.0) * scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
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

  Widget _buildActivityTypeSelector(double scale, bool isTablet, double fontScale) {
    final hMargin = (isTablet ? 15.0 : 12.0) * scale;
    final innerPad = (isTablet ? 5.0 : 4.0) * scale;
    final br = (isTablet ? 12.0 : 10.0);
    final vPad = (isTablet ? 11.0 : 10.0) * scale;
    final iconSize = (isTablet ? 20.0 : 18.0) * scale;
    final labelSize = (isTablet ? 11.5 : 11.0) * scale * fontScale;
    final isDisabled = _coreLogic.runningState != RunningState.idle;

    const activeColor = Color(0xFF900EBF);
    const inactiveColor = Color(0xFF9B99B8);

    final types = [
      (ActivityType.running, Icons.directions_run_rounded, 'Running'),
      (ActivityType.walking, Icons.directions_walk_rounded, 'Walking'),
      (ActivityType.cycling, Icons.directions_bike_rounded, 'Cycling'),
    ];

    return Opacity(
      opacity: isDisabled ? 0.45 : 1.0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: hMargin),
        padding: EdgeInsets.all(innerPad),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEF5),
          borderRadius: BorderRadius.circular(br + 2),
        ),
        child: Row(
          children: List.generate(types.length, (i) {
            final (type, icon, label) = types[i];
            final isActive = _selectedActivity == type;
            return Expanded(
              child: GestureDetector(
                onTap: isDisabled ? null : () {
                  setState(() => _selectedActivity = type);
                  _coreLogic.activityType = switch (type) {
                    ActivityType.walking => 'walk',
                    ActivityType.cycling => 'cycling',
                    _ => 'run',
                  };
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: vPad),
                  decoration: isActive
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(br),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(br),
                        ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: iconSize,
                          color: isActive ? activeColor : inactiveColor),
                      SizedBox(height: 4.0 * scale),
                      Text(label,
                          style: GoogleFonts.tajawal(
                            fontSize: labelSize,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                            color: isActive ? activeColor : inactiveColor,
                            letterSpacing: 0.2,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatsSection(double scale, bool isTablet, AppLocalizations l10n, double fontScale) {
    final hMargin = (isTablet ? 15.0 : 12.0) * scale;
    final dividerHeight = (isTablet ? 40.0 : 36.0) * scale;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildStatItem(l10n.distanceLabel, _coreLogic.distance.toStringAsFixed(2),
                l10n.unitKm, scale, isTablet, fontScale),
          ),
          Container(width: 1, height: dividerHeight, color: const Color(0xFFE8ECF4)),
          Expanded(
            child: _buildStatItem(l10n.durationLabel,
                _coreLogic.formatDuration(_coreLogic.seconds), null, scale, isTablet, fontScale),
          ),
          Container(width: 1, height: dividerHeight, color: const Color(0xFFE8ECF4)),
          Expanded(
            child: _buildStatItem(l10n.caloriesLabel,
                _coreLogic.calories.toStringAsFixed(0), null, scale, isTablet, fontScale),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String? unit, double scale, bool isTablet,
      double fontScale) {
    final labelSize = (isTablet ? 11.5 : 11.0) * scale;
    final valueSize = (isTablet ? 22.0 : 22.0) * scale;
    final unitSize = (isTablet ? 13.0 : 13.0) * scale;
    final gap = (isTablet ? 4.0 : 3.0) * scale;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (isTablet ? 10.0 : 8.0) * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: labelSize * fontScale,
              fontWeight: FontWeight.w600,
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
                style: GoogleFonts.tajawal(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF1B2D51),
                ),
              ),
              if (unit != null) ...[
                SizedBox(width: 4 * scale),
                Text(
                  unit,
                  style: GoogleFonts.tajawal(
                    fontSize: unitSize * fontScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B88B5),
                  ),
                ),
              ],
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

  Widget _buildPaceHeartRateCard(double scale, bool isTablet, AppLocalizations l10n, double fontScale) {
    final double minHeight = (isTablet ? 80.0 : 72.0) * scale;
    final double margin = (isTablet ? 15.0 : 12.0) * scale;
    final double padding = (isTablet ? 18.0 : 14.0) * scale;
    final double dividerHeight = (isTablet ? 52.0 : 44.0) * scale;

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
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPaceHeartItem(
              _coreLogic.formatPace(_coreLogic.currentPace), l10n.unitMinKm, l10n.currentPaceLabel,
              scale, isTablet, fontScale),
          Container(width: 1, height: dividerHeight, color: const Color(0xFFE8ECF4)),
          SizedBox(width: isTablet ? 20.0 : 12.0),
          _buildPaceHeartItem(
              _coreLogic.avgBpm > 0 ? _coreLogic.avgBpm.toStringAsFixed(0) : '--',
              l10n.unitBpm, l10n.heartRateLabel, scale, isTablet, fontScale),
        ],
      ),
    );
  }

  Widget _buildPaceHeartItem(String value, String unit, String label, double scale,
      bool isTablet, double fontScale) {
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
              style: GoogleFonts.tajawal(
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: GoogleFonts.tajawal(
                fontSize: unitSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B88B5),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: labelSize * fontScale,
            fontWeight: FontWeight.w600,
            height: 1.1,
            color: const Color(0xFF8B88B5),
          ),
        ),
      ],
    );
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
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_supportLogic.songs.isNotEmpty || _supportLogic.currentSongName != null)
            Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 8.0 : 5.0),
              child: Text(
                _supportLogic.currentSongName ??
                    (_supportLogic.songs.isNotEmpty ? _supportLogic.songs[_supportLogic.currentSongIndex].title : ''),
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontSize: titleFontSize, color: const Color(0xFF6F86B5)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _supportLogic.pickSong,
                child: Icon(Icons.list_rounded, size: listIconSize, color: const Color(0xFF96AAD2)),
              ),
              GestureDetector(
                onTap: _supportLogic.prevSong,
                child: Icon(Icons.skip_previous, size: skipIconSize, color: const Color(0xFF96AAD2)),
              ),
              _buildPlayPauseButton(scale, isTablet),
              GestureDetector(
                onTap: _supportLogic.nextSong,
                child: Icon(Icons.skip_next, size: skipIconSize, color: const Color(0xFF96AAD2)),
              ),
              GestureDetector(
                onTap: _supportLogic.toggleMute,
                child: Icon(
                  _supportLogic.isMusicMuted ? Icons.volume_off : Icons.volume_up,
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
      onTap: _supportLogic.togglePlay,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF96AAD2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _supportLogic.isMusicPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildSummaryView(double scale, bool isTablet, AppLocalizations l10n, double fontScale) {
    final screenHeight = MediaQuery.of(context).size.height;

    const double summarySmall = 0.55;
    const double summaryMedium = 0.75;
    const double summaryLarge = 0.85;
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
              _buildSummaryStatItem(l10n.distanceLabel, _coreLogic.distance.toStringAsFixed(2),
                  l10n.unitKm, sScale, isTablet, fontScale),
              SizedBox(height: verticalGap),
              _buildDivider(),
              SizedBox(height: verticalGap),
              _buildSummaryStatItem(l10n.durationLabel, _coreLogic.formatDuration(_coreLogic.seconds),
                  null, sScale, isTablet, fontScale),
              SizedBox(height: verticalGap),
              _buildDivider(),
              SizedBox(height: verticalGap),
              _buildSummaryStatItem(l10n.caloriesLabel, _coreLogic.calories.toStringAsFixed(0),
                  null, sScale, isTablet, fontScale),
              SizedBox(height: sectionGap),
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
                    _buildSummaryPaceHeartItem(_coreLogic.formatPace(_coreLogic.avgPace),
                        l10n.unitMinKm, l10n.avgPaceLabel, sScale, isTablet, fontScale),
                    Container(
                        width: 1,
                        height: (isTablet ? 60.0 : 40.0) * sScale,
                        color: Colors.grey.withValues(alpha: 0.2)),
                    _buildSummaryPaceHeartItem(
                        _coreLogic.avgBpm > 0 ? _coreLogic.avgBpm.toStringAsFixed(0) : '--',
                        l10n.unitBpm, l10n.heartRateLabel, sScale, isTablet, fontScale),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: (isTablet ? 40.0 : 20.0) * sScale),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _coreLogic.resetToIdle,
                        child: Container(
                          height: isTablet ? 60.0 : 52.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF900EBF), width: 1.5),
                            borderRadius: BorderRadius.circular(12.0 * sScale),
                          ),
                          child: Center(
                            child: Text(
                              l10n.newRunButton,
                              style: GoogleFonts.tajawal(
                                fontSize: (isTablet ? 18.0 : 16.0) * fontScale,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF900EBF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * sScale),
                    Expanded(
                      child: GradientButton(
                        text: l10n.shareButton,
                        width: double.infinity,
                        height: isTablet ? 60.0 : 52.0,
                        showIcon: false,
                        textStyle: GoogleFonts.tajawal(
                          fontSize: (isTablet ? 18.0 : 16.0) * fontScale,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          ref.read(realTimeNotificationServiceProvider).clearAllBanners();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                final now = DateTime.now();
                                const months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
                                final user = ref.read(userProfileProvider).value;
                                return ShareScreen(
                                  totalTime: _coreLogic.formatDuration(_coreLogic.seconds),
                                  avgPace: _coreLogic.formatPace(_coreLogic.avgPace),
                                  distance: _coreLogic.distance.toStringAsFixed(2),
                                  date: dateStr,
                                  routePoints: _coreLogic.routePoints,
                                  userName: user?.name ?? '',
                                  profilePictureUrl: user?.profilePicture,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height: isTablet
                      ? 150.0
                      : screenHeight < 680
                          ? 110.0
                          : screenHeight < 850
                              ? 130.0
                              : 140.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, String? unit, double scale,
      bool isTablet, [double fontScale = 1.0]) {
    final labelSize = (isTablet ? 14.0 : 13.0 * scale) * fontScale;
    final valueSize = (isTablet ? 45.0 : 40.0 * scale) * fontScale;
    final unitSize = (isTablet ? 18.0 : 16.0 * scale) * fontScale;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
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
              style: GoogleFonts.tajawal(
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B2D51),
              ),
            ),
            if (unit != null) ...[
              SizedBox(width: 4 * scale),
              Text(
                unit,
                style: GoogleFonts.tajawal(
                  fontSize: unitSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B2D51),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryPaceHeartItem(String value, String unit, String label, double scale,
      bool isTablet, [double fontScale = 1.0]) {
    final valueSize = (isTablet ? 35.0 : 30.5 * scale) * fontScale;
    final unitSize = (isTablet ? 16.0 : 14.0 * scale) * fontScale;
    final labelSize = (isTablet ? 12.0 : 10.0 * scale) * fontScale;

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
                    style: GoogleFonts.tajawal(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.tajawal(
                  fontSize: unitSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B88B5),
                ),
              ),
            ],
          ),
          SizedBox(height: 2 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B88B5),
              textStyle: const TextStyle(letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(double scale, bool isTablet, bool isAr) {
    final size = (isTablet ? 42.0 : 42.0) * scale;
    return GestureDetector(
      onTap: () async {
        await _supportLogic.onPopInvoked(
          isRunning: _coreLogic.runningState == RunningState.running ||
              _coreLogic.runningState == RunningState.paused,
          isFinished: _coreLogic.runningState == RunningState.finished,
          finishRun: _coreLogic.finishRun,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/images/back_arrow_icon.svg',
          width: size,
          height: size,
          matchTextDirection: true,
        ),
      ),
    );
  }

  Widget _buildGPSStatusIndicator(double scale, bool isTablet) {
    if (_coreLogic.runningState == RunningState.finished) return const SizedBox.shrink();
    
    final text = _coreLogic.getGPSStatusMessage();
    final color = _coreLogic.getGPSStatusColor();
    
    // Don't show "Good" status to avoid clutter
    if (text == "🟢 GPS Good") return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 10.0 * scale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _coreLogic.isIndoorMode ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: Colors.white,
            size: 18.0 * scale,
          ),
          SizedBox(width: 10.0 * scale),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.tajawal(
                fontSize: 13.0 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
            color: const Color(0xFFD2D2D2).withValues(alpha: 0.25),
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

class _RunHoldCircle extends StatefulWidget {
  final double size;
  final Color ringColor;
  final IconData icon;
  final VoidCallback onAction;
  final VoidCallback onTap;

  const _RunHoldCircle({
    required this.size,
    required this.ringColor,
    required this.icon,
    required this.onAction,
    required this.onTap,
  });

  @override
  State<_RunHoldCircle> createState() => _RunHoldCircleState();
}

class _RunHoldCircleState extends State<_RunHoldCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.vibrate();
        widget.onAction();
        _controller.reset();
        if (mounted) setState(() => _isHolding = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_controller.isAnimating && !_controller.isCompleted) {
      widget.onTap();
      _controller.reverse();
      setState(() => _isHolding = false);
    }
  }

  void _handleTapCancel() {
    if (_controller.isAnimating) {
      _controller.reverse();
      setState(() => _isHolding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isHolding ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              if (_isHolding)
                Container(
                  width: widget.size + 10,
                  height: widget.size + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF900EBF).withValues(alpha: 0.20 * _controller.value),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, 10),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: widget.size * 0.50,
                  color: const Color(0xFF900EBF),
                ),
              ),
              SizedBox(
                width: widget.size + 4,
                height: widget.size + 4,
                child: CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF900EBF).withValues(alpha: _isHolding ? 1.0 : 0.0),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunHoldGradient extends StatefulWidget {
  final VoidCallback onAction;
  final Widget child;

  const _RunHoldGradient({required this.onAction, required this.child});

  @override
  State<_RunHoldGradient> createState() => _RunHoldGradientState();
}

class _RunHoldGradientState extends State<_RunHoldGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.vibrate();
        widget.onAction();
        _ctrl.reset();
        if (mounted) setState(() => _holding = false);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _holding = true);
    _ctrl.forward();
  }

  void _up(TapUpDetails _) {
    if (_ctrl.isAnimating) _ctrl.reverse();
    if (mounted) setState(() => _holding = false);
  }

  void _cancel() {
    if (_ctrl.isAnimating) _ctrl.reverse();
    if (mounted) setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _holding ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_holding)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF900EBF)
                              .withValues(alpha: 0.20 * _ctrl.value),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              child!,
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: _ctrl.value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF900EBF)
                        .withValues(alpha: _holding ? 1.0 : 0.0),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}


