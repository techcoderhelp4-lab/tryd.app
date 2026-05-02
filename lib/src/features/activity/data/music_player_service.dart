// Shared music player service used by RunningScreen and WorkoutScreen.
//
// One AudioPlayer instance for the whole app — playback continues when the
// user navigates between Run and Workout screens. Permission flow, song
// loading (Android MediaStore + iOS file picker), and playback controls all
// live here so both screens stay in sync.

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tryd/src/generated/l10n/app_localizations.dart';

/// Singleton holding all music player state. Both screens listen to
/// `notifyListeners()` to rebuild their media controls card.
class MusicPlayerService extends ChangeNotifier {
  MusicPlayerService() {
    _initPlayerListener();
  }

  // ─── Audio/Music State ──────────────────────────────────────────────────
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();

  List<SongModel> songs = [];
  List<String> _iosNames = [];
  int currentSongIndex = 0;
  bool hasAudioPermission = false;
  String? currentSongName;
  bool isMusicPlaying = false;
  bool isMusicMuted = false;
  bool _isIosPlaylist = false;
  StreamSubscription<int?>? _indexSubscription;

  bool _initialized = false;

  // ─── Initialization ─────────────────────────────────────────────────────

  void _initPlayerListener() {
    audioPlayer.playerStateStream.listen((state) {
      isMusicPlaying = state.playing;
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        if (!_isIosPlaylist && songs.length > 1) {
          nextSong();
        }
      }
    });
    isMusicPlaying = audioPlayer.playing;
  }

  /// Permission flow + library load. Idempotent and safe to call on every
  /// screen entry — silently no-ops once permission is granted, surfaces the
  /// modal again if still denied. Returns when modal closes (or immediately
  /// when granted).
  Future<void> initMusic(BuildContext context, {bool showModal = true}) async {
    // Already granted — load library on first call only.
    if (hasAudioPermission) {
      if (!_initialized) {
        _initialized = true;
        if (Platform.isAndroid && songs.isEmpty) {
          await _loadAndroidSongs();
        }
      }
      return;
    }

    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.status;
      if (status.isGranted) {
        hasAudioPermission = true;
        _initialized = true;
        notifyListeners();
        return;
      }
      // Not granted yet — show modal and await its closure.
      if (context.mounted && showModal) {
        await showAudioPermissionModal(context);
      }
      return;
    }

    // Android
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    if (audioStatus.isGranted || storageStatus.isGranted) {
      hasAudioPermission = true;
      _initialized = true;
      await _loadAndroidSongs();
      return;
    }
    if (context.mounted && showModal) {
      await showAudioPermissionModal(context);
    }
  }

  /// Re-check audio permission status. Returns true when permission is
  /// already granted; surfaces the modal otherwise. Used by RunningScreen's
  /// per-tab `checkAllPermissions` flow.
  Future<bool> isAudioPermissionGranted() async {
    if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.status;
      return status.isGranted;
    }
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    return audioStatus.isGranted || storageStatus.isGranted;
  }

  // ─── Library Loading ────────────────────────────────────────────────────

  Future<void> _loadAndroidSongs() async {
    try {
      final loaded = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      if (loaded.isNotEmpty) {
        songs = loaded;
        currentSongIndex = 0;
        notifyListeners();
        await _loadAndroidSong(songs[0]);
      }
    } catch (e) {
      debugPrint('Load Android Songs Error: $e');
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
      currentSongName = song.title;
      notifyListeners();
    } catch (e) {
      debugPrint('Load Android Song Error: $e');
    }
  }

  // ─── Playback Controls ──────────────────────────────────────────────────

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

        final sources =
            validFiles.map((f) => AudioSource.file(f.path!)).toList();
        _iosNames = validFiles.map((f) => f.name).toList();

        await _indexSubscription?.cancel();
        await audioPlayer.setAudioSources(sources, initialIndex: 0);

        _isIosPlaylist = true;
        songs = [];
        currentSongName = _iosNames.first;
        notifyListeners();

        _indexSubscription = audioPlayer.currentIndexStream.listen((idx) {
          if (idx != null && idx < _iosNames.length) {
            currentSongName = _iosNames[idx];
            notifyListeners();
          }
        });

        await audioPlayer.play();
      } else {
        final file = result.files.first;
        if (file.path == null) return;

        _isIosPlaylist = false;
        await audioPlayer.setAudioSource(AudioSource.file(file.path!));

        currentSongName = file.name;
        notifyListeners();
        await audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Pick Song Error: $e');
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
      debugPrint('Toggle Play Error: $e');
    }
  }

  Future<void> nextSong() async {
    try {
      if (_isIosPlaylist) {
        await audioPlayer.seekToNext();
        await audioPlayer.play();
        return;
      }
      if (songs.isEmpty) return;
      currentSongIndex = (currentSongIndex + 1) % songs.length;
      notifyListeners();
      await _loadAndroidSong(songs[currentSongIndex]);
      await audioPlayer.play();
    } catch (e) {
      debugPrint('Next Song Error: $e');
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
      notifyListeners();
      await _loadAndroidSong(songs[currentSongIndex]);
      await audioPlayer.play();
    } catch (e) {
      debugPrint('Prev Song Error: $e');
    }
  }

  void toggleMute() {
    isMusicMuted = !isMusicMuted;
    audioPlayer.setVolume(isMusicMuted ? 0 : 1);
    notifyListeners();
  }

  // ─── Permission Modal ───────────────────────────────────────────────────

  /// Public so screens can call it from their per-screen permission flow.
  /// Returns a Future that resolves when the modal closes — letting callers
  /// chain modals sequentially.
  Future<void> showAudioPermissionModal(BuildContext context) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    await showDialog<void>(
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
              padding: const EdgeInsets.only(
                  top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    l10n.audioPermissionTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF24252C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.audioPermissionMessage,
                    style: GoogleFonts.tajawal(
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
                if (granted) {
                  hasAudioPermission = true;
                  await _loadAndroidSongs();
                } else {
                  openAppSettings();
                }
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.allowAudio,
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
    );
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}

/// App-wide singleton. Lives for the lifetime of the ProviderScope, so
/// playback persists across screen navigation.
final musicPlayerServiceProvider = ChangeNotifierProvider<MusicPlayerService>(
  (ref) => MusicPlayerService(),
);

