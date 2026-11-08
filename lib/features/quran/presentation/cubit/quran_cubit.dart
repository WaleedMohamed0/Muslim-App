import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/storage/cache_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/data_sources/quran_audio_player.dart';
import '../../data/data_sources/quran_audio_handler.dart';
import '../../data/data_sources/quran_reciter_artwork_cache.dart';
import '../../data/repositories/quran_audio_repository.dart';
import '../../domain/repositories/quran_audio_repository.dart' as contract;
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/entities/quran_reciter.dart';
import '../../domain/entities/quran_ayah_timing.dart';
import '../../domain/entities/quran_downloaded_audio.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';
import '../../data/repositories/quran_bookmark_repository_impl.dart';
import '../../data/repositories/quran_tafsir_repository_impl.dart';
import '../../domain/repositories/quran_tafsir_repository.dart';
import '../../data/repositories/platform_quran_share_repository.dart';
import '../../domain/repositories/quran_share_repository.dart';

import 'quran_state.dart';
import '../../../../core/assets/app_assets.dart';

enum QuranPlaybackMode { fullSurah, fromAyah, ayahOnly }

class QuranCubit extends Cubit<QuranState> {
  QuranCubit({
    contract.QuranAudioRepository? audioRepository,
    QuranAudioPlayer? audioPlayer,
    QuranAudioHandler? audioHandler,
    QuranBookmarkRepository? bookmarkRepository,
    QuranTafsirRepository? tafsirRepository,
    QuranShareRepository? shareRepository,
  }) : _audioRepository = audioRepository ?? QuranAudioRepository(),
       _audioPlayer =
           audioPlayer ?? QuranAudioPlayer(audioHandler ?? QuranAudioHandler()),
       _bookmarkRepository =
           bookmarkRepository ?? QuranBookmarkRepositoryImpl(),
       _tafsirRepository = tafsirRepository ?? QuranTafsirRepositoryImpl(),
       _shareRepository =
           shareRepository ?? const PlatformQuranShareRepository(),
       super(const QuranState()) {
    _playerStateSubscription = _audioPlayer.player.playerStateStream.listen(
      _handlePlayerState,
    );
    _playerErrorSubscription = _audioPlayer.player.errorStream.listen(
      _handlePlayerError,
    );
    _positionSubscription = _audioPlayer.player.positionStream.listen(
      _handleAudioPosition,
    );
    _audioPlayer.handler
      ..onPrevious = previousSurah
      ..onNext = nextSurah
      ..onPlayAction = resumePlaybackFromMediaSession
      ..onPauseAction = pausePlaybackFromMediaSession
      ..onStopAction = changeQuranSoundActive;
    _reciterReady = _loadReciterPreference();
  }

  final contract.QuranAudioRepository _audioRepository;
  final QuranAudioPlayer _audioPlayer;
  final QuranBookmarkRepository _bookmarkRepository;
  final QuranTafsirRepository _tafsirRepository;
  final QuranShareRepository _shareRepository;
  final Map<String, Uri?> _reciterArtworkUris = {};
  final Set<String> _artworkRequests = {};
  static const _reciterPreferenceKey = 'quran_audio_reciter_id';
  static String _savedAudioPositionKey(String reciterId, int number) =>
      'quran_audio_position_${reciterId}_$number';
  static String _savedAudioSourceKey(String reciterId, int number) =>
      'quran_audio_source_${reciterId}_$number';
  static const _lightReaderBackgroundKey = 'quran_reader_background_light';
  static const _darkReaderBackgroundKey = 'quran_reader_background_dark';
  late final Future<void> _reciterReady;
  QuranReciter selectedReciter = QuranReciter.all.first;
  int? lightReaderBackgroundColorValue;
  int? darkReaderBackgroundColorValue;
  QuranReciter? _sourceReciter;
  QuranReciter get displayReciter => _sourceReciter ?? selectedReciter;
  final AudioPlayer azanSound = AudioPlayer();
  String surahName = '';
  int surahNumber = 0;
  int currentPageNumber = 0;
  int surahPlaybackNavigationRevision = 0;
  int surahPlaybackNavigationTarget = 0;
  int surahPlaybackNavigationAyah = 1;
  bool get isPlaying => _audioPlayer.player.playing;
  IconData get soundIcon =>
      isPlaying ? Icons.pause : Icons.play_arrow;
  bool _playbackSessionActive = false;
  bool isAudioLoading = false;
  bool isCached = false;
  bool quranSoundActive = false;
  String quranSoundUrl = '';
  int? _pendingRestoredAudioPositionMs;
  int _lastSavedAudioPositionMs = 0;
  int _lastPositionWriteSurah = 0;
  String _lastPositionWriteReciter = '';
  final Set<String> _downloadingAudioUrls = <String>{};
  final Set<String> _failedDownloadUrls = <String>{};
  final Set<String> _knownDownloadedAudioUrls = <String>{};
  int _downloadStatusRevision = 0;
  int downloadRevision = 0;

  String get currentSurahAudioUrl =>
      surahNumber > 0 ? audioUrlFor(surahNumber) : '';
  bool get canDownloadCurrentSurah =>
      surahNumber > 0 && selectedReciter.serverUrl.isNotEmpty;
  bool get isDownloading =>
      currentSurahAudioUrl.isNotEmpty &&
      _downloadingAudioUrls.contains(currentSurahAudioUrl);
  bool get isCurrentSurahDownloaded =>
      currentSurahAudioUrl.isNotEmpty &&
      _knownDownloadedAudioUrls.contains(currentSurahAudioUrl);
  bool get hasCurrentSurahDownloadFailed =>
      currentSurahAudioUrl.isNotEmpty &&
      _failedDownloadUrls.contains(currentSurahAudioUrl);

  Stream<Duration> get audioPositionStream =>
      _audioPlayer.player.positionStream;
  Stream<Duration?> get audioDurationStream =>
      _audioPlayer.player.durationStream;
  Duration get audioPosition => _audioPlayer.player.position;
  int get lastKnownAudioPositionMs =>
      quranSoundActive && _audioSourcePrepared
          ? _audioPlayer.player.position.inMilliseconds
          : _pendingRestoredAudioPositionMs ?? _lastSavedAudioPositionMs;
  Duration? get audioDuration => _audioPlayer.player.duration;
  int get currentMushafPageNumber =>
      surahNumber >= 1 && surahNumber <= 114
      ? quran.getPageNumber(
          surahNumber,
          currentAyahNumber
              .clamp(1, quran.getVerseCount(surahNumber))
              .toInt(),
        )
      : 0;
  bool _audioSourcePrepared = false;
  bool _singleAyahPlayback = false;
  QuranPlaybackMode playbackMode = QuranPlaybackMode.fullSurah;
  bool _preparingAudioSource = false;
  bool _audioErrorReported = false;
  bool _seekingToAyah = false;
  bool _playCommandPending = false;
  bool _pauseCommandPending = false;
  bool _stopCommandPending = false;
  int _seekRevision = 0;
  Future<void> _audioCommandQueue = Future<void>.value();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<PlayerException> _playerErrorSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  Timer? _audioStartTimeout;
  List<QuranAyahTiming> _ayahTimings = const [];
  int currentAyahNumber = 1;
  bool _advancingCompletedSurah = false;
  bool get hasAyahTimings => _ayahTimings.isNotEmpty;
  bool get isSingleAyahPlayback => _singleAyahPlayback;
  bool get hasActivePlaybackSession =>
      _playbackSessionActive || _audioPlayer.player.playing;
  bool get hasReliableCurrentAyah =>
      hasAyahTimings || isSingleAyahPlayback || !hasActivePlaybackSession;
  int? lastAyahForSurah(int number) {
    if (number < 1 || number > 114) return null;
    if (surahNumber == number) {
      final currentAyah =
          hasActivePlaybackSession ? currentAyahNumber : currentPageNumber;
      if (currentAyah > 0) return currentAyah;
    }
    if (CacheHelper.sharedPreferences == null) return null;
    final saved =
        CacheHelper.getData(key: 'quran_last_played_ayah_$number') ??
        (CacheHelper.getData(key: 'quran_last_played_surah') == number
            ? CacheHelper.getData(key: 'quran_last_played_ayah')
            : null);
    return saved is int && saved > 0 && saved <= quran.getVerseCount(number)
        ? saved
        : null;
  }

