import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/data_sources/quran_audio_player.dart';
import '../../data/repositories/quran_audio_repository.dart';
import '../../domain/repositories/quran_audio_repository.dart' as contract;
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';
import '../../data/repositories/quran_bookmark_repository_impl.dart';
import '../../data/repositories/quran_tafsir_repository_impl.dart';
import '../../domain/repositories/quran_tafsir_repository.dart';
import '../../data/repositories/platform_quran_share_repository.dart';
import '../../domain/repositories/quran_share_repository.dart';

import 'quran_state.dart';
import '../../../../core/assets/app_assets.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit({
    contract.QuranAudioRepository? audioRepository,
    QuranAudioPlayer? audioPlayer,
    QuranBookmarkRepository? bookmarkRepository,
    QuranTafsirRepository? tafsirRepository,
    QuranShareRepository? shareRepository,
  }) : _audioRepository = audioRepository ?? QuranAudioRepository(),
       _audioPlayer = audioPlayer ?? QuranAudioPlayer(),
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
  }

  final contract.QuranAudioRepository _audioRepository;
  final QuranAudioPlayer _audioPlayer;
  final QuranBookmarkRepository _bookmarkRepository;
  final QuranTafsirRepository _tafsirRepository;
  final QuranShareRepository _shareRepository;
  final AudioPlayer azanSound = AudioPlayer();
  String surahName = '';
  int surahNumber = 0;
  int currentPageNumber = 0;
  bool isPlaying = false;
  bool isAudioLoading = false;
  bool isCached = false;
  bool isDownloading = false;
  bool quranSoundActive = false;
  String quranSoundUrl = '';
  bool _audioSourcePrepared = false;
  bool _preparingAudioSource = false;
  bool _audioErrorReported = false;
  int _surahSelectionRevision = 0;
  Future<void> _audioCommandQueue = Future<void>.value();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<PlayerException> _playerErrorSubscription;
  Timer? _audioStartTimeout;
  IconData soundIcon = Icons.play_arrow;
  String audioUrlFor(int number) => _audioRepository.urlFor(number);
  Future<void> playCurrentSurahOnline(int number) =>
      _enqueueAudioCommand(() async {
        if (number < 1) return;
        if (number != surahNumber) return;
        _audioErrorReported = false;
        quranSoundActive = true;
        quranSoundUrl = audioUrlFor(number);
        await _prepareAudioSource(preferOffline: false);
        await _startPlayback();
      });

  QuranBookmark? bookmark;
  int _revision = 0;
  bool isOnline = false;
  void setConnectivity(bool connected) {
    isOnline = connected;
    emit(_nextState);
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
    bookmark = await _bookmarkRepository.read();
    emit(_nextState);
  }

  Future<void> initialize() => loadBookmark();

  Future<void> toggleBookmark(String name) async {
    if (bookmark?.surahNumber == surahNumber &&
        bookmark?.pageNumber == currentPageNumber) {
      await _bookmarkRepository.clear();
      bookmark = null;
    } else {
      bookmark = QuranBookmark(
        surahNumber: surahNumber,
        surahName: name,
        pageNumber: currentPageNumber,
      );
      await _bookmarkRepository.save(bookmark!);
    }
    emit(_nextState);
  }

  Future<void> selectSurah(
    int number,
    String name, {
    required bool online,
  }) async {
    if (surahNumber == number) return;
    final selectionRevision = ++_surahSelectionRevision;
    final url = _audioRepository.urlFor(number);
    isCached = false;
    _audioSourcePrepared = false;
    quranSoundUrl = url;
    setSurahInfo(number, name);
    quranSoundActive = true;
    _preparingAudioSource = true;
    _setAudioLoading(true);
    await _enqueueAudioCommand(() async {
      try {
        await _audioPlayer.stop();
        if (selectionRevision != _surahSelectionRevision) return;
        final cachedPath = await _audioRepository.cachedPath(number);
        if (selectionRevision != _surahSelectionRevision) return;
        if (cachedPath == null) return;
        isCached = true;
        _preparingAudioSource = true;
        await _audioPlayer.setFile(cachedPath);
        if (selectionRevision == _surahSelectionRevision) {
          _audioSourcePrepared = true;
        }
      } catch (_) {
        // Cache lookup and offline preparation are optional.
        if (selectionRevision == _surahSelectionRevision) {
          isCached = false;
          _audioSourcePrepared = false;
        }
      } finally {
        if (selectionRevision == _surahSelectionRevision) {
          _preparingAudioSource = false;
          _setAudioLoading(false);
        }
      }
    });
  }

  void setCurrentPageNumber(int pageNumber) {
    currentPageNumber = pageNumber;
    emit(_nextState);
  }

  void setSurahInfo(int number, String name) {
    surahNumber = number;
    surahName = name == 'اللهب' ? 'المسد' : name;
    emit(_nextState);
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
        } finally {
          _preparingAudioSource = false;
          _setAudioLoading(false);
        }
      });

  Future<void> changeQuranSoundActive() => _enqueueAudioCommand(() async {
        quranSoundActive = false;
        _audioStartTimeout?.cancel();
        await _audioPlayer.stop();
        await _audioPlayer.seekToStart();
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
        try {
          if (_audioPlayer.player.playing) {
            await _audioPlayer.pause();
            return;
          }
          if (surahNumber < 1) return;
          _audioErrorReported = false;
          quranSoundActive = true;
          await _prepareAudioSource(preferOffline: true);
          await _startPlayback();
        } catch (_) {
          _handleAudioFailure(force: true);
        }
      });

  Future<void> _prepareAudioSource({required bool preferOffline}) async {
    if (_audioSourcePrepared) return;
    if (surahNumber < 1) throw StateError('No Surah selected');

    _preparingAudioSource = true;
    _setAudioLoading(true);
    try {
      if (preferOffline) {
        final cachedPath = await _audioRepository.cachedPath(surahNumber);
        if (cachedPath != null) {
          try {
            await _audioPlayer.setFile(cachedPath);
            isCached = true;
            _audioSourcePrepared = true;
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
    final completed = state.processingState == ProcessingState.completed;
    isPlaying = state.playing && !completed;
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
    soundIcon = Icons.play_arrow;
    _audioSourcePrepared = false;
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
    if (quranSoundUrl.isEmpty && surahNumber > 0) {
      quranSoundUrl = _audioRepository.urlFor(surahNumber);
    }
    isDownloading = true;
    soundIcon = Icons.download;
    emit(const QuranState());
    try {
      await _audioRepository.download(quranSoundUrl);
      isCached = true;
      AppSnackBar.show(
        message: 'تم تحميل السورة بنجاح',
        success: true,
      );
    } catch (_) {
      AppSnackBar.show(
        message: 'تعذر تحميل التلاوة، تحقق من الاتصال وحاول مجددًا',
      );
    } finally {
      isDownloading = false;
      _audioSourcePrepared = false;
      soundIcon = isPlaying ? Icons.pause : Icons.play_arrow;
      emit(_nextState);
    }
  }

  @override
  Future<void> close() async {
    _audioStartTimeout?.cancel();
    await _playerStateSubscription.cancel();
    await _playerErrorSubscription.cancel();
    await _audioPlayer.dispose();
    await azanSound.dispose();
    return super.close();
  }
}
