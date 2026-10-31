import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:untitled8/components/components.dart';
import 'package:untitled8/components/constants.dart';
import 'package:untitled8/cubit/states.dart';
import 'package:untitled8/models/hadeeth.dart';
import 'package:untitled8/models/prayertimes.dart';
import '../shared/network/dio.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(InitialAppState());

  static AppCubit get(context) => BlocProvider.of(context);
  String? lat, long;
  DateTime now = DateTime.now();

  Future getLocation() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);

    lat = position.latitude.toString();
    long = position.longitude.toString();
    emit(GotLocationAppState());
  }

  PrayerTimesModel? prayerTimesModel;
  bool gotPrayerTimes = false;
  int elAsrHours = 0,
      elMaghribHours = 0,
      elIshaHours = 0,
      elDuhrHours = 0,
      elDuhrMins = 0,
      elFajrHours = 0,
      elAsrMins = 0,
      elMaghribMins = 0,
      elIshaMins = 0,
      elFajrMins = 0;

  int duhrDurationInHours = 0,
      duhrDurationInMins = 0,
      asrDurationInHours = 0,
      asrDurationInMins = 0,
      maghribDurationInHours = 0,
      maghribDurationInMins = 0,
      ishaDurationInHours = 0,
      ishaDurationInMins = 0,
      fajrDurationInHours = 0,
      fajrDurationInMins = 0;
  bool azanElDuhr = false,
      azanElAsr = false,
      azanElMaghrib = false,
      azanElIsha = false,
      azanElFajr = false;

  void getPrayerTime() {
    if (internetConnection) {
      getLocation().then((value) {
        DioHelper.getData(endPoint: 'calendar', query: {
          'latitude': lat,
          'longitude': long,
          'month': now.month,
          'year': now.year
        }).then((value) {
          prayerTimesModel = PrayerTimesModel.fromJson(value.data);
          gotPrayerTimes = true;
          emit(GotPrayerTimesAppState());
          elDuhrHours = int.parse(prayerTimesModel!.Dhuhr!.substring(0, 2));
          elDuhrMins = int.parse(prayerTimesModel!.Dhuhr!.substring(3, 5));
          elAsrHours = int.parse(prayerTimesModel!.Asr!.substring(0, 2));
          elAsrMins = int.parse(prayerTimesModel!.Asr!.substring(3, 5));
          elMaghribHours =
              int.parse(prayerTimesModel!.Maghrib!.substring(0, 2));
          elMaghribMins = int.parse(prayerTimesModel!.Maghrib!.substring(3, 5));
          elIshaHours = int.parse(prayerTimesModel!.Isha!.substring(0, 2));
          elIshaMins = int.parse(prayerTimesModel!.Isha!.substring(3, 5));
          elFajrHours = int.parse(prayerTimesModel!.Fajr!.substring(0, 2));
          elFajrMins = int.parse(prayerTimesModel!.Fajr!.substring(3, 5));

          duhrDurationInHours = elDuhrHours - DateTime.now().hour;
          duhrDurationInMins = elDuhrMins - DateTime.now().minute;

          asrDurationInHours = elAsrHours - DateTime.now().hour;
          asrDurationInMins = elAsrMins - DateTime.now().minute;

          maghribDurationInHours = elMaghribHours - DateTime.now().hour;
          maghribDurationInMins = elMaghribMins - DateTime.now().minute;

          ishaDurationInHours = elIshaHours - DateTime.now().hour;
          ishaDurationInMins = elIshaMins - DateTime.now().minute;

          fajrDurationInHours = elFajrHours - DateTime.now().hour;
          fajrDurationInMins = elFajrMins - DateTime.now().minute;
        }).catchError((error) {
          print(error.toString());
        });
      });
    }
  }

  bool isPlaying = false;

  AudioPlayer quranSound = AudioPlayer();
  AudioPlayer azanSound = AudioPlayer();
  IconData soundIcon = Icons.play_arrow;
  bool quranSoundActive = false;
  String surahName = '';
  int surahNumber = 0;
  int currentPageNumber = 0;
  bool isCached = false;
  String quranSoundUrl = "";

  void setCurrentPageNumber(int pageNumber) {
    currentPageNumber = pageNumber;
    emit(SetCurrentPageNumberAppState());
  }

  void setSurahInfo(int number, String name) {
    surahNumber = number;
    if (name == 'اللهب') {
      name = 'المسد';
    }
    surahName = name;
  }

  void setUrlQuranSoundSrcOnline({required String urlSrc}) {
    quranSoundActive = true;
    quranSoundUrl = urlSrc;
    quranSound.setUrl(urlSrc);
  }

  void setUrlQuranSoundSrcOffline({required String urlSrc}) {
    quranSoundActive = true;
    quranSound.setFilePath(urlSrc);
  }

  void changeQuranSoundActive() {
    soundIcon = Icons.play_arrow;
    quranSoundActive = false;
    quranSound.stop();
    quranSound.seek(Duration.zero);
    isPlaying = false;
    emit(ChangeQuranSoundActiveState());
  }

  void setUrlAzanSoundSrc() {
    azanSound.setAsset('assets/sounds/azan.mp3').then((value) {
      azanSound.play();
    });
  }

  void togglePlay() {
    if (!isPlaying) {
      quranSound.play();
      soundIcon = Icons.pause;
      emit(PlaySoundAppState());
    } else {
      quranSound.pause();
      soundIcon = Icons.play_arrow;
      emit(PauseSoundAppState());
    }
    isPlaying = !isPlaying;

    quranSound.playerStateStream.listen((event) {
      if (event.processingState == ProcessingState.completed ||
          (!isCached && !internetConnection)) {
        quranSound.seek(Duration.zero);
        quranSound.stop();
        isPlaying = false;
        soundIcon = Icons.play_arrow;
        emit(PauseSoundAppState());
      }
    });
  }

  bool isDownloading = false;

  void downloadSurahSound() {
    isDownloading = true;
    soundIcon = Icons.download;
    emit(DownloadSoundAppState());
    DefaultCacheManager().downloadFile(quranSoundUrl).then((value) {
      isCached = true;
      isDownloading = false;
      defaultFlutterToast(
          msg: "تم تحميل السورة بنجاح", backgroundColor: Colors.green);
      soundIcon = Icons.play_arrow;
      emit(DownloadSoundAppState());
    });
  }

  Hadeeth? hadeeth;
  bool gotHadeeths = false;

  void getHadeeth() {
    gotHadeeths = true;
    if (internetConnection) {
      for (int i = 1; i <= 2; i++) {
        // each iterate gets 20 hadeeth
        DioHelper.getHadeeth(endPoint: 'hadeeths/list', query: {
          'language': 'ar',
          'category_id': 1,
          'page': i,
        }).then((value) {
          hadeeth = Hadeeth.getIds(value.data);
        }).then((value) {
          for (String id in Hadeeth.ids) {
            DioHelper.getHadeeth(endPoint: 'hadeeths/one', query: {
              'language': 'ar',
              'id': id,
            }).then((value) {
              hadeeth = Hadeeth.getHadeethInfo(value.data);
            });
          }
        });
      }
    }
  }

  List<int> azkarTimes = [];

  void incrementAzkarTimes(index) {
    azkarTimes[index]++;
    emit(IncrementAzkarTimesAppState());
  }

  void clearTimes(index) {
    azkarTimes[index] = 0;
    emit(ClearTimesAppState());
  }
}