  int? lastReaderAyahForSurah(int number) {
    if (number < 1 || number > 114 || CacheHelper.sharedPreferences == null) {
      return null;
    }
    final saved = CacheHelper.getData(key: 'quran_reader_ayah_$number');
    return saved is int && saved > 0 && saved <= quran.getVerseCount(number)
        ? saved
        : null;
  }

  void saveReaderPosition(int number, int ayah) {
    if (number < 1 ||
        number > 114 ||
        ayah < 1 ||
        ayah > quran.getVerseCount(number)) {
      return;
    }
    unawaited(
      CacheHelper.saveData(key: 'quran_reader_ayah_$number', value: ayah),
    );
  }

  bool _hasSavedAyahForSurah(int number) {
    if (CacheHelper.sharedPreferences == null) return false;
    final hasSurahPosition =
        CacheHelper.getData(key: 'quran_last_played_ayah_$number') is int;
    final hasMatchingLegacyPosition =
        CacheHelper.getData(key: 'quran_last_played_surah') == number &&
        CacheHelper.getData(key: 'quran_last_played_ayah') is int;
    return hasSurahPosition || hasMatchingLegacyPosition;
  }

  Future<void> _saveAyahPosition(int ayah) async {
    if (surahNumber < 1 || ayah < 1) return;
    await CacheHelper.saveData(
      key: 'quran_last_played_ayah_$surahNumber',
      value: ayah,
    );
    await CacheHelper.saveData(key: 'quran_last_played_ayah', value: ayah);
  }

  int get currentSurahVerseCount =>
      surahNumber > 0 ? quran.getVerseCount(surahNumber) : 0;
  String audioUrlFor(int number) =>
      _audioRepository.urlFor(number, reciterId: selectedReciter.id);
  Future<void> playCurrentSurahOnline(int number) =>
      _enqueueAudioCommand(() async {
        if (number < 1) return;
        if (number != surahNumber) return;
        _audioErrorReported = false;
        playbackMode = QuranPlaybackMode.fullSurah;
        _singleAyahPlayback = false;
        quranSoundActive = true;
        quranSoundUrl = audioUrlFor(number);
        _persistCurrentAudioSource();
        _publishMediaItem();
        await _prepareAudioSource(preferOffline: false);
        await _startPlayback();
        if (!_singleAyahPlayback) unawaited(_loadAyahTimings(number));
      });

  QuranBookmark? bookmark;
  List<int> pageBookmarks = <int>[];
  Set<String> ayahBookmarks = <String>{};
  int _revision = 0;
  bool isOnline = false;
  bool backgroundAudioEnabled = true;
  void setConnectivity(bool connected) {
    isOnline = connected;
    emit(_nextState);
  }

  void _publishMediaItem() {
    if (!quranSoundActive || surahNumber < 1 || surahName.isEmpty) return;
    final reciter = displayReciter;
    final artwork = _reciterArtworkUris[reciter.id];
    // Keep the current notification artwork in place while a newly selected
    // reciter's local portrait is being prepared. Publishing a null artUri
    // here clears album art from Android's MediaSession immediately.
    if (artwork != null) {
      _audioPlayer.handler.updateQuranMediaItem(
        surahName: surahName,
        surahNumber: surahNumber,
        mushafPageNumber: currentMushafPageNumber,
        reciterName: reciter.nameArabic,
        reciterId: reciter.id,
        sourceUrl: quranSoundUrl,
        artworkUri: artwork,
        ayahNumber: currentAyahNumber > 0 ? currentAyahNumber : null,
      );
    }
    if (artwork == null && _artworkRequests.add(reciter.id)) {
      unawaited(_loadReciterArtwork(reciter));
    }
  }

  Future<void> _loadReciterArtwork(QuranReciter reciter) async {
    try {
      final artwork = await QuranReciterArtworkCache.fileUriFor(reciter);
      if (isClosed || !quranSoundActive || displayReciter.id != reciter.id) {
        return;
      }
      if (artwork != null) _reciterArtworkUris[reciter.id] = artwork;
      // Publish again after the file is ready. A null URI here is only used
      // when even the bundled fallback could not be read.
      _audioPlayer.handler.updateQuranMediaItem(
        surahName: surahName,
        surahNumber: surahNumber,
        mushafPageNumber: currentMushafPageNumber,
        reciterName: reciter.nameArabic,
        reciterId: reciter.id,
        sourceUrl: quranSoundUrl,
        artworkUri: artwork,
        ayahNumber: currentAyahNumber > 0 ? currentAyahNumber : null,
      );
    } catch (_) {
      // A later metadata update may retry the local artwork lookup.
    } finally {
      // Do not permanently suppress retries after an asset/cache failure.
      _artworkRequests.remove(reciter.id);
    }
  }

  Future<void> _loadAyahTimings(int number, {int? preserveAyah}) async {
    final reciterId = selectedReciter.id;
    final readId = selectedReciter.timingReadId;
    try {
      final timings = await _audioRepository.ayahTimings(
        surahNumber: number,
        reciterId: reciterId,
        readId: readId,
      );
      if (number != surahNumber ||
          selectedReciter.id != reciterId ||
          isClosed) {
        return;
      }
      _ayahTimings = [...timings]
        ..sort((left, right) => left.start.compareTo(right.start));
      final previousAyah = currentAyahNumber;
      if (preserveAyah != null) {
        currentAyahNumber = preserveAyah;
        currentPageNumber = preserveAyah;
        final start = _startForAyah(preserveAyah);
        if (start != null && _audioSourcePrepared && !_audioPlayer.player.playing) {
          try {
            await _audioPlayer.player.seek(Duration(milliseconds: start));
          } catch (_) {
            // Keep the selected reader position if the prepared source cannot seek.
          }
        }
        _publishMediaItem();
      } else {
        _updateAyahFromPosition(_audioPlayer.player.position, force: true);
      }
      if (!isClosed && currentAyahNumber == previousAyah) emit(_nextState);
    } catch (_) {
      // Playback remains available if the optional Ayah timing service is down.
      if (number == surahNumber && selectedReciter.id == reciterId) {
        _ayahTimings = const [];
        if (!isClosed) emit(_nextState);
      }
    }
  }

  void _handleAudioPosition(Duration position) {
    if (_seekingToAyah) return;
    final actualPosition = _audioPlayer.player.position;
    if ((actualPosition - position).inMilliseconds.abs() > 1000) return;
    _persistCurrentAudioPosition(position);
    _updateAyahFromPosition(position);
  }

  void _persistCurrentAudioPosition(Duration position, {bool force = false}) {
    if (!quranSoundActive || !_audioSourcePrepared || surahNumber < 1) return;
    final reciter = displayReciter;
    final positionMs = position.inMilliseconds.clamp(0, 0x7fffffff);
    final sameTrack =
        _lastPositionWriteSurah == surahNumber &&
        _lastPositionWriteReciter == reciter.id;
    if (!force &&
        sameTrack &&
        (positionMs - _lastSavedAudioPositionMs).abs() < 900) {
      return;
    }
    _lastPositionWriteSurah = surahNumber;
    _lastPositionWriteReciter = reciter.id;
    _lastSavedAudioPositionMs = positionMs;
    unawaited(
      CacheHelper.saveData(
        key: _savedAudioPositionKey(reciter.id, surahNumber),
        value: positionMs,
      ),
    );
    _persistCurrentAudioSource();
  }

  void _persistCurrentAudioSource() {
    if (surahNumber < 1 || quranSoundUrl.isEmpty) return;
    unawaited(
      CacheHelper.saveData(
        key: _savedAudioSourceKey(selectedReciter.id, surahNumber),
        value: quranSoundUrl,
      ),
    );
  }

  void _resetSavedAudioPositionForCurrentTrack() {
    if (surahNumber < 1 || surahNumber > 114) return;
    _pendingRestoredAudioPositionMs = null;
    _lastSavedAudioPositionMs = 0;
    _lastPositionWriteSurah = surahNumber;
    _lastPositionWriteReciter = selectedReciter.id;
    unawaited(
      CacheHelper.saveData(
        key: _savedAudioPositionKey(selectedReciter.id, surahNumber),
        value: 0,
      ),
    );
  }

