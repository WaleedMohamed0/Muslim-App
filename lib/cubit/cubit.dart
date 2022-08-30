import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:untitled8/cubit/states.dart';
import 'package:untitled8/models/prayertimes.dart';

import '../models/quran_sound.dart';
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
  int elAsrHours=0,
      elMaghribHours=0,
      elIshaHours=0,
      elDuhrHours=0,
      elDuhrMins=0,
      elFajrHours=0,
      elAsrMins=0,
      elMaghribMins=0,
      elIshaMins=0,
      elFajrMins=0;

  int duhrDurationInHours =0,
    duhrDurationInMins=0,
    asrDurationInHours=0,
    asrDurationInMins=0,
    maghribDurationInHours=0,
    maghribDurationInMins=0,
    ishaDurationInHours=0,
    ishaDurationInMins=0,
    fajrDurationInHours=0,
    fajrDurationInMins=0;
  bool azanElDuhr=false, azanElAsr=false, azanElMaghrib=false, azanElIsha=false, azanElFajr = false;
  void getPrayerTime() {
    getLocation().then((value) {
      DioHelper.getData(endPoint: 'calendar', query: {
        'latitude': lat,
        'longitude': long,
        'method': 5,
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
        elMaghribHours = int.parse(prayerTimesModel!.Maghrib!.substring(0, 2));
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

  bool isPlaying = false;

  AudioPlayer quranSound = AudioPlayer();
  AudioPlayer azanSound = AudioPlayer();
  IconData soundIcon = Icons.play_arrow;

  void setUrlQuranSoundSrc({required String urlSrc}) {
    quranSound.setUrl(urlSrc);
  }

  // File file = File('C:/Users/Waleed/Desktop/azan.mp3');

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
  }

// For Getting Surah Sound Ayah By Ayah
// but i found that i can get the link of Surah sound directly and easier..

// bool stopAudio = false;
//
// Future<void> setUrlSrc({required String urlSrc, int? numOfAyahs}) async {
//   if (nextAyah != numOfAyahs) {
//     await sound.setUrl(urlSrc).then((value) {
//       play();
//     });
//   }
//
//   // print(sound.duration!.inSeconds);
// }
//
// int nextAyah = 1;
// IconData soundIcon = Icons.play_arrow;
//
// void play() {
//   soundIcon = Icons.stop;
//   emit(ToggleIconAppState());
//
//   sound.play().then((value) {
//     sound.stop();
//     setUrlSrc(urlSrc: quranSound!.audio[nextAyah]);
//     nextAyah++;
//   });
//
//   emit(PlaySoundAppState());
// }
//
// void stop() {
//   print("STOPPED");
//   soundIcon = Icons.play_arrow;
//   sound.stop();
//       quranSound!.audio=[];
//
//   // sound.pause();
//   emit(ToggleIconAppState());
//
//   // emit(PauseSoundAppState());
//
// }
//
// QuranSound? quranSound;
//
// Future<void> getSound({required int surahNum}) async {
//   await DioHelper.getDataSound(endPoint: '$surahNum/ar.alafasy')
//       .then((value) {
//     quranSound = QuranSound.fromJson(value.data);
//     // print(quranSound!.audio[0]);
//   });
// }
}
