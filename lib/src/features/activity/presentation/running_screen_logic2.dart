// running_screen_logic2.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shell/main_shell.dart' show mainNavTapProvider, mainTabProvider;
import '../data/health_repository.dart';
import '../data/music_player_service.dart';
import 'running_screen_logic1.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import 'package:tryd/main.dart' show localeProvider;

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Services Logic - Music, TTS, Health, Permissions, Dialogs
// ─────────────────────────────────────────────────────────────────────────────

class RunningSupportLogic {
  final WidgetRef ref;
  final BuildContext context;
  final VoidCallback onStateChanged;
  final bool Function() isMounted;

  RunningSupportLogic({
    required this.ref,
    required this.context,
    required this.onStateChanged,
    required this.isMounted,
  });

  // ─── Audio/Music — delegates to shared MusicPlayerService ───────────────
  MusicPlayerService get _music => ref.read(musicPlayerServiceProvider);

  // Pass-through getters keep the old call sites in running_screen.dart
  // working without changes.
  List<SongModel> get songs => _music.songs;
  int get currentSongIndex => _music.currentSongIndex;
  bool get hasAudioPermission => _music.hasAudioPermission;
  String? get currentSongName => _music.currentSongName;
  bool get isMusicPlaying => _music.isMusicPlaying;
  bool get isMusicMuted => _music.isMusicMuted;

  // ─── TTS ────────────────────────────────────────────────────────────────
  final FlutterTts flutterTts = FlutterTts();

  // ─── Health ─────────────────────────────────────────────────────────────
  bool isHealthConnected = false;
  bool healthDialogShown = false; // True only while dialog is on screen

  // ─── Location ───────────────────────────────────────────────────────────
  bool _locationDialogShown = false; // True only while dialog is on screen

  // ─── Sequencer ──────────────────────────────────────────────────────────
  // Set to true while the Location → Health → Audio cycle is mid-flight on
  // this screen entry. Prevents re-entry from concurrent triggers
  // (initState + tab listener + app resume firing at once).
  bool _promptCycleRunning = false;


