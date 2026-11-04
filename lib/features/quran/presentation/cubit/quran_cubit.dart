import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      _updateAyahFromPosition,
    );
    _audioPlayer.handler
      ..onPrevious = previousAyah
      ..onNext = nextAyah
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
  bool isPlaying = false;
  bool _playbackSessionActive = false;
  bool isAudioLoading = false;
  bool isCached = false;
  bool quranSoundActive = false;
  String quranSoundUrl = '';
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
  Duration? get audioDuration => _audioPlayer.player.duration;
  bool _audioSourcePrepared = false;
  bool _singleAyahPlayback = false;
  QuranPlaybackMode playbackMode = QuranPlaybackMode.fullSurah;
  bool _preparingAudioSource = false;
  bool _audioErrorReported = false;
  int _surahSelectionRevision = 0;
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
  IconData soundIcon = Icons.play_arrow;
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
    _audioPlayer.handler.updateQuranMediaItem(
      surahName: surahName,
      reciterName: reciter.nameArabic,
      artworkUri: _reciterArtworkUris[reciter.id],
      ayahNumber: currentAyahNumber > 0 ? currentAyahNumber : null,
    );
    if (_artworkRequests.add(reciter.id)) {
      unawaited(_loadReciterArtwork(reciter));
    }
  }

  Future<void> _loadReciterArtwork(QuranReciter reciter) async {
    final artwork = await QuranReciterArtworkCache.fileUriFor(reciter);
    if (isClosed || !quranSoundActive || displayReciter.id != reciter.id) {
      return;
    }
    _reciterArtworkUris[reciter.id] = artwork;
    _audioPlayer.handler.updateQuranMediaItem(
      surahName: surahName,
      reciterName: reciter.nameArabic,
      artworkUri: artwork,
      ayahNumber: currentAyahNumber > 0 ? currentAyahNumber : null,
    );
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
      if (preserveAyah != null && currentAyahNumber == preserveAyah) {
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

  void _updateAyahFromPosition(Duration position, {bool force = false}) {
    if (_ayahTimings.isEmpty || surahNumber < 1 || isClosed) return;
    QuranAyahTiming? current;
    for (final timing in _ayahTimings) {
      if (timing.ayah < 1) continue;
      if (timing.start > position) break;
      current = timing;
    }
    if (current == null || (!force && current.ayah == currentAyahNumber)) {
      return;
    }
    currentAyahNumber = current.ayah;
    currentPageNumber = current.ayah;
    unawaited(_saveAyahPosition(current.ayah));
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
      _publishMediaItem();
      emit(_nextState);
      unawaited(_saveAyahPosition(timing.ayah));
      try {
        await _audioPlayer.player.seek(timing.start);
      } catch (_) {
        _updateAyahFromPosition(_audioPlayer.player.position, force: true);
        AppSnackBar.show(message: 'تعذر الانتقال إلى موضع التلاوة');
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
        _publishMediaItem();
        emit(_nextState);
        unawaited(_saveAyahPosition(targetAyah));
        try {
          await _audioPlayer.player.seek(timing.start);
        } catch (_) {
          AppSnackBar.show(message: 'تعذر الانتقال إلى الآية');
        }
        return;
      }

      await _playSingleAyah(surahNumber, targetAyah, resume: true);
    });
  }

  Future<void> _navigateAyah({required bool previous}) =>
      _enqueueAudioCommand(() async {
        if (surahNumber < 1) return;
        playbackMode = QuranPlaybackMode.fromAyah;
        if (_ayahTimings.isEmpty) await _loadAyahTimings(surahNumber);
        if (_ayahTimings.isEmpty) {
          final targetAyah = currentAyahNumber + (previous ? -1 : 1);
          final verseCount = quran.getVerseCount(surahNumber);
          if (targetAyah >= 1 && targetAyah <= verseCount) {
            await _playSingleAyah(surahNumber, targetAyah, resume: isPlaying);
          } else {
            final adjacentSurah = surahNumber + (previous ? -1 : 1);
            if (adjacentSurah < 1 || adjacentSurah > 114) return;
            await _switchSurahForPlayback(
              adjacentSurah,
              targetAyah: previous ? quran.getVerseCount(adjacentSurah) : 1,
              resume: isPlaying,
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
              resume: isPlaying,
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
          _publishMediaItem();
          emit(_nextState);
          unawaited(_saveAyahPosition(timing.ayah));
          try {
            await _audioPlayer.player.seek(timing.start);
          } catch (_) {
            AppSnackBar.show(message: 'تعذر الانتقال إلى الآية');
            return;
          }
          if (isPlaying) await _startPlayback();
          return;
        }
        final adjacentSurah = surahNumber + (previous ? -1 : 1);
        if (adjacentSurah < 1 || adjacentSurah > 114) return;
        final resume = isPlaying;
        final targetAyah = previous ? quran.getVerseCount(adjacentSurah) : 1;
        await _switchSurahForPlayback(
          adjacentSurah,
          targetAyah: targetAyah,
          resume: resume,
        );
      });

  Future<void> _switchSurahForPlayback(
    int number, {
    required int targetAyah,
    required bool resume,
    QuranPlaybackMode mode = QuranPlaybackMode.fromAyah,
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
    unawaited(_saveAyahPosition(targetAyah));
    isPlaying = false;
    quranSoundUrl = audioUrlFor(number);
    _setAudioLoading(true);
    try {
      final cachedPath = await _audioRepository.cachedPath(
        quranSoundUrl,
        legacyUrl: _legacyAlafasyUrl(number),
      );
      if (cachedPath != null) {
        await _audioPlayer.setFile(cachedPath);
        isCached = true;
      } else if (isOnline) {
        await _audioPlayer.setUrl(quranSoundUrl);
      } else {
        throw StateError('Surah is not available offline');
      }
      _audioSourcePrepared = true;
      _sourceReciter = selectedReciter;
      await _loadAyahTimings(number);
      // Timing initialization may inspect the player's old zero position;
      // restore the requested bookmark position before publishing/seeking.
      currentAyahNumber = targetAyah;
      currentPageNumber = targetAyah;
      _publishMediaItem();
      emit(_nextState);
      final start = _startForAyah(targetAyah);
      if (start != null) {
        await _audioPlayer.player.seek(Duration(milliseconds: start));
      } else if (targetAyah > 1) {
        await _playSingleAyah(number, targetAyah, resume: resume);
        return;
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
    quranSoundActive = true;
    _playbackSessionActive = false;
    surahNumber = number;
    surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    quranSoundUrl = url;
    _sourceReciter = selectedReciter;
    playbackMode = mode;
    _singleAyahPlayback = true;
    _ayahTimings = const [];
    _audioSourcePrepared = false;
    isCached = false;
    isPlaying = false;
    _publishMediaItem();
    emit(_nextState);
    unawaited(_saveAyahPosition(ayah));
    await _audioPlayer.stop();
    isPlaying = false;
    _setAudioLoading(true);
    try {
      await _audioPlayer.setUrl(url);
      _audioSourcePrepared = true;
      _sourceReciter = selectedReciter;
      _publishMediaItem();
      if (resume) await _startPlayback();
    } catch (_) {
      _handleAudioFailure(force: true);
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
      _sourceReciter = null;
      _ayahTimings = const [];
      _singleAyahPlayback = false;
      await CacheHelper.saveData(key: _reciterPreferenceKey, value: reciter.id);
      isCached = false;
      quranSoundUrl = surahNumber > 0 ? audioUrlFor(surahNumber) : '';
      unawaited(refreshCurrentSurahDownloadStatus());
      isPlaying = false;
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
        isPlaying = false;
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
      ++_surahSelectionRevision;
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
    if (hasActivePlaybackSession) return;
    final initialAyah = (startAyah ?? lastAyahForSurah(number) ?? 1)
        .clamp(1, quran.getVerseCount(number))
        .toInt();
    ++_surahSelectionRevision;
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
    isPlaying = false;
    soundIcon = Icons.play_arrow;
    setSurahInfo(number, name);
    await _enqueueAudioCommand(() async {
      try {
        await _audioPlayer.stop();
        _audioPlayer.handler.clearMediaItem();
      } catch (_) {
        // Reading position should remain usable if a stale source cannot stop.
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

  Future<void> changeQuranSoundActive() => _enqueueAudioCommand(() async {
    quranSoundActive = false;
    _singleAyahPlayback = false;
    playbackMode = QuranPlaybackMode.fullSurah;
    _playbackSessionActive = false;
    _audioStartTimeout?.cancel();
    await _audioPlayer.stop();
    await _audioPlayer.seekToStart();
    _audioPlayer.handler.clearMediaItem();
    isAudioLoading = false;
    soundIcon = Icons.play_arrow;
    emit(_nextState);
  });

  Future<void> playAzan() async {
    await azanSound.setAsset(AppAssets.azan);
    await azanSound.play();
  }

  Future<void> stopAzan() => azanSound.stop();

  Future<void> togglePlay() => _enqueueAudioCommand(() async {
    if (_audioPlayer.player.playing) {
      await _audioPlayer.pause();
      return;
    }
    await _resumeQuranPlayback();
  });

  /// Entry point for Android MediaSession and widget Play commands. Unlike a
  /// UI toggle, a Play command must never pause an already-playing session.
  Future<void> resumePlaybackFromMediaSession() async {
    await _reciterReady;
    await _enqueueAudioCommand(() async {
      if (_audioPlayer.player.playing) return;
      await _resumeQuranPlayback();
    });
  }

  Future<void> pausePlaybackFromMediaSession() =>
      _enqueueAudioCommand(() async {
        if (_audioPlayer.player.playing) await _audioPlayer.pause();
      });

  Future<void> _resumeQuranPlayback() async {
    try {
      if (surahNumber < 1) return;
      _audioErrorReported = false;
      if (_playbackSessionActive) {
        await _startPlayback();
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
        );
        return;
      }
      quranSoundActive = true;
      _publishMediaItem();
      await _prepareAudioSource(preferOffline: true);
      await _startPlayback();
      if (!_singleAyahPlayback) unawaited(_loadAyahTimings(surahNumber));
    } catch (_) {
      _handleAudioFailure(force: true);
    }
  }

  Future<void> _prepareAudioSource({required bool preferOffline}) async {
    if (_audioSourcePrepared) return;
    if (surahNumber < 1) throw StateError('No Surah selected');

    _singleAyahPlayback = false;
    _preparingAudioSource = true;
    _setAudioLoading(true);
    try {
      if (preferOffline) {
        final currentUrl = audioUrlFor(surahNumber);
        final cachedPath = await _audioRepository.cachedPath(
          currentUrl,
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
        if (!isOnline) {
          throw StateError('Offline Quran audio is unavailable');
        }
      }

      quranSoundUrl = audioUrlFor(surahNumber);
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
    _audioStartTimeout?.cancel();
    isAudioLoading = true;
    emit(_nextState);
    final playback = _audioPlayer.play();
    unawaited(
      playback.catchError((Object error, StackTrace stackTrace) {
        _handleAudioFailure(force: true);
      }),
    );
    _audioStartTimeout = Timer(const Duration(seconds: 15), () {
      if (isAudioLoading) _handleAudioFailure();
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
    isPlaying = state.playing && !completed;
    if (isPlaying) _playbackSessionActive = true;
    soundIcon = isPlaying ? Icons.pause : Icons.play_arrow;

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
      _handleAudioFailure(force: true);

  void _handleAudioFailure({bool force = false}) {
    if (isClosed ||
        _audioErrorReported ||
        (!force &&
            !isAudioLoading &&
            !isPlaying &&
            !_audioPlayer.player.playing)) {
      return;
    }
    _audioErrorReported = true;
    _audioStartTimeout?.cancel();
    isPlaying = false;
    isAudioLoading = false;
    quranSoundActive = false;
    _singleAyahPlayback = false;
    _playbackSessionActive = false;
    soundIcon = Icons.play_arrow;
    _audioSourcePrepared = false;
    _audioPlayer.handler.clearMediaItem();
    emit(_nextState);
    AppSnackBar.show(message: 'تعذر تشغيل التلاوة، حاول مجددًا');
    unawaited(_enqueueAudioCommand(() => _audioPlayer.stop()));
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
