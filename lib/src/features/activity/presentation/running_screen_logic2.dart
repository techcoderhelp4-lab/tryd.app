// running_screen_logic2.dart
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shell/main_shell.dart' show mainNavTapProvider;
import '../data/health_repository.dart';
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

  // ─── Audio/Music ────────────────────────────────────────────────────────
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();
  List<SongModel> songs = [];      // Android MediaStore songs
  List<String> _iosNames = [];     // iOS picked file display names
  int currentSongIndex = 0;
  bool hasAudioPermission = false;
  String? currentSongName;
  bool isMusicPlaying = false;
  bool isMusicMuted = false;
  bool _isIosPlaylist = false;     // true when iOS multi-file playlist is loaded
  StreamSubscription<int?>? _indexSubscription;  // iOS current-index listener

  // ─── TTS ────────────────────────────────────────────────────────────────
  final FlutterTts flutterTts = FlutterTts();

  // ─── Health ─────────────────────────────────────────────────────────────
  bool isHealthConnected = false;
  bool healthDialogShown = false;
  bool _permissionsDialogShownOnce = false;
  DateTime? _lastHealthCheckTime;

  // ─── Location ───────────────────────────────────────────────────────────
  bool _locationDialogShown = false;


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
    _initMusic();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _indexSubscription?.cancel();
    audioPlayer.dispose();
    flutterTts.stop();
  }

  // Returns true only when the RunningScreen widget is still in the tree and
  // the BuildContext is still valid — prevents dialogs leaking onto other screens.
  bool get _canShowDialog => isMounted() && context.mounted;

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
  // Music Methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initMusic() async {
    // Single player-state listener — tracks play/pause and auto-advances
    // Android-only single-song mode advances via currentSongIndex.
    audioPlayer.playerStateStream.listen((state) {
      if (!context.mounted) return;
      isMusicPlaying = state.playing;
      onStateChanged();
      if (state.processingState == ProcessingState.completed) {
        // iOS playlist: just_audio auto-advances; only do manual advance for
        // Android single-song mode (no queue loaded).
        if (!_isIosPlaylist && songs.length > 1) {
          nextSong();
        }
      }
    });

    // Sync initial playing state in case player was already active.
    isMusicPlaying = audioPlayer.playing;

    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();
      if (status.isGranted) {
        hasAudioPermission = true;
        if (context.mounted) onStateChanged();
      } else if (context.mounted) {
        _showAudioPermissionModal();
      }
      return;
    }

    // Android: check existing permission before requesting.
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    if (audioStatus.isGranted || storageStatus.isGranted) {
      hasAudioPermission = true;
      await _loadAndroidSongs();
    } else {
      final result = await Permission.audio.request();
      if (result.isGranted) {
        hasAudioPermission = true;
        await _loadAndroidSongs();
      } else if (context.mounted) {
        _showAudioPermissionModal();
      }
    }
  }

  Future<void> _loadAndroidSongs() async {
    try {
      final loaded = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      if (loaded.isNotEmpty && context.mounted) {
        songs = loaded;
        currentSongIndex = 0;
        onStateChanged();
        // Pre-load first song so controls are ready, but don't auto-play.
        await _loadAndroidSong(songs[0]);
      }
    } catch (e) {
      debugPrint("Load Android Songs Error: $e");
    }
  }

  Future<void> _loadAndroidSong(SongModel song) async {
    try {
      final uri = song.uri;
      final path = song.data;
      if (uri != null && uri.isNotEmpty) {
        await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      } else if (path.isNotEmpty) {
        await audioPlayer.setAudioSource(AudioSource.file(path));
      }
      if (context.mounted) {
        currentSongName = song.title;
        onStateChanged();
      }
    } catch (e) {
      debugPrint("Load Android Song Error: $e");
    }
  }

  Future<void> pickSong() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: Platform.isIOS,
      );
      if (result == null || result.files.isEmpty) return;

      if (Platform.isIOS) {
        final validFiles = result.files.where((f) => f.path != null).toList();
        if (validFiles.isEmpty) return;

        final sources = validFiles.map((f) => AudioSource.file(f.path!)).toList();
        _iosNames = validFiles.map((f) => f.name).toList();

        // Cancel previous index-tracking subscription to avoid leaks.
        await _indexSubscription?.cancel();

        // Load playlist — setAudioSources replaces whatever was loaded before.
        await audioPlayer.setAudioSources(sources, initialIndex: 0);

        _isIosPlaylist = true;
        songs = []; // iOS playlist supersedes Android song list

        if (context.mounted) {
          currentSongName = _iosNames.first;
          onStateChanged();

          // Track current track name as user skips through the playlist.
          _indexSubscription = audioPlayer.currentIndexStream.listen((idx) {
            if (idx != null && idx < _iosNames.length && context.mounted) {
              currentSongName = _iosNames[idx];
              onStateChanged();
            }
          });

          await audioPlayer.play();
        }
      } else {
        // Android: single-file pick — replace current source and play immediately.
        final file = result.files.first;
        if (file.path == null) return;

        _isIosPlaylist = false;
        await audioPlayer.setAudioSource(AudioSource.file(file.path!));

        if (context.mounted) {
          currentSongName = file.name;
          onStateChanged();
          await audioPlayer.play();
        }
      }
    } catch (e) {
      debugPrint("Pick Song Error: $e");
    }
  }

  Future<void> togglePlay() async {
    try {
      if (audioPlayer.playing) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Toggle Play Error: $e");
    }
  }

  Future<void> nextSong() async {
    try {
      if (_isIosPlaylist) {
        // Playlist mode: let just_audio handle advancement.
        await audioPlayer.seekToNext();
        await audioPlayer.play();
        return;
      }
      // Android single-song list mode.
      if (songs.isEmpty) return;
      currentSongIndex = (currentSongIndex + 1) % songs.length;
      onStateChanged();
      await _loadAndroidSong(songs[currentSongIndex]);
      await audioPlayer.play();
    } catch (e) {
      debugPrint("Next Song Error: $e");
    }
  }

  Future<void> prevSong() async {
    try {
      if (_isIosPlaylist) {
        await audioPlayer.seekToPrevious();
        await audioPlayer.play();
        return;
      }
      if (songs.isEmpty) return;
      currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
      onStateChanged();
      await _loadAndroidSong(songs[currentSongIndex]);
      await audioPlayer.play();
    } catch (e) {
      debugPrint("Prev Song Error: $e");
    }
  }

  void toggleMute() {
    isMusicMuted = !isMusicMuted;
    audioPlayer.setVolume(isMusicMuted ? 0 : 1);
    onStateChanged();
  }

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

  Future<void> initHealth({bool force = false}) async {
    if (isHealthConnected && !force) return;
    if (healthDialogShown) return;

    // Throttle checks to once per 60 seconds unless forced
    final now = DateTime.now();
    if (!force &&
        _lastHealthCheckTime != null &&
        now.difference(_lastHealthCheckTime!) < const Duration(seconds: 60)) {
      return;
    }
    _lastHealthCheckTime = now;

    try {
      // Check actual granted permissions first — most reliable source
      final alreadyGranted = await _areHealthPermissionsActuallyGranted();

      if (alreadyGranted) {
        await _coreLogic?.initializeHealthConnect();
        isHealthConnected = true;
        _permissionsDialogShownOnce = false;
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
        if (context.mounted) {
          _showHealthConnectDialog(HealthConnectSdkStatus.sdkUnavailable);
        }
        return;
      }

      if (status == HealthSetupStatus.needsPermissions) {
        isHealthConnected = false;
        onStateChanged();
        // Show permissions dialog only once per session unless forced
        if (_permissionsDialogShownOnce && !force) return;
        if (context.mounted) {
          _permissionsDialogShownOnce = true;
          _showHealthPermissionsDialog();
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

  void _showHealthConnectDialog(HealthConnectSdkStatus status) {
    if (healthDialogShown || isHealthConnected) {
      debugPrint("Health: Dialog already shown or already connected, skipping");
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
                    status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired
                        ? l10n.healthUpdateTitle
                        : l10n.healthConnectTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired
                        ? l10n.healthUpdateMessage
                        : l10n.healthConnectMessage,
                    style: GoogleFonts.lexend(
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
                        style: GoogleFonts.lexend(
                          fontSize: 14.0 * fontScale,
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
                        style: GoogleFonts.lexend(
                          fontSize: 13.0 * fontScale,
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
    ).then((_) {
      healthDialogShown = false;
    });
  }

  void _showHealthPermissionsDialog() {
    if (healthDialogShown || isHealthConnected) return;
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
                    l10n.healthPermissionTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.healthPermissionMessage,
                    style: GoogleFonts.lexend(
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
                        style: GoogleFonts.lexend(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w500,
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
                        _permissionsDialogShownOnce = false;
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
                        style: GoogleFonts.lexend(
                          fontSize: 13.0 * fontScale,
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
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.appleHealthMessage,
                    style: GoogleFonts.lexend(
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
                        style: GoogleFonts.lexend(
                          fontSize: 14.0 * fontScale,
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
                        style: GoogleFonts.lexend(
                          fontSize: 13.0 * fontScale,
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
    ).then((_) {
      healthDialogShown = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // All-permissions check — called every time the Running screen becomes visible
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> checkAllPermissions() async {
    if (!context.mounted) return;

    // Suppress all setup modals while a run is active — only running modals allowed.
    if (_isRunActive) return;

    // 1. Location — always re-check, modal only shows when denied
    await initLocationWithPermission();

    if (!context.mounted || _isRunActive) return;
    // Small gap so modals don't stack on top of each other
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. Health — reset one-time guards so modal can appear again on re-visit
    if (!isHealthConnected) {
      if (_isRunActive) return;
      healthDialogShown = false;
      _permissionsDialogShownOnce = false;
      await initHealth();
    }

    if (!context.mounted || _isRunActive) return;
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Audio — show modal only if permission was never granted
    if (!hasAudioPermission && !_isRunActive) {
      if (Platform.isIOS) {
        final status = await Permission.mediaLibrary.status;
        if (!status.isGranted) _showAudioPermissionModal();
      } else {
        final audioStatus = await Permission.audio.status;
        final storageStatus = await Permission.storage.status;
        if (!audioStatus.isGranted && !storageStatus.isGranted) {
          _showAudioPermissionModal();
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location Permission Methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initLocationWithPermission() async {
    // Reset so the modal shows every time the screen is visited
    _locationDialogShown = false;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _coreLogic?.fetchInitialLocation();
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (!context.mounted) return;

      if (permission == LocationPermission.deniedForever) {
        _showLocationDeniedModal();
        return;
      }
      if (permission == LocationPermission.denied) {
        _showLocationPermissionModal();
        return;
      }
      await _coreLogic?.fetchInitialLocation();
    } catch (e) {
      debugPrint("Location init error: $e");
      await _coreLogic?.fetchInitialLocation();
    }
  }

  Future<bool> checkLocationForStart() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) _showLocationServiceDisabledModal();
        return false;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) _showLocationDeniedModal();
        return false;
      }
      if (permission == LocationPermission.denied) {
        if (context.mounted) _showLocationPermissionModal();
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showAudioPermissionModal() {
    if (!_canShowDialog) return;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
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
                    l10n.audioPermissionTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.audioPermissionMessage,
                    style: GoogleFonts.lexend(
                      fontSize: 14.0 * fontScale,
                      color: const Color(0xFF24252C).withValues(alpha: 0.8),
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
                Navigator.pop(ctx);
                bool granted = false;
                if (Platform.isAndroid) {
                  granted = (await Permission.audio.request()).isGranted ||
                      (await Permission.storage.request()).isGranted;
                } else {
                  granted = (await Permission.mediaLibrary.request()).isGranted;
                }
                if (granted && context.mounted) {
                  hasAudioPermission = true;
                  await _loadAndroidSongs();
                } else if (!granted && context.mounted) {
                  openAppSettings();
                }
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
                  l10n.allowAudio,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationServiceDisabledModal() {
    if (_locationDialogShown) return;
    if (!_canShowDialog) return;
    _locationDialogShown = true;

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
                    l10n.locationServiceDisabledTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.locationServiceDisabledMessage,
                    style: GoogleFonts.lexend(
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
                  style: GoogleFonts.lexend(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w600,
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

  void _showLocationPermissionModal() {
    if (_locationDialogShown) return;
    if (!_canShowDialog) return;
    _locationDialogShown = true;

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
                    l10n.locationPermissionTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.locationPermissionMessage,
                    style: GoogleFonts.lexend(
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
                  style: GoogleFonts.lexend(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w600,
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

  void _showLocationDeniedModal() {
    if (_locationDialogShown) return;
    if (!_canShowDialog) return;
    _locationDialogShown = true;

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
                    l10n.locationDeniedTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.locationDeniedMessage,
                    style: GoogleFonts.lexend(
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
                  style: GoogleFonts.lexend(
                    fontSize: 13.0 * fontScale,
                    color: const Color(0xFF900EBF),
                    fontWeight: FontWeight.w600,
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
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.endRunMessage,
                    style: GoogleFonts.lexend(
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
                  style: GoogleFonts.lexend(
                    fontSize: 16.0 * fontScale,
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
                  l10n.keepRunning,
                  style: GoogleFonts.lexend(
                    fontSize: 16.0 * fontScale,
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
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.resumeActivityMessage,
                    style: GoogleFonts.lexend(
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
                        style: GoogleFonts.lexend(
                          fontSize: 14.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w500,
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
                        style: GoogleFonts.lexend(
                          fontSize: 14.0 * fontScale,
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