  void _requestReaderPlaybackNavigation(int number, int ayah) {
    if (number < 1 || number > 114) return;
    surahPlaybackNavigationTarget = number;
    surahPlaybackNavigationAyah = ayah
        .clamp(1, quran.getVerseCount(number))
        .toInt();
    surahPlaybackNavigationRevision++;
  }

  void _updateAyahFromPosition(Duration position, {bool force = false}) {
    if (_ayahTimings.isEmpty || surahNumber < 1 || isClosed) return;
    QuranAyahTiming? current;
    for (final timing in _ayahTimings) {
      if (timing.ayah < 1) continue;
      if (timing.start > position) break;
      current = timing;
    }
    // If a recording's first verse timestamp follows a lead-in, the first
    // timed verse is still what should be highlighted during that interval.
    if (current == null) {
      for (final timing in _ayahTimings) {
        if (timing.ayah > 0) {
          current = timing;
          break;
        }
      }
    }
    if (current == null || (!force && current.ayah == currentAyahNumber)) {
      return;
    }
    currentAyahNumber = current.ayah;
    currentPageNumber = current.ayah;
    unawaited(_saveAyahPosition(current.ayah));
    _requestReaderPlaybackNavigation(surahNumber, current.ayah);
    _publishMediaItem();
    emit(_nextState);
  }

  int? _startForAyah(int ayah) {
    for (final timing in _ayahTimings) {
      if (timing.ayah < 1) continue;
      if (timing.ayah == ayah) return timing.start.inMilliseconds;
    }
    return null;
  }

  Future<void> previousAyah() => _navigateAyah(previous: true);
  Future<void> nextAyah() => _navigateAyah(previous: false);

  Future<void> previousSurah() => _navigateSurah(previous: true);
  Future<void> nextSurah() => _navigateSurah(previous: false);

  Future<void> _navigateSurah({required bool previous}) =>
      _enqueueAudioCommand(() async {
        final targetSurah = surahNumber + (previous ? -1 : 1);
        if (targetSurah < 1 || targetSurah > 114) return;

        _audioErrorReported = false;
        _audioStartTimeout?.cancel();
        await _switchSurahForPlayback(
          targetSurah,
          targetAyah: 1,
          resume: true,
          mode: QuranPlaybackMode.fullSurah,
        );
      });

  Future<void> seekToAyahProgress(double progress) {
    final seekRevision = ++_seekRevision;
    return _enqueueAudioCommand(() async {
      if (seekRevision != _seekRevision) return;
      if (surahNumber < 1) return;
      final duration = _audioPlayer.player.duration;
      if (duration == null || duration.inMilliseconds <= 0) return;

      final targetPosition = Duration(
        milliseconds:
            (duration.inMilliseconds * progress.clamp(0.0, 1.0)).round(),
      );
      if (_singleAyahPlayback) {
        try {
          await _audioPlayer.player.seek(targetPosition);
        } catch (_) {
          AppSnackBar.show(message: 'تعذر الانتقال إلى موضع التلاوة');
        }
        return;
      }
      if (_ayahTimings.isEmpty) return;
      QuranAyahTiming? selectedTiming;
      for (final timing in _ayahTimings) {
        if (timing.ayah < 1) continue;
        if (timing.start > targetPosition) break;
        selectedTiming = timing;
      }
      if (selectedTiming == null) {
        for (final timing in _ayahTimings) {
          if (timing.ayah > 0) {
            selectedTiming = timing;
            break;
          }
        }
      }
      final timing = selectedTiming;
      if (timing == null || seekRevision != _seekRevision) return;

      currentAyahNumber = timing.ayah;
      currentPageNumber = timing.ayah;
      _requestReaderPlaybackNavigation(surahNumber, timing.ayah);
      _publishMediaItem();
      emit(_nextState);
      unawaited(_saveAyahPosition(timing.ayah));
      _seekingToAyah = true;
      try {
        await _audioPlayer.player.seek(timing.start);
        if (seekRevision == _seekRevision) {
          _updateAyahFromPosition(_audioPlayer.player.position, force: true);
        }
      } catch (_) {
        AppSnackBar.show(message: 'تعذر الانتقال إلى موضع التلاوة');
      } finally {
        _seekingToAyah = false;
      }
    });
  }

  Future<void> selectAyahByProgress(double progress) {
    final seekRevision = ++_seekRevision;
    return _enqueueAudioCommand(() async {
      if (seekRevision != _seekRevision || surahNumber < 1) return;
      playbackMode = QuranPlaybackMode.fromAyah;
      final verseCount = quran.getVerseCount(surahNumber);
      final targetAyah =
          (progress.clamp(0.0, 1.0) * (verseCount - 1)).round() + 1;
      QuranAyahTiming? timing;
      for (final candidate in _ayahTimings) {
        if (candidate.ayah == targetAyah) {
          timing = candidate;
          break;
        }
      }
      if (timing != null) {
        currentAyahNumber = targetAyah;
        currentPageNumber = targetAyah;
        _requestReaderPlaybackNavigation(surahNumber, targetAyah);
        _publishMediaItem();
        emit(_nextState);
        unawaited(_saveAyahPosition(targetAyah));
        _seekingToAyah = true;
        try {
          await _audioPlayer.player.seek(timing.start);
          if (seekRevision == _seekRevision) {
            _updateAyahFromPosition(_audioPlayer.player.position, force: true);
          }
        } catch (_) {
          AppSnackBar.show(message: 'تعذر الانتقال إلى الآية');
        } finally {
          _seekingToAyah = false;
        }
        return;
      }

      await _playSingleAyah(surahNumber, targetAyah, resume: true);
    });
  }

  /// Moves the active audio session to the first Ayah on a page selected in
  /// the reader. Paused playback stays paused; active playback keeps running.
  Future<void> navigatePlaybackToAyah(int number, int ayah) =>
      _enqueueAudioCommand(() async {
        if ((!hasActivePlaybackSession && !quranSoundActive) ||
            number < 1 ||
            number > 114) {
          return;
        }
        final targetAyah = ayah.clamp(1, quran.getVerseCount(number)).toInt();
        final shouldResume = _audioPlayer.player.playing;
        if (number != surahNumber) {
          await _switchSurahForPlayback(
            number,
            targetAyah: targetAyah,
            resume: shouldResume,
            mode: playbackMode,
          );
          return;
        }

        if (_singleAyahPlayback) {
          if (targetAyah != currentAyahNumber) {
            await _playSingleAyah(
              number,
              targetAyah,
              resume: shouldResume,
              mode: playbackMode,
            );
          }
          return;
        }
        final ayahWasAlreadyCurrent = targetAyah == currentAyahNumber;
        if (_ayahTimings.isEmpty) {
          currentAyahNumber = targetAyah;
          currentPageNumber = targetAyah;
          _requestReaderPlaybackNavigation(number, targetAyah);
          unawaited(_saveAyahPosition(targetAyah));
          _publishMediaItem();
          emit(_nextState);
          await _loadAyahTimings(number, preserveAyah: targetAyah);
        }
        QuranAyahTiming? timing;
        for (final candidate in _ayahTimings) {
          if (candidate.ayah == targetAyah) {
            timing = candidate;
            break;
          }
        }
        if (ayahWasAlreadyCurrent) return;
        if (timing == null) {
          await _playSingleAyah(
            number,
            targetAyah,
            resume: shouldResume,
            mode: playbackMode,
          );
          return;
        }

        currentAyahNumber = targetAyah;
        currentPageNumber = targetAyah;
        _requestReaderPlaybackNavigation(number, targetAyah);
        unawaited(_saveAyahPosition(targetAyah));
        _publishMediaItem();
        emit(_nextState);
        _seekingToAyah = true;
        try {
          await _audioPlayer.player.seek(timing.start);
          _updateAyahFromPosition(_audioPlayer.player.position, force: true);
        } catch (_) {
          // Keep the selected Quran position if seeking is unavailable.
        } finally {
          _seekingToAyah = false;
        }
      });

