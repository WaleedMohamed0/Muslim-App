import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quran_reciter.dart';

/// Owns the single Quran playback engine and publishes its state to Android's
/// media session/notification. The QuranCubit and system controls use this same
/// engine instance.
class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  QuranAudioHandler() {
    _playerStateSubscription = player.playerStateStream.listen(_publishState);
    _positionSubscription = player.positionStream.listen((position) {
      final current = playbackState.value;
      playbackState.add(
        current.copyWith(
          updatePosition: position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
        ),
      );
      _persistPositionCheckpoint(position);
    });
    _durationSubscription = player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && current.duration != duration) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  final ja.AudioPlayer player = ja.AudioPlayer();
  late final StreamSubscription<ja.PlayerState> _playerStateSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  Future<void> Function()? onPrevious;
  Future<void> Function()? onNext;
  Future<void> Function()? onPlayAction;
  Future<void> Function()? onPauseAction;
  Future<void> Function()? onStopAction;
  bool _standaloneRestorePending = false;
  String _lastCheckpointTrack = '';
  int _lastCheckpointPositionMs = 0;

  Future<void> setUrl(String url) => player.setUrl(url);
  Future<void> setFile(String path) => player.setFilePath(path);

  /// Starts the already prepared source without routing back through the
  /// MediaSession command callback. QuranCubit uses this for its own queue.
  Future<void> startPlayer() async {
    if (player.processingState == ja.ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }

  Future<void> pausePlayer() => player.pause();

  Future<void> stopPlayer() => player.stop();

  void updateQuranMediaItem({
    required String surahName,
    required int surahNumber,
    required int mushafPageNumber,
    required String reciterName,
    required String reciterId,
    required String sourceUrl,
    Uri? artworkUri,
    int? ayahNumber,
  }) {
    final item = MediaItem(
      id: 'quran:$surahName:$reciterName',
      album: 'القرآن الكريم',
      title:
          'سورة $surahName${ayahNumber == null ? '' : ' • الآية $ayahNumber'}',
      artist: reciterName,
      duration: player.duration,
      artUri: artworkUri,
      displayTitle: 'سورة $surahName',
      displaySubtitle: reciterName,
      displayDescription:
          ayahNumber == null ? 'القرآن الكريم' : 'الآية $ayahNumber',
      extras: {
        'surahName': surahName,
        'surahNumber': surahNumber,
        'mushafPageNumber': mushafPageNumber,
        'reciterName': reciterName,
        'reciterId': reciterId,
        'sourceUrl': sourceUrl,
        'ayahNumber': ayahNumber,
      },
    );
    mediaItem.add(item);
    queue.add([item]);
    _publishState(player.playerState);
  }

  void clearMediaItem() {
    mediaItem.add(null);
    queue.add(const []);
    playbackState.add(
      PlaybackState(
        controls: const [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1,
      ),
    );
  }

  void _publishState(ja.PlayerState state) {
    final isPlaying =
        state.playing && state.processingState != ja.ProcessingState.completed;
    final controls = <MediaControl>[
      if (onNext != null) MediaControl.skipToNext,
      isPlaying ? MediaControl.pause : MediaControl.play,
      if (onPrevious != null) MediaControl.skipToPrevious,
      MediaControl.stop,
    ];
    playbackState.add(
      PlaybackState(
        controls: controls,
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {MediaAction.seek},
        processingState: switch (state.processingState) {
          ja.ProcessingState.idle => AudioProcessingState.idle,
          ja.ProcessingState.loading => AudioProcessingState.loading,
          ja.ProcessingState.buffering => AudioProcessingState.buffering,
          ja.ProcessingState.ready => AudioProcessingState.ready,
          ja.ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: isPlaying,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ),
    );
  }

  void _persistPositionCheckpoint(Duration position) {
    final extras = mediaItem.value?.extras;
    final surahNumber = extras?['surahNumber'];
    final reciterId = extras?['reciterId'];
    if (surahNumber is! int ||
        surahNumber < 1 ||
        surahNumber > 114 ||
        reciterId is! String ||
        reciterId.isEmpty) {
      return;
    }
    final positionMs = position.inMilliseconds.clamp(0, 0x7fffffff).toInt();
    final track = '$reciterId:$surahNumber';
    if (track == _lastCheckpointTrack &&
        (positionMs - _lastCheckpointPositionMs).abs() < 900) {
      return;
    }
    _lastCheckpointTrack = track;
    _lastCheckpointPositionMs = positionMs;
    final sourceUrl = extras?['sourceUrl'];
    unawaited(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(
        'quran_audio_position_${reciterId}_$surahNumber',
        positionMs,
      );
      if (sourceUrl is String && sourceUrl.isNotEmpty) {
        await preferences.setString(
          'quran_audio_source_${reciterId}_$surahNumber',
          sourceUrl,
        );
      }
    }());
  }

  @override
  Future<void> play() async {
    final action = onPlayAction;
    if (action != null) {
      developer.log('Play received; forwarding to bound Quran Cubit', name: 'QuranAudioHandler');
      await action();
      return;
    }
    developer.log('Play received without a bound Cubit; restoring the saved source', name: 'QuranAudioHandler');
    if (_standaloneRestorePending) return;
    _standaloneRestorePending = true;
    try {
      await _resumeOrRestoreSavedSession();
    } finally {
      _standaloneRestorePending = false;
    }
  }

  /// A widget Play command can arrive after Android has recreated the
  /// AudioService but before the Flutter UI/Cubit exists. Restore the last
  /// saved session into this existing service player instead of attempting to
  /// play an empty source or opening the Activity.
  Future<void> _resumeOrRestoreSavedSession() async {
    if (player.playing) {
      developer.log('Player is already playing; no-op', name: 'QuranAudioHandler');
      return;
    }
    if (mediaItem.value != null &&
        player.processingState != ja.ProcessingState.idle) {
      developer.log('Resuming prepared source at ${player.position}', name: 'QuranAudioHandler');
      await startPlayer();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final surahNumber = preferences.getInt('quran_last_played_surah') ?? 0;
    if (surahNumber < 1 || surahNumber > 114) return;

    final reciterId = preferences.getString('quran_audio_reciter_id');
    final reciter = QuranReciter.byId(reciterId);
    final fullSurahUrl = reciter.surahUrl(surahNumber);
    final sourceKey = 'quran_audio_source_${reciter.id}_$surahNumber';
    final savedSourceUrl = preferences.getString(sourceKey);
    final ayahUrlPrefix = reciter.ayahAudioDirectory == null
        ? null
        : 'https://everyayah.com/data/${reciter.ayahAudioDirectory}/'
              '${surahNumber.toString().padLeft(3, '0')}';
    final audioUrl = savedSourceUrl == fullSurahUrl ||
            (ayahUrlPrefix != null &&
                savedSourceUrl != null &&
                savedSourceUrl.startsWith(ayahUrlPrefix) &&
                savedSourceUrl.endsWith('.mp3'))
        ? savedSourceUrl!
        : fullSurahUrl;
    developer.log('Restoring surah=$surahNumber reciter=${reciter.id} source=$audioUrl', name: 'QuranAudioHandler');
    final positionKey = 'quran_audio_position_${reciter.id}_$surahNumber';
    final savedPositionMs = (preferences.getInt(positionKey) ?? 0)
        .clamp(0, 0x7fffffff)
        .toInt();

    final cachedFile = await DefaultCacheManager()
        .getFileFromCache(audioUrl)
        .catchError((_) => null);
    if (cachedFile != null) {
      await player.setAudioSource(ja.AudioSource.file(cachedFile.file.path));
    } else {
      await player.setUrl(audioUrl);
    }
    await preferences.setString(sourceKey, audioUrl);

    final durationMs = player.duration?.inMilliseconds ?? 0;
    final safePositionMs = durationMs > 0
        ? savedPositionMs.clamp(0, durationMs).toInt()
        : savedPositionMs;
    await player.seek(Duration(milliseconds: safePositionMs));
    developer.log('Restored seek position=${player.position}', name: 'QuranAudioHandler');

    final savedAyah = preferences.getInt('quran_last_played_ayah_$surahNumber') ?? 1;
    final ayahNumber = savedAyah
        .clamp(1, quran.getVerseCount(surahNumber))
        .toInt();
    final rawSurahName = quran.getSurahNameArabic(surahNumber);
    final surahName = rawSurahName == 'اللهب' ? 'المسد' : rawSurahName;
    final item = MediaItem(
      id: 'quran:$surahName:${reciter.nameArabic}',
      album: 'القرآن الكريم',
      title: 'سورة $surahName • الآية $ayahNumber',
      artist: reciter.nameArabic,
      duration: player.duration,
      displayTitle: 'سورة $surahName',
      displaySubtitle: reciter.nameArabic,
      displayDescription: 'الآية $ayahNumber',
      extras: {
        'surahName': surahName,
        'surahNumber': surahNumber,
        'mushafPageNumber': quran.getPageNumber(surahNumber, ayahNumber),
        'reciterName': reciter.nameArabic,
        'reciterId': reciter.id,
        'sourceUrl': audioUrl,
        'ayahNumber': ayahNumber,
      },
    );
    mediaItem.add(item);
    queue.add([item]);
    _publishState(player.playerState);
    await startPlayer();
    developer.log('Restored source sent to player; state=${player.playerState}', name: 'QuranAudioHandler');
  }

  @override
  Future<void> pause() async {
    final action = onPauseAction;
    if (action != null) {
      await action();
      return;
    }
    await pausePlayer();
    await _persistStandalonePosition();
  }

  Future<void> _persistStandalonePosition() async {
    final item = mediaItem.value;
    final surahNumber = item?.extras?['surahNumber'];
    if (surahNumber is! int || surahNumber < 1 || surahNumber > 114) return;
    final preferences = await SharedPreferences.getInstance();
    final reciterId = preferences.getString('quran_audio_reciter_id');
    final reciter = QuranReciter.byId(reciterId);
    await preferences.setInt(
      'quran_audio_position_${reciter.id}_$surahNumber',
      player.position.inMilliseconds.clamp(0, 0x7fffffff).toInt(),
    );
  }

  @override
  Future<void> stop() async {
    final action = onStopAction;
    if (action != null) {
      developer.log('Stop received; forwarding to bound Quran Cubit', name: 'QuranAudioHandler');
      await action();
      return;
    }
    developer.log('Stop received without a bound Cubit; stopping shared player', name: 'QuranAudioHandler');
    await stopPlayer();
    clearMediaItem();
  }

  @override
  Future<void> skipToPrevious() async => onPrevious?.call();

  @override
  Future<void> skipToNext() async => onNext?.call();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> onTaskRemoved() async {
    // Keep active recitation running when Android removes the task from recents.
  }

  Future<void> dispose() async {
    await _playerStateSubscription.cancel();
    await _positionSubscription.cancel();
    await _durationSubscription.cancel();
    await player.dispose();
  }
}

Future<AudioHandler> initializeQuranAudioService() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  return AudioService.init(
    builder: QuranAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.muslim.quran_audio',
      androidNotificationChannelName: 'تلاوة القرآن الكريم',
      androidNotificationChannelDescription: 'تشغيل تلاوة القرآن في الخلفية',
      androidNotificationIcon: 'mipmap/launcher_icon',
      // Keep the media service and its lock-screen controls available while
      // paused. audio_service requires ongoing=false for this configuration.
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
    ),
  );
}
