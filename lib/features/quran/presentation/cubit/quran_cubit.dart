import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../data/data_sources/quran_audio_player.dart';
import '../../data/repositories/quran_audio_repository.dart';
import '../../domain/repositories/quran_audio_repository.dart' as contract;
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';
import '../../data/repositories/quran_bookmark_repository_impl.dart';

import 'quran_state.dart';
import '../../../../core/assets/app_assets.dart';

class QuranCubit extends Cubit<QuranState> {
  QuranCubit({contract.QuranAudioRepository? audioRepository, QuranAudioPlayer? audioPlayer, QuranBookmarkRepository? bookmarkRepository})
      : _audioRepository = audioRepository ?? QuranAudioRepository(),
        _audioPlayer = audioPlayer ?? QuranAudioPlayer(),
        _bookmarkRepository = bookmarkRepository ?? QuranBookmarkRepositoryImpl(),
        super(const QuranState());

  final contract.QuranAudioRepository _audioRepository;
  final QuranAudioPlayer _audioPlayer;
  final QuranBookmarkRepository _bookmarkRepository;
  final AudioPlayer azanSound = AudioPlayer();
  String surahName = '';
  int surahNumber = 0;
  int currentPageNumber = 0;
  bool isPlaying = false;
  bool isCached = false;
  bool isDownloading = false;
  bool quranSoundActive = false;
  String quranSoundUrl = '';
  IconData soundIcon = Icons.play_arrow;
  String audioUrlFor(int number) => _audioRepository.urlFor(number);
  Future<void> playCurrentSurahOnline(int number) async {
    if (quranSoundUrl != audioUrlFor(number)) {
      await setUrlQuranSoundSrcOnline(urlSrc: audioUrlFor(number));
    }
    await togglePlay();
  }
  QuranBookmark? bookmark;
  int _revision = 0;
  bool isOnline = false;
  void setConnectivity(bool connected) { isOnline = connected; emit(_nextState); }
  QuranState get _nextState => QuranState(revision: ++_revision);
  bool bookmarkPromptShown = false;

  Future<void> loadBookmark() async {
    bookmark = await _bookmarkRepository.read();
    emit(_nextState);
  }

  Future<void> initialize() => loadBookmark();

  void markBookmarkPromptShown() => bookmarkPromptShown = true;

  Future<void> toggleBookmark(String name) async {
    if (bookmark?.pageNumber == currentPageNumber) {
      await _bookmarkRepository.clear();
      bookmark = null;
    } else {
      bookmark = QuranBookmark(surahNumber: surahNumber, surahName: name, pageNumber: currentPageNumber);
      await _bookmarkRepository.save(bookmark!);
    }
    emit(_nextState);
  }

  Future<void> selectSurah(int number, String name, {required bool online}) async {
    if (surahNumber == number) return;
    final url = _audioRepository.urlFor(number);
    final cachedPath = await _audioRepository.cachedPath(number);
    isCached = cachedPath != null;
    setSurahInfo(number, name);
    quranSoundActive = true;
    if (cachedPath != null) {
      await setUrlQuranSoundSrcOffline(urlSrc: cachedPath);
    } else if (online) {
      await setUrlQuranSoundSrcOnline(urlSrc: url);
    }
    if (isPlaying) await togglePlay();
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

  Future<void> setUrlQuranSoundSrcOnline({required String urlSrc}) async {
    quranSoundActive = true;
    quranSoundUrl = urlSrc;
    await _audioPlayer.setUrl(urlSrc);
    emit(_nextState);
  }

  Future<void> setUrlQuranSoundSrcOffline({required String urlSrc}) async {
    quranSoundActive = true;
    await _audioPlayer.setFile(urlSrc);
    emit(_nextState);
  }

  Future<void> changeQuranSoundActive() async {
    soundIcon = Icons.play_arrow;
    quranSoundActive = false;
    isPlaying = false;
    await _audioPlayer.stop();
    await _audioPlayer.seekToStart();
    emit(_nextState);
  }

  Future<void> playAzan() async {
    await azanSound.setAsset(AppAssets.azan);
    await azanSound.play();
  }

  Future<void> stopAzan() => azanSound.stop();

  Future<void> togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
      soundIcon = Icons.play_arrow;
    } else {
      await _audioPlayer.play();
      soundIcon = Icons.pause;
    }
    isPlaying = !isPlaying;
    emit(_nextState);
  }

  Future<void> downloadSurahSound() async {
    isDownloading = true;
    soundIcon = Icons.download;
    emit(const QuranState());
    try {
      await _audioRepository.download(quranSoundUrl);
      isCached = true;
      defaultFlutterToast(
        msg: 'تم تحميل السورة بنجاح',
        backgroundColor: Colors.green,
      );
    } catch (_) {
      rethrow;
    } finally {
      isDownloading = false;
      soundIcon = Icons.play_arrow;
      emit(_nextState);
    }
  }

  @override
  Future<void> close() async {
    await _audioPlayer.dispose();
    await azanSound.dispose();
    return super.close();
  }
}