  Future<void> _navigateAyah({required bool previous}) =>
      _enqueueAudioCommand(() async {
        if (surahNumber < 1) return;
        // Read the source player's state at command execution time. Cubit/UI
        // snapshots can lag while MediaSession commands are being processed.
        final shouldResume = _audioPlayer.player.playing;
        playbackMode = QuranPlaybackMode.fromAyah;
        // A single-Ayah source has no Surah-wide timing positions. Navigate
        // through the reciter's Ayah tracks instead of seeking a short track
        // using timestamps from a different, full-Surah recording.
        if (_singleAyahPlayback) {
          final targetAyah = currentAyahNumber + (previous ? -1 : 1);
          final verseCount = quran.getVerseCount(surahNumber);
          if (targetAyah >= 1 && targetAyah <= verseCount) {
            await _playSingleAyah(
              surahNumber,
              targetAyah,
              resume: shouldResume,
              mode: QuranPlaybackMode.fromAyah,
            );
          } else {
            final adjacentSurah = surahNumber + (previous ? -1 : 1);
            if (adjacentSurah < 1 || adjacentSurah > 114) return;
            await _switchSurahForPlayback(
              adjacentSurah,
              targetAyah: previous ? quran.getVerseCount(adjacentSurah) : 1,
              resume: shouldResume,
            );
          }
          return;
        }
        if (_ayahTimings.isEmpty) await _loadAyahTimings(surahNumber);
        if (_ayahTimings.isEmpty) {
          final targetAyah = currentAyahNumber + (previous ? -1 : 1);
          final verseCount = quran.getVerseCount(surahNumber);
          if (targetAyah >= 1 && targetAyah <= verseCount) {
            await _playSingleAyah(
              surahNumber,
              targetAyah,
              resume: shouldResume,
            );
          } else {
            final adjacentSurah = surahNumber + (previous ? -1 : 1);
            if (adjacentSurah < 1 || adjacentSurah > 114) return;
            await _switchSurahForPlayback(
              adjacentSurah,
              targetAyah: previous ? quran.getVerseCount(adjacentSurah) : 1,
              resume: shouldResume,
            );
          }
          return;
        }
        final current = _ayahTimings.indexWhere(
          (timing) => timing.ayah == currentAyahNumber,
        );
        if (current < 0) {
          final fallbackAyah = currentAyahNumber + (previous ? -1 : 1);
          if (fallbackAyah >= 1 &&
              fallbackAyah <= quran.getVerseCount(surahNumber)) {
            await _playSingleAyah(
              surahNumber,
              fallbackAyah,
              resume: shouldResume,
            );
          } else {
            final adjacentSurah = surahNumber + (previous ? -1 : 1);
            if (adjacentSurah < 1 || adjacentSurah > 114) return;
            await _switchSurahForPlayback(
              adjacentSurah,
              targetAyah: previous ? quran.getVerseCount(adjacentSurah) : 1,
              resume: shouldResume,
            );
          }
          return;
        }
        final index = current;
        final targetIndex = previous ? index - 1 : index + 1;
        if (targetIndex >= 0 && targetIndex < _ayahTimings.length) {
          final timing = _ayahTimings[targetIndex];
          currentAyahNumber = timing.ayah;
          currentPageNumber = timing.ayah;
          _requestReaderPlaybackNavigation(surahNumber, timing.ayah);
          _publishMediaItem();
          emit(_nextState);
          unawaited(_saveAyahPosition(timing.ayah));
          _seekingToAyah = true;
          try {
            await _audioPlayer.player.seek(timing.start);
          } catch (_) {
            AppSnackBar.show(message: 'تعذر الانتقال إلى الآية');
            return;
          } finally {
            _seekingToAyah = false;
          }
          if (shouldResume) await _startPlayback();
          return;
        }
        final adjacentSurah = surahNumber + (previous ? -1 : 1);
        if (adjacentSurah < 1 || adjacentSurah > 114) return;
        final targetAyah = previous ? quran.getVerseCount(adjacentSurah) : 1;
        await _switchSurahForPlayback(
          adjacentSurah,
          targetAyah: targetAyah,
          resume: shouldResume,
        );
      });

  Future<void> _switchSurahForPlayback(
    int number, {
    required int targetAyah,
    required bool resume,
    QuranPlaybackMode mode = QuranPlaybackMode.fromAyah,
    bool allowNetworkWhenOffline = false,
    int? restorePositionMs,
  }) async {
    playbackMode = mode;
    final rawName = quran.getSurahNameArabic(number);
    final nextName = rawName == 'اللهب' ? 'المسد' : rawName;
    _audioSourcePrepared = false;
    _singleAyahPlayback = false;
    _ayahTimings = const [];
    await _audioPlayer.stop();
    isCached = false;
    quranSoundActive = true;
    setSurahInfo(number, nextName);
    currentAyahNumber = targetAyah;
    currentPageNumber = targetAyah;
    if (restorePositionMs == null) _resetSavedAudioPositionForCurrentTrack();
    _requestReaderPlaybackNavigation(number, targetAyah);
    unawaited(_saveAyahPosition(targetAyah));
    quranSoundUrl = audioUrlFor(number);
    _persistCurrentAudioSource();
    _setAudioLoading(true);
    try {
      final cachedPath = await _audioRepository.cachedPath(
        quranSoundUrl,
        legacyUrl: _legacyAlafasyUrl(number),
      );
      if (cachedPath != null) {
        await _audioPlayer.setFile(cachedPath);
        isCached = true;
      } else if (isOnline || allowNetworkWhenOffline) {
        await _audioPlayer.setUrl(quranSoundUrl);
      } else {
        throw StateError('Surah is not available offline');
      }
      _audioSourcePrepared = true;
      _sourceReciter = selectedReciter;
      await _loadAyahTimings(number, preserveAyah: targetAyah);
      // Timing initialization may inspect the player's old zero position;
      // restore the requested bookmark position before publishing/seeking.
      currentAyahNumber = targetAyah;
      currentPageNumber = targetAyah;
      _publishMediaItem();
      emit(_nextState);
      if (restorePositionMs != null) {
        final durationMs = _audioPlayer.player.duration?.inMilliseconds;
        final safePositionMs = durationMs != null && durationMs > 0
            ? restorePositionMs.clamp(0, durationMs)
            : restorePositionMs;
        final restoredPosition = Duration(milliseconds: safePositionMs);
        await _audioPlayer.player.seek(restoredPosition);
        _updateAyahFromPosition(restoredPosition, force: true);
      } else {
        final start = _startForAyah(targetAyah);
        if (start != null) {
          await _audioPlayer.player.seek(Duration(milliseconds: start));
        } else if (targetAyah > 1) {
          await _playSingleAyah(number, targetAyah, resume: resume);
          return;
        }
        _persistCurrentAudioPosition(_audioPlayer.player.position, force: true);
      }
      _publishMediaItem();
      if (resume) await _startPlayback();
    } finally {
      _setAudioLoading(false);
    }
  }

  Future<void> _playSingleAyah(
    int number,
    int ayah, {
    required bool resume,
    QuranPlaybackMode mode = QuranPlaybackMode.fromAyah,
  }) async {
    final url = selectedReciter.ayahUrl(number, ayah);
    if (url == null) {
      AppSnackBar.show(message: 'لا يتوفر صوت منفصل لهذه الآية');
      return;
    }
    final rawName = quran.getSurahNameArabic(number);
    currentAyahNumber = ayah;
    currentPageNumber = ayah;
    _requestReaderPlaybackNavigation(number, ayah);
    quranSoundActive = true;
    _playbackSessionActive = false;
    surahNumber = number;
    surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    quranSoundUrl = url;
    _persistCurrentAudioSource();
    _resetSavedAudioPositionForCurrentTrack();
    _sourceReciter = selectedReciter;
    playbackMode = mode;
    _singleAyahPlayback = true;
    _ayahTimings = const [];
    _audioSourcePrepared = false;
    isCached = false;
    _publishMediaItem();
    emit(_nextState);
    unawaited(_saveAyahPosition(ayah));
    await _audioPlayer.stop();
    _setAudioLoading(true);
    try {
      await _audioPlayer.setUrl(url);
      _audioSourcePrepared = true;
      _sourceReciter = selectedReciter;
      _publishMediaItem();
      if (resume) await _startPlayback();
    } catch (_) {
      unawaited(_handleAudioFailure(force: true));
    } finally {
      _setAudioLoading(false);
    }
  }