  // ─── App Lifecycle ──────────────────────────────────────────────────────
  late final WidgetsBindingObserver _observer;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  void init({
    required VoidCallback onResumed,
    required VoidCallback onPaused,
  }) {
    _observer = _RunningSupportObserver(
      onResumed: onResumed,
      onPaused: onPaused,
    );
    WidgetsBinding.instance.addObserver(_observer);
    _initTts();
    _music.addListener(onStateChanged);
    if (context.mounted) {
      _music.initMusic(context, showModal: false);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _music.removeListener(onStateChanged);
    flutterTts.stop();
  }

  // Returns true only when the RunningScreen widget is still in the tree,
  // the BuildContext is valid, AND this tab is currently visible — 
  // prevents dialogs leaking onto other screens (like Home or Settings).
  bool get _canShowDialog => 
      isMounted() && 
      context.mounted && 
      ref.read(mainTabProvider) == 1;

  // True while a run is in progress — health/audio modals must not interrupt.
  bool get _isRunActive =>
      _coreLogic != null &&
      (_coreLogic!.runningState == RunningState.running ||
          _coreLogic!.runningState == RunningState.paused ||
          _coreLogic!.runningState == RunningState.countdown);

  // ─────────────────────────────────────────────────────────────────────────
  // TTS Methods
  // ─────────────────────────────────────────────────────────────────────────

  String _lastTtsLang = '';

  Future<void> _initTts() async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    if (Platform.isAndroid) {
      await _pickArabicEngine();
    } else if (Platform.isIOS) {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
    await flutterTts.setLanguage('en-US');
    _lastTtsLang = 'en-US';
  }

  Future<void> _pickArabicEngine() async {
    try {
      final engines = await flutterTts.getEngines as List?;
      debugPrint('TTS engines: $engines');
      if (engines == null || engines.isEmpty) return;
      // com.svox.pico does not support Arabic — excluded intentionally
      const preferred = [
        'com.google.android.tts',
        'com.samsung.SMT',
        'com.samsung.android.app.tts',
      ];
      for (final pref in preferred) {
        final match = engines.cast<String?>().firstWhere(
          (e) => e != null && (e == pref || e.contains(pref.split('.').last)),
          orElse: () => null,
        );
        if (match != null) {
          await flutterTts.setEngine(match);
          debugPrint('TTS engine set to: $match');
          return;
        }
      }
      // Fall back to first non-pico engine
      final fallback = engines.cast<String?>().firstWhere(
        (e) => e != null && !e.toString().contains('pico'),
        orElse: () => engines.first as String?,
      );
      if (fallback != null) {
        await flutterTts.setEngine(fallback);
        debugPrint('TTS engine set to fallback: $fallback');
      }
    } catch (e) {
      debugPrint('TTS engine pick error: $e');
    }
  }

  Future<void> speak(String text, {bool force = false, bool isCountdown = false}) async {
    try {
      // Only skip non-forced countdown speech; all other calls pass through
      if (isCountdown && !force) return;
      final lang = ref.read(localeProvider).languageCode == 'ar' ? 'ar-EG' : 'en-US';
      await flutterTts.stop();
      if (_lastTtsLang != lang) {
        await flutterTts.setLanguage(lang);
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.setVolume(1.0);
        await flutterTts.setPitch(1.0);
        _lastTtsLang = lang;
      }
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Music Methods — thin delegations to MusicPlayerService
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> pickSong() => _music.pickSong();
  Future<void> togglePlay() => _music.togglePlay();
  Future<void> nextSong() => _music.nextSong();
  Future<void> prevSong() => _music.prevSong();
  void toggleMute() => _music.toggleMute();

  // ─────────────────────────────────────────────────────────────────────────
  // Health Connect Methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _areHealthPermissionsActuallyGranted() async {
    try {
      final health = Health();
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      final granted = await health.hasPermissions(types);
      debugPrint("Health: hasPermissions = $granted");
      return granted == true;
    } catch (e) {
      debugPrint("Health: hasPermissions error = $e");
      return false;
    }
  }

  /// Returns a Future that resolves only after the health flow finishes —
  /// either silently (already granted) or when the user closes the modal.
  /// Used by the sequencer in checkAllPermissions().
  Future<void> initHealth({bool force = false}) async {
    if (isHealthConnected && !force) return;
    if (healthDialogShown) return;

    try {
      // Check actual granted permissions first — most reliable source
      final alreadyGranted = await _areHealthPermissionsActuallyGranted();

      if (alreadyGranted) {
        await _coreLogic?.initializeHealthConnect();
        isHealthConnected = true;
        onStateChanged();
        debugPrint("Health: ✅ Permissions confirmed — connected silently");
        return;
      }

      // Permissions not granted — check if app is even installed
      final healthRepo = ref.read(healthRepositoryProvider);
      final status = await healthRepo.getSetupStatus();
      debugPrint("Health: status = $status");

      if (status == HealthSetupStatus.notInstalled && Platform.isAndroid) {
        isHealthConnected = false;
        onStateChanged();
        if (_canShowDialog) {
          await _showHealthConnectDialog(HealthConnectSdkStatus.sdkUnavailable);
        }
        return;
      }

      if (status == HealthSetupStatus.needsPermissions) {
        isHealthConnected = false;
        onStateChanged();
        if (_canShowDialog) {
          await _showHealthPermissionsDialog();
        }
        return;
      }
    } catch (e) {
      debugPrint("Health init error: $e");
    }
  }

  // Helper to get local logic (since it's created in RunningScreen)
  RunningCoreLogic? _coreLogic;
  void setCoreLogic(RunningCoreLogic logic) => _coreLogic = logic;

  Future<void> _showHealthConnectDialog(HealthConnectSdkStatus status) async {
    if (healthDialogShown || isHealthConnected) {
      debugPrint("Health: Dialog already shown or already connected, skipping");
      return;
    }
    if (!_canShowDialog) return;

    healthDialogShown = true;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    await showDialog<void>(
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
                        ? l10n.healthUpdateTitle
                        : l10n.healthConnectTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired
                        ? l10n.healthUpdateMessage
                        : l10n.healthConnectMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
                    onTap: () {
                      Navigator.pop(context);
                      healthDialogShown = false;
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.later,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w700,
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
                      healthDialogShown = false;
                      ref.read(healthRepositoryProvider).installHealthConnect();
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.installUpdate,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 13.0 * fontScale,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w800,
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
    ).then((_) {
      healthDialogShown = false;
    });
  }

  Future<void> _showHealthPermissionsDialog() async {
    if (healthDialogShown || isHealthConnected) return;
    if (!_canShowDialog) return;
    healthDialogShown = true;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    await showDialog<void>(
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
                    l10n.healthPermissionTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.healthPermissionMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
                    onTap: () {
                      Navigator.pop(context);
                      healthDialogShown = false;
                    },
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20.0)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.later,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 56, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      healthDialogShown = false;

                      final healthRepo = ref.read(healthRepositoryProvider);
                      await healthRepo.openHealthConnectPermissions();

                      await Future.delayed(const Duration(milliseconds: 1000));
                      if (!context.mounted) return;

                      // Check actual permissions — not cached status
                      final granted = await _areHealthPermissionsActuallyGranted();
                      if (granted) {
                        await _coreLogic?.initializeHealthConnect();
                        isHealthConnected = true;
                        onStateChanged();
                        debugPrint("Health: ✅ Connected after user granted");
                      } else {
                        debugPrint("Health: Permissions not granted by user");
                      }
                    },
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20.0)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.enablePermissions,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 13.0 * fontScale,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w800,
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
    ).then((_) {
      healthDialogShown = false;
    });
  }