  Future<void> playAyahOnly(int number, int ayah) async {
    await _reciterReady;
    await _enqueueAudioCommand(() async {
      if (number < 1 || number > 114) return;
      final verseCount = quran.getVerseCount(number);
      if (ayah < 1 || ayah > verseCount) return;
      _audioErrorReported = false;
      _audioStartTimeout?.cancel();
      await _playSingleAyah(
        number,
        ayah,
        resume: true,
        mode: QuranPlaybackMode.ayahOnly,
      );
    });
  }

  QuranState get _nextState => QuranState(revision: ++_revision);

  Future<String> getTafsir(int globalAyahNumber) =>
      _tafsirRepository.getTafsir(globalAyahNumber);

  Future<void> shareAyah({required String text, required String title}) async {
    try {
      await _shareRepository.shareText(text: text, title: title);
    } catch (_) {
      AppSnackBar.show(message: 'تعذر مشاركة الآية');
    }
  }

  Future<void> loadBookmark() async {
    pageBookmarks = await _bookmarkRepository.readPageBookmarks();
    bookmark = pageBookmarks.isEmpty
        ? null
        : QuranBookmark(pageNumber: pageBookmarks.last);
    ayahBookmarks = await _bookmarkRepository.readAyahBookmarks();
    emit(_nextState);
  }

  Future<void> initialize() async {
    await _reciterReady;
    await loadBookmark();
  }

  Future<void> _loadReciterPreference() async {
    try {
      await CacheHelper.ensureInitialized();
      final savedId =
          CacheHelper.getData(key: _reciterPreferenceKey) as String?;
      selectedReciter = QuranReciter.byId(savedId);
      final savedLightBackground =
          CacheHelper.getData(key: _lightReaderBackgroundKey);
      final savedDarkBackground =
          CacheHelper.getData(key: _darkReaderBackgroundKey);
      lightReaderBackgroundColorValue =
          savedLightBackground is int ? savedLightBackground : null;
      darkReaderBackgroundColorValue =
          savedDarkBackground is int ? savedDarkBackground : null;
      backgroundAudioEnabled =
          CacheHelper.getData(key: 'quran_background_audio_enabled') as bool? ??
          true;
      if (surahNumber == 0) {
        final savedSurah = CacheHelper.getData(key: 'quran_last_played_surah');
        if (savedSurah is int && savedSurah >= 1 && savedSurah <= 114) {
          surahNumber = savedSurah;
          final rawName = quran.getSurahNameArabic(savedSurah);
          surahName = rawName == 'اللهب' ? 'المسد' : rawName;
          final savedAyah =
              CacheHelper.getData(
                key: 'quran_last_played_ayah_$savedSurah',
              ) ??
              CacheHelper.getData(key: 'quran_last_played_ayah');
          if (savedAyah is int &&
              savedAyah > 0 &&
              savedAyah <= quran.getVerseCount(savedSurah)) {
            currentAyahNumber = savedAyah;
            currentPageNumber = savedAyah;
          }
          final savedPosition = CacheHelper.getData(
            key: _savedAudioPositionKey(selectedReciter.id, savedSurah),
          );
          if (savedPosition is int && savedPosition >= 0) {
            _lastSavedAudioPositionMs = savedPosition;
            _pendingRestoredAudioPositionMs = savedPosition;
            _lastPositionWriteSurah = savedSurah;
            _lastPositionWriteReciter = selectedReciter.id;
          }
        }
      }
      emit(_nextState);
      unawaited(refreshCurrentSurahDownloadStatus());
    } catch (_) {
      // The default reciter remains available if preference storage fails.
    }
  }

  Future<void> selectReciter(QuranReciter reciter) async {
    await _reciterReady;
    if (selectedReciter.id == reciter.id) return;
    await _enqueueAudioCommand(() async {
      final wasPlaying = _audioPlayer.player.playing;
      final resumeAyah = currentAyahNumber;
      _audioStartTimeout?.cancel();
      _audioSourcePrepared = false;
      await _audioPlayer.stop();
      final previousPlaybackMode = playbackMode;
      selectedReciter = reciter;
      _pendingRestoredAudioPositionMs = null;
      _lastSavedAudioPositionMs = 0;
      _lastPositionWriteSurah = surahNumber;
      _lastPositionWriteReciter = reciter.id;
      _sourceReciter = null;
      _ayahTimings = const [];
      _singleAyahPlayback = false;
      await CacheHelper.saveData(key: _reciterPreferenceKey, value: reciter.id);
      isCached = false;
      quranSoundUrl = surahNumber > 0 ? audioUrlFor(surahNumber) : '';
      unawaited(refreshCurrentSurahDownloadStatus());
      _audioErrorReported = false;
      emit(_nextState);

      if (!quranSoundActive || surahNumber < 1) return;
      try {
        if (previousPlaybackMode == QuranPlaybackMode.ayahOnly) {
          await _playSingleAyah(
            surahNumber,
            resumeAyah,
            resume: wasPlaying,
            mode: QuranPlaybackMode.ayahOnly,
          );
          return;
        }
        await _prepareAudioSource(preferOffline: true);
        await _loadAyahTimings(surahNumber);
        currentAyahNumber = resumeAyah;
        final start = _startForAyah(resumeAyah);
        if (start != null) {
          await _audioPlayer.player.seek(Duration(milliseconds: start));
        } else if (resumeAyah > 1) {
          await _playSingleAyah(
            surahNumber,
            resumeAyah,
            resume: false,
            mode: QuranPlaybackMode.fromAyah,
          );
        }
        _publishMediaItem();
        if (wasPlaying) await _startPlayback();
      } catch (_) {
        isAudioLoading = false;
        emit(_nextState);
        AppSnackBar.show(
          message:
              isOnline
                  ? 'تعذر تشغيل التلاوة بهذا القارئ، حاول مجددًا'
                  : 'هذا الملف غير محفوظ للاستماع دون اتصال',
        );
      }
    });
  }

  Future<void> setBackgroundAudioEnabled(bool enabled) async {
    backgroundAudioEnabled = enabled;
    await CacheHelper.saveData(
      key: 'quran_background_audio_enabled',
      value: enabled,
    );
    emit(_nextState);
  }

  Future<void> setReaderBackgroundColor({
    required bool darkMode,
    required Color? color,
  }) async {
    final key = darkMode
        ? _darkReaderBackgroundKey
        : _lightReaderBackgroundKey;
    final value = color?.toARGB32();
    if (darkMode) {
      darkReaderBackgroundColorValue = value;
    } else {
      lightReaderBackgroundColorValue = value;
    }
    emit(_nextState);
    if (value == null) {
      await CacheHelper.removeData(key: key);
    } else {
      await CacheHelper.saveData(key: key, value: value);
    }
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (backgroundAudioEnabled ||
        (state != AppLifecycleState.paused &&
            state != AppLifecycleState.hidden) ||
        !isPlaying) {
      return;
    }
    unawaited(_enqueueAudioCommand(() => _audioPlayer.pause()));
  }

  Future<List<QuranDownloadedAudio>> downloadedAudios() =>
      _audioRepository.downloadedAudios();

  Future<void> refreshCurrentSurahDownloadStatus() async {
    final url = currentSurahAudioUrl;
    final revision = ++_downloadStatusRevision;
    if (url.isEmpty) return;
    var downloaded = false;
    try {
      downloaded = (await _audioRepository.downloadedAudios()).any(
        (audio) => audio.url == url,
      );
    } catch (_) {
      downloaded = false;
    }
    if (isClosed ||
        revision != _downloadStatusRevision ||
        url != currentSurahAudioUrl) {
      return;
    }
    if (downloaded) {
      _knownDownloadedAudioUrls.add(url);
    } else {
      _knownDownloadedAudioUrls.remove(url);
    }
    emit(_nextState);
  }

  Future<void> deleteDownloadedAudio(String url) async {
    if (url == quranSoundUrl && quranSoundActive) {
      await _enqueueAudioCommand(() async {
        quranSoundActive = false;
        await _audioPlayer.stop();
        _audioSourcePrepared = false;
        emit(_nextState);
      });
    }
    await _audioRepository.deleteDownloadedAudio(url);
    _knownDownloadedAudioUrls.remove(url);
    _failedDownloadUrls.remove(url);
    downloadRevision++;
    if (url == currentSurahAudioUrl) isCached = false;
    emit(_nextState);
  }

  Future<void> togglePageBookmark(int mushafPageNumber) async {
    pageBookmarks = [...pageBookmarks];
    if (!pageBookmarks.remove(mushafPageNumber)) {
      pageBookmarks.add(mushafPageNumber);
    }
    await _bookmarkRepository.savePageBookmarks(pageBookmarks);
    bookmark = pageBookmarks.isEmpty
        ? null
        : QuranBookmark(pageNumber: pageBookmarks.last);
    emit(_nextState);
  }

  Future<void> playFromAyahBookmark(int number, int ayah) async {
    await _reciterReady;
    await _enqueueAudioCommand(() async {
      if (isDownloading) return;
      if (number < 1 || number > 114) return;
      if (ayah < 1 || ayah > quran.getVerseCount(number)) return;
      ++_seekRevision;
      _audioErrorReported = false;
      _audioStartTimeout?.cancel();
      await _switchSurahForPlayback(
        number,
        targetAyah: ayah,
        resume: true,
        mode: QuranPlaybackMode.fromAyah,
      );
    });
  }

  Future<void> toggleAyahBookmark(int bookmarkedSurah, int ayahNumber) async {
    final key = '$bookmarkedSurah:$ayahNumber';
    ayahBookmarks = {...ayahBookmarks};
    if (!ayahBookmarks.add(key)) ayahBookmarks.remove(key);
    await _bookmarkRepository.saveAyahBookmarks(ayahBookmarks);
    emit(_nextState);
  }

  Future<void> selectSurah(
    int number,
    String name, {
    required bool online,
    int? startAyah,
  }) async {
    await _reciterReady;
    if (surahNumber == number) return;
    // Reading navigation must never interrupt a live or paused audio session.
    // The reader can display another Surah independently while the shared
    // player remains bound to its current media item.
    final initialAyah = (startAyah ?? 1)
        .clamp(1, quran.getVerseCount(number))
        .toInt();
    _audioStartTimeout?.cancel();
    isCached = false;
    _audioSourcePrepared = false;
    _singleAyahPlayback = false;
    playbackMode = QuranPlaybackMode.fullSurah;
    _playbackSessionActive = false;
    _ayahTimings = const [];
    _preparingAudioSource = false;
    isAudioLoading = false;
    currentAyahNumber = initialAyah;
    currentPageNumber = initialAyah;
    quranSoundUrl = '';
    quranSoundActive = false;
    setSurahInfo(number, name);
    await _enqueueAudioCommand(() async {
      try {
        await _audioPlayer.stop();
        _audioPlayer.handler.clearMediaItem();
        quranSoundUrl = audioUrlFor(number);
        _persistCurrentAudioSource();
        final cachedPath = await _audioRepository.cachedPath(
          quranSoundUrl,
          legacyUrl: _legacyAlafasyUrl(number),
        );
        if (cachedPath != null) {
          await _audioPlayer.setFile(cachedPath);
          isCached = true;
        } else if (online || isOnline) {
          await _audioPlayer.setUrl(quranSoundUrl);
          isCached = false;
        } else {
          throw StateError('Surah is not available offline');
        }
        await _audioPlayer.player.seek(Duration.zero);
        _audioSourcePrepared = true;
        _sourceReciter = selectedReciter;
        _publishMediaItem();
      } catch (_) {
        _audioSourcePrepared = false;
      }
    });
    emit(_nextState);
  }

  Future<void> openAtAyah(
    int number,
    String name,
    int ayah, {
    required bool online,
    bool preservePlayback = false,
  }) async {
    await _reciterReady;
    final targetAyah = ayah.clamp(1, quran.getVerseCount(number)).toInt();
    if (preservePlayback && hasActivePlaybackSession) return;
    if (preservePlayback && number == surahNumber) {
      final savedPosition = _hasSavedAyahForSurah(number)
          ? lastAyahForSurah(number)
          : null;
      final readerAyah = savedPosition ?? targetAyah;
      currentAyahNumber = readerAyah;
      currentPageNumber = readerAyah;
      unawaited(_saveAyahPosition(readerAyah));
      _publishMediaItem();
      emit(_nextState);
      return;
    }
    if (isPlaying && !preservePlayback) {
      await playFromAyahBookmark(number, targetAyah);
      return;
    }

    if (surahNumber != number) {
      final readerAyah = preservePlayback
          ? lastAyahForSurah(number) ?? targetAyah
          : targetAyah;
      await selectSurah(
        number,
        name,
        online: online,
        startAyah: readerAyah,
      );
      return;
    }

    currentAyahNumber = targetAyah;
    currentPageNumber = targetAyah;
    unawaited(_saveAyahPosition(targetAyah));
    _publishMediaItem();
    emit(_nextState);
    final start = _startForAyah(targetAyah);
    if (start != null && _audioSourcePrepared) {
      await _enqueueAudioCommand(() async {
        if (surahNumber != number || currentAyahNumber != targetAyah) return;
        try {
          await _audioPlayer.player.seek(Duration(milliseconds: start));
        } catch (_) {
          // Reader navigation remains available if the current source cannot seek.
        }
      });
    }
  }

  String? _legacyAlafasyUrl(int number) =>
      selectedReciter.id == QuranReciter.all.first.id
          ? '${AppColors.quranSoundUrl}$number.mp3'
          : null;

  void setCurrentPageNumber(int pageNumber) {
    currentPageNumber = pageNumber;
    if (!hasActivePlaybackSession) {
      currentAyahNumber = pageNumber;
      unawaited(_saveAyahPosition(pageNumber));
    }
    unawaited(
      CacheHelper.saveData(key: 'quran_last_reader_verse', value: pageNumber),
    );
    saveReaderPosition(surahNumber, pageNumber);
    _publishMediaItem();
    emit(_nextState);
  }

  void restoreAudioAyah(int ayah) {
    if (surahNumber < 1) return;
    currentAyahNumber = ayah.clamp(1, quran.getVerseCount(surahNumber));
    currentPageNumber = currentAyahNumber;
    _publishMediaItem();
    emit(_nextState);
  }

  void setSurahInfo(int number, String name) {
    final surahChanged = surahNumber != number;
    if (surahChanged) {
      _pendingRestoredAudioPositionMs = null;
      _lastSavedAudioPositionMs = 0;
      _lastPositionWriteSurah = number;
      _lastPositionWriteReciter = selectedReciter.id;
    }
    surahNumber = number;
    surahName = name == 'اللهب' ? 'المسد' : name;
    if (number > 0) {
      unawaited(
        CacheHelper.saveData(key: 'quran_last_played_surah', value: number),
      );
    }
    _publishMediaItem();
    emit(_nextState);
    if (surahChanged) unawaited(refreshCurrentSurahDownloadStatus());
  }

  Future<void> setUrlQuranSoundSrcOnline({required String urlSrc}) =>
      _enqueueAudioCommand(() async {
        quranSoundActive = true;
        quranSoundUrl = urlSrc;
        _persistCurrentAudioSource();
        _audioSourcePrepared = false;
        _preparingAudioSource = true;
        _setAudioLoading(true);
        try {
          await _audioPlayer.setUrl(urlSrc);
          _audioSourcePrepared = true;
          _sourceReciter = selectedReciter;
        } finally {
          _preparingAudioSource = false;
          _setAudioLoading(false);
        }
      });

  Future<void> setUrlQuranSoundSrcOffline({required String urlSrc}) =>
      _enqueueAudioCommand(() async {
        quranSoundActive = true;
        _preparingAudioSource = true;
        _setAudioLoading(true);
        try {
          await _audioPlayer.setFile(urlSrc);
          _audioSourcePrepared = true;
          _sourceReciter = selectedReciter;
        } finally {
          _preparingAudioSource = false;
          _setAudioLoading(false);
        }
      });