  void _showAppleHealthDialog() {
    if (healthDialogShown || isHealthConnected) {
      debugPrint("Health: Apple dialog already shown or already connected, skipping");
      return;
    }
    if (!_canShowDialog) return;

    healthDialogShown = true;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

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
                    l10n.appleHealthTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.appleHealthMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
                    onTap: () {
                      Navigator.pop(context);
                      healthDialogShown = false;
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.later,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w700,
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
                      healthDialogShown = false;
                      openAppSettings();
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.openSettings,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 13.0 * fontScale,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w800,
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
    ).then((_) {
      healthDialogShown = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // All-permissions check — called every time the Running screen becomes visible
  // ─────────────────────────────────────────────────────────────────────────

  /// Sequential prompt cycle: Location → Health → Audio. Each step awaits
  /// modal closure before the next opens, so only one modal is ever on
  /// screen at once. Re-entering the screen runs a fresh cycle if any
  /// permission is still missing.
  Future<void> checkAllPermissions() async {
    if (!context.mounted) return;
    if (_isRunActive) return;
    if (_promptCycleRunning) return; // already prompting on this entry
    _promptCycleRunning = true;
    try {
      // 1. Location — awaits modal close (or returns immediately if granted)
      await initLocationWithPermission();
      if (!_canShowDialog || _isRunActive) return;

      // 2. Health
      if (!isHealthConnected) {
        await initHealth();
      }
      if (!_canShowDialog || _isRunActive) return;

      // 3. Audio
      if (!hasAudioPermission) {
        final granted = await _music.isAudioPermissionGranted();
        if (granted) {
          onStateChanged();
        } else if (_canShowDialog && !_isRunActive) {
          await _music.showAudioPermissionModal(context);
        }
      }
    } finally {
      _promptCycleRunning = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location Permission Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Awaits modal closure when permission is missing. Always calls
  /// fetchInitialLocation() so the map UI renders (with fallback coords if
  /// permission is denied) — preventing the "blank page" bug.
  Future<void> initLocationWithPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!context.mounted) return;

      if (!serviceEnabled) {
        // Surface the modal but still render the map with fallback coords
        // so the screen isn't blank.
        unawaited(_coreLogic?.fetchInitialLocation() ?? Future.value());
        if (_canShowDialog) await _showLocationServiceDisabledModal();
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (!_canShowDialog) return;

      // Permission already granted — silent success path.
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        await _coreLogic?.fetchInitialLocation();
        return;
      }

      // Render fallback map immediately so the page is never blank,
      // then surface the appropriate modal and await its closure.
      unawaited(_coreLogic?.fetchInitialLocation() ?? Future.value());

      if (permission == LocationPermission.deniedForever) {
        if (_canShowDialog) await _showLocationDeniedModal();
        return;
      }
      if (permission == LocationPermission.denied) {
        if (_canShowDialog) await _showLocationPermissionModal();
        return;
      }
    } catch (e) {
      debugPrint("Location init error: $e");
      await _coreLogic?.fetchInitialLocation();
    }
  }

  Future<bool> checkLocationForStart() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) await _showLocationServiceDisabledModal();
        return false;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) await _showLocationDeniedModal();
        return false;
      }
      if (permission == LocationPermission.denied) {
        if (context.mounted) await _showLocationPermissionModal();
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showLocationServiceDisabledModal() async {
    if (_locationDialogShown) return;
    if (!_canShowDialog) return;
    _locationDialogShown = true;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    await showDialog<void>(
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
                    l10n.locationServiceDisabledTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.locationServiceDisabledMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
              onTap: () {
                Navigator.pop(context);
                _locationDialogShown = false;
                Geolocator.openLocationSettings();
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.enableLocation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _locationDialogShown = false;
    });
  }

  Future<void> _showLocationPermissionModal() async {
    if (_locationDialogShown) return;
    if (!_canShowDialog) return;
    _locationDialogShown = true;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    await showDialog<void>(
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
                    l10n.locationPermissionTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.locationPermissionMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
              onTap: () async {
                Navigator.pop(context);
                _locationDialogShown = false;
                final granted = await Geolocator.requestPermission();
                if (granted == LocationPermission.denied ||
                    granted == LocationPermission.deniedForever) { return; }
                // Permission granted — re-init location so the map switches
                // from fallback coords to the user's real location.
                await _coreLogic?.fetchInitialLocation();
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.allowLocation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _locationDialogShown = false;
    });
  }

  Future<void> _showLocationDeniedModal() async {
    if (_locationDialogShown) return;
    if (!_canShowDialog) return;
    _locationDialogShown = true;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    await showDialog<void>(
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
                    l10n.locationDeniedTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.locationDeniedMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
              onTap: () {
                Navigator.pop(context);
                _locationDialogShown = false;
                Geolocator.openAppSettings();
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.openSettings,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _locationDialogShown = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exit Confirmation Dialog
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> showExitConfirmation() async {
    if (!_canShowDialog) return null;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

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
                    l10n.endRunTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.endRunMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
                  l10n.saveAndExit,
                  style: GoogleFonts.tajawal(
                    fontSize: 16.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w800,
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
                  l10n.keepRunning,
                  style: GoogleFonts.tajawal(
                    fontSize: 16.0 * fontScale,
                    color: const Color(0xFF8B88B5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> showResumeDialog() {
    if (!_canShowDialog) return Future.value(null);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    return showDialog<bool>(
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
                    l10n.resumeActivityTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.resumeActivityMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.0 * fontScale,
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
                    onTap: () => Navigator.pop(context, false),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20.0)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.discardButton,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 56, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, true),
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20.0)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.resumeButton,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w800,
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

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> handleNavigation(int index, {bool isRunning = false}) async {
    if (index == 1) return;

    if (isRunning) {
      final result = await showExitConfirmation();
      if (result == null) return;
    }

    if (!context.mounted) return;
    ref.read(mainNavTapProvider)?.call(index);
  }

  Future<bool> onPopInvoked({bool isRunning = false, bool isFinished = false, Future<void> Function()? finishRun}) async {
    if (isRunning) {
      final result = await showExitConfirmation();
      if (result == null) return false;

      await finishRun?.call();
      return true;
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return false; // Handled
      } else {
        ref.read(mainNavTapProvider)?.call(0);
        return true;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom WidgetsBindingObserver
// ─────────────────────────────────────────────────────────────────────────────

class _RunningSupportObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;
  final VoidCallback onPaused;

  _RunningSupportObserver({required this.onResumed, required this.onPaused});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      onPaused();
    }
  }
}