  Future<void> changeQuranSoundActive() {
    debugPrint(
      'QuranWidgetPlay: Cubit received Stop surah=$surahNumber '
      'playing=${_audioPlayer.player.playing} active=$quranSoundActive '
      'position=${_audioPlayer.player.position}',
    );
    if (_stopCommandPending) return Future<void>.value();
    if (!quranSoundActive &&
        !_audioPlayer.player.playing &&
        !isAudioLoading &&
        _audioPlayer.player.processingState == ProcessingState.idle &&
        _audioPlayer.handler.mediaItem.value == null) {
      return Future<void>.value();
    }

    // Publish the stopped session immediately. The old implementation waited
    // for the serialized stop and seek before the Cubit reflected the button
    // tap, allowing repeated taps to queue duplicate stops and stale UI state.
    _stopCommandPending = true;
    _playCommandPending = false;
    _pauseCommandPending = false;
    quranSoundActive = false;
    _singleAyahPlayback = false;
    playbackMode = QuranPlaybackMode.fullSurah;
    _playbackSessionActive = false;
    _audioSourcePrepared = false;
    _pendingRestoredAudioPositionMs = null;
    _lastSavedAudioPositionMs = 0;
    if (surahNumber >= 1 && surahNumber <= 114) {
      unawaited(
        CacheHelper.removeData(
          key: _savedAudioPositionKey(selectedReciter.id, surahNumber),
        ),
      );
    }
    _audioStartTimeout?.cancel();
    isAudioLoading = false;
    emit(_nextState);

    return _enqueueAudioCommand(() async {
      try {
        try {
          await _audioPlayer.stop();
        } finally {
          try {
            await _audioPlayer.seekToStart();
          } finally {
            _audioPlayer.handler.clearMediaItem();
            debugPrint('QuranWidgetPlay: Stop completed and MediaSession cleared');
          }
        }
      } finally {
        _stopCommandPending = false;
        if (!isClosed) emit(_nextState);
      }
    });
  }

  Future<void> playAzan() async {
    await azanSound.setAsset(AppAssets.azan);
    await azanSound.play();
  }

  Future<void> stopAzan() => azanSound.stop();

  Future<void> togglePlay() {
    // just_audio may emit the new playing value a moment after a command. Do
    // not derive a second opposite command from that transitional value.
    if (_stopCommandPending || _playCommandPending || _pauseCommandPending) {
      return Future<void>.value();
    }
    return _audioPlayer.player.playing
        ? pausePlaybackFromMediaSession()
        : resumePlaybackFromMediaSession();
  }

  /// Entry point for Android MediaSession and widget Play commands. Unlike a
  /// UI toggle, a Play command must never pause an already-playing session.
  Future<void> resumePlaybackFromMediaSession() async {
    debugPrint(
      'QuranWidgetPlay: Cubit received Play surah=$surahNumber ayah=$currentAyahNumber '
      'playing=${_audioPlayer.player.playing} prepared=$_audioSourcePrepared active=$quranSoundActive '
      'position=${_audioPlayer.player.position}',
    );
    if (_audioPlayer.player.playing ||
        _stopCommandPending ||
        _playCommandPending ||
        _pauseCommandPending) {
      debugPrint('QuranWidgetPlay: Play ignored by state guard');
      return;
    }
    _playCommandPending = true;
    await _reciterReady;
    try {
      await _enqueueAudioCommand(() async {
        if (_audioPlayer.player.playing) return;
        // A stale third-party connectivity probe must not prevent the native
        // widget from resolving the existing Surah source. Prefer the local
        // cache first, then let the existing player report a genuine network
        // failure if the source cannot be reached.
        await _resumeQuranPlayback(allowNetworkWhenOffline: true);
      });
      debugPrint(
        'QuranWidgetPlay: resume command finished playing=${_audioPlayer.player.playing} '
        'loading=$isAudioLoading state=${_audioPlayer.player.playerState}',
      );
    } finally {
      // startPlayer intentionally returns after issuing play(), while the
      // actual PlayerState arrives on its stream. Keep duplicate Play events
      // coalesced until that stream confirms playback or loading fails/ends.
      if (_audioPlayer.player.playing ||
          (!isAudioLoading &&
              _audioPlayer.player.processingState != ProcessingState.loading &&
              _audioPlayer.player.processingState != ProcessingState.buffering)) {
        _playCommandPending = false;
      }
    }
  }

  Future<void> pausePlaybackFromMediaSession() async {
    if (_stopCommandPending ||
        !_audioPlayer.player.playing ||
        _playCommandPending ||
        _pauseCommandPending) {
      return;
    }
    _pauseCommandPending = true;
    try {
      await _enqueueAudioCommand(() async {
        if (_audioPlayer.player.playing) {
          await _audioPlayer.pause();
          _persistCurrentAudioPosition(
            _audioPlayer.player.position,
            force: true,
          );
        }
      });
    } finally {
      if (!_audioPlayer.player.playing) _pauseCommandPending = false;
    }
  }

  Future<void> _resumeQuranPlayback({
    bool allowNetworkWhenOffline = false,
  }) async {
    try {
      debugPrint(
        'QuranWidgetPlay: restore path surah=$surahNumber active=$quranSoundActive '
        'prepared=$_audioSourcePrepared pendingPosition=$_pendingRestoredAudioPositionMs',
      );
      if (surahNumber < 1) return;
      _audioErrorReported = false;
      if (_playbackSessionActive && _audioSourcePrepared) {
        await _startPlayback();
        return;
      }
      // The playback-session flag can outlive the prepared audio source during
      // a source transition. Treat that as a recoverable resume, not as a
      // ready player: _startPlayback would otherwise throw "source is not
      // ready" and the shared failure handler would clear the MediaSession.
      if (_playbackSessionActive && !_audioSourcePrepared) {
        _playbackSessionActive = false;
      }
      final restoredPositionMs = _pendingRestoredAudioPositionMs;
      if (restoredPositionMs != null) {
        _pendingRestoredAudioPositionMs = null;
        await _switchSurahForPlayback(
          surahNumber,
          targetAyah: currentAyahNumber,
          resume: true,
          mode: QuranPlaybackMode.fromAyah,
          allowNetworkWhenOffline: allowNetworkWhenOffline,
          restorePositionMs: restoredPositionMs,
        );
        return;
      }
      if (playbackMode == QuranPlaybackMode.ayahOnly) {
        await _playSingleAyah(
          surahNumber,
          currentAyahNumber,
          resume: true,
          mode: QuranPlaybackMode.ayahOnly,
        );
        return;
      }
      if (currentAyahNumber > 1) {
        await _switchSurahForPlayback(
          surahNumber,
          targetAyah: currentAyahNumber,
          resume: true,
          mode: QuranPlaybackMode.fromAyah,
          allowNetworkWhenOffline: allowNetworkWhenOffline,
        );
        return;
      }
      quranSoundActive = true;
      _publishMediaItem();
      await _prepareAudioSource(
        preferOffline: true,
        allowNetworkWhenOffline: allowNetworkWhenOffline,
      );
      await _startPlayback();
      if (!_singleAyahPlayback) unawaited(_loadAyahTimings(surahNumber));
    } catch (_) {
      unawaited(_handleAudioFailure(force: true));
    }
  }

  Future<void> _prepareAudioSource({
    required bool preferOffline,
    bool allowNetworkWhenOffline = false,
  }) async {
    if (_audioSourcePrepared) return;
    if (surahNumber < 1) throw StateError('No Surah selected');

    _singleAyahPlayback = false;
    quranSoundUrl = audioUrlFor(surahNumber);
    _persistCurrentAudioSource();
    _preparingAudioSource = true;
    _setAudioLoading(true);
    try {
      if (preferOffline) {
        final cachedPath = await _audioRepository.cachedPath(
          quranSoundUrl,
          legacyUrl: _legacyAlafasyUrl(surahNumber),
        );
        if (cachedPath != null) {
          try {
            await _audioPlayer.setFile(cachedPath);
            isCached = true;
            _audioSourcePrepared = true;
            _sourceReciter = selectedReciter;
            return;
          } catch (_) {
            isCached = false;
            _audioSourcePrepared = false;
          }
        }
        if (!isOnline && !allowNetworkWhenOffline) {
          throw StateError('Offline Quran audio is unavailable');
        }
      }

      await _audioPlayer.setUrl(quranSoundUrl);
      _audioSourcePrepared = true;
      _sourceReciter = selectedReciter;
    } finally {
      _preparingAudioSource = false;
      _setAudioLoading(false);
    }
  }

  Future<void> _startPlayback() async {
    if (!_audioSourcePrepared) {
      throw StateError('Quran audio source is not ready');
    }
    if (_audioPlayer.player.playing) return;
    if (_audioPlayer.player.processingState == ProcessingState.completed) {
      await _audioPlayer.seekToStart();
    }
    _publishMediaItem();
    debugPrint(
      'QuranWidgetPlay: starting source=$quranSoundUrl at ${_audioPlayer.player.position}',
    );
    _audioStartTimeout?.cancel();
    isAudioLoading = true;
    emit(_nextState);
    final playback = _audioPlayer.play();
    unawaited(
      playback.catchError((Object error, StackTrace stackTrace) {
        unawaited(_handleAudioFailure(force: true));
      }),
    );
    _audioStartTimeout = Timer(const Duration(seconds: 15), () {
      if (isAudioLoading) unawaited(_handleAudioFailure());
    });
  }

  void _handlePlayerState(PlayerState state) {
    if (isClosed) return;
    if (state.processingState == ProcessingState.idle &&
        quranSoundActive &&
        _audioSourcePrepared &&
        !_preparingAudioSource) {
      quranSoundActive = false;
      _playbackSessionActive = false;
      _singleAyahPlayback = false;
      _audioSourcePrepared = false;
      _audioPlayer.handler.clearMediaItem();
    }
    final completed = state.processingState == ProcessingState.completed;
    final isActuallyPlaying = state.playing && !completed;
    if (isActuallyPlaying) {
      // A delayed idle event from the previous source can arrive while a
      // single-ayah replay is already playing. The player state is the source
      // of truth here, so restore the active flag when playback is confirmed.
      quranSoundActive = true;
      _playbackSessionActive = true;
      _playCommandPending = false;
    } else {
      if (_pauseCommandPending) _pauseCommandPending = false;
      if (_playCommandPending &&
          !isAudioLoading &&
          state.processingState != ProcessingState.loading &&
          state.processingState != ProcessingState.buffering) {
        _playCommandPending = false;
      }
    }

    final buffering =
        state.processingState == ProcessingState.loading ||
        (state.processingState == ProcessingState.buffering && state.playing);
    if (buffering) {
      isAudioLoading = true;
    } else if (state.processingState == ProcessingState.ready ||
        completed ||
        (!state.playing && !_preparingAudioSource)) {
      isAudioLoading = false;
      _audioStartTimeout?.cancel();
    }
    emit(_nextState);
    if (completed && quranSoundActive && !_advancingCompletedSurah) {
      if (playbackMode == QuranPlaybackMode.ayahOnly) {
        quranSoundActive = false;
        _playbackSessionActive = false;
        _singleAyahPlayback = false;
        _audioPlayer.handler.clearMediaItem();
        emit(_nextState);
        return;
      }
      if (_singleAyahPlayback) {
        _advancingCompletedSurah = true;
        unawaited(
          _enqueueAudioCommand(() async {
            try {
              final verseCount = quran.getVerseCount(surahNumber);
              if (currentAyahNumber < verseCount) {
                await _playSingleAyah(
                  surahNumber,
                  currentAyahNumber + 1,
                  resume: true,
                );
              } else if (surahNumber < 114) {
                await _switchSurahForPlayback(
                  surahNumber + 1,
                  targetAyah: 1,
                  resume: true,
                );
              } else {
                quranSoundActive = false;
                _playbackSessionActive = false;
                _audioPlayer.handler.clearMediaItem();
                emit(_nextState);
              }
            } catch (_) {
              quranSoundActive = false;
              _playbackSessionActive = false;
              _audioPlayer.handler.clearMediaItem();
              emit(_nextState);
            } finally {
              _advancingCompletedSurah = false;
            }
          }),
        );
        return;
      }
      if (surahNumber < 114) {
        _advancingCompletedSurah = true;
        unawaited(
          _enqueueAudioCommand(() async {
            try {
              await _switchSurahForPlayback(
                surahNumber + 1,
                targetAyah: 1,
                resume: true,
                mode: QuranPlaybackMode.fullSurah,
              );
            } catch (_) {
              quranSoundActive = false;
              _playbackSessionActive = false;
              _audioPlayer.handler.clearMediaItem();
              emit(_nextState);
            } finally {
              _advancingCompletedSurah = false;
            }
          }),
        );
      } else {
        quranSoundActive = false;
        _playbackSessionActive = false;
        _audioPlayer.handler.clearMediaItem();
        emit(_nextState);
      }
    }
  }

  void _handlePlayerError(PlayerException _) =>
      unawaited(_handleAudioFailure(force: true));

  Future<void> _handleAudioFailure({bool force = false}) async {
    if (isClosed ||
        _audioErrorReported ||
        (!force &&
            !isAudioLoading &&
            !isPlaying &&
            !_audioPlayer.player.playing)) {
      return;
    }
    _audioErrorReported = true;
    _playCommandPending = false;
    _pauseCommandPending = false;
    _audioStartTimeout?.cancel();
    isAudioLoading = false;
    quranSoundActive = false;
    _singleAyahPlayback = false;
    _playbackSessionActive = false;
    _audioSourcePrepared = false;
    _audioPlayer.handler.clearMediaItem();
    emit(_nextState);
    unawaited(_enqueueAudioCommand(() => _audioPlayer.stop()));
    final hasConnection = await _hasInternetConnection();
    if (isClosed) return;
    AppSnackBar.show(
      message:
          hasConnection
              ? 'تعذر تشغيل التلاوة، حاول مجددًا'
              : 'لا يوجد اتصال بالإنترنت. اتصل بالإنترنت وحاول مجددًا',
    );
  }

  Future<bool> _hasInternetConnection() async {
    try {
      return await InternetConnectionChecker.instance.hasConnection;
    } catch (_) {
      return true;
    }
  }

  void _setAudioLoading(bool value) {
    if (isClosed) return;
    if (isAudioLoading == value) return;
    isAudioLoading = value;
    emit(_nextState);
  }

  Future<void> _enqueueAudioCommand(Future<void> Function() command) {
    final operation = _audioCommandQueue.then((_) => command());
    _audioCommandQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> downloadSurahSound() async {
    if (!canDownloadCurrentSurah) {
      AppSnackBar.show(message: 'لا يتوفر تنزيل لهذا القارئ');
      return;
    }
    final number = surahNumber;
    final url = audioUrlFor(number);
    if (_downloadingAudioUrls.contains(url) ||
        _knownDownloadedAudioUrls.contains(url)) {
      return;
    }
    _downloadStatusRevision++;
    _failedDownloadUrls.remove(url);
    _downloadingAudioUrls.add(url);
    downloadRevision++;
    emit(_nextState);
    try {
      // The repository also records the URL for Download Management. Its
      // cache manager reuses an existing file, so this remains safe when the
      // audio was cached by an earlier playback session.
      await _audioRepository.download(url);
      _knownDownloadedAudioUrls.add(url);
      _failedDownloadUrls.remove(url);
      if (url == currentSurahAudioUrl) {
        quranSoundUrl = url;
        isCached = true;
      }
      AppSnackBar.show(message: 'تم تحميل السورة بنجاح', success: true);
    } catch (_) {
      _failedDownloadUrls.add(url);
      AppSnackBar.show(
        message: 'تعذر تحميل التلاوة، تحقق من الاتصال وحاول مجددًا',
      );
    } finally {
      _downloadingAudioUrls.remove(url);
      downloadRevision++;
      emit(_nextState);
    }
  }

  @override
  Future<void> close() async {
    _audioStartTimeout?.cancel();
    _audioPlayer.handler
      ..onPrevious = null
      ..onNext = null
      ..onPlayAction = null
      ..onPauseAction = null
      ..onStopAction = null;
    await _playerStateSubscription.cancel();
    await _playerErrorSubscription.cancel();
    await _positionSubscription.cancel();
    await _audioPlayer.dispose();
    await azanSound.dispose();
    return super.close();
  }
}
