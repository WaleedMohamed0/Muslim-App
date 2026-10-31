import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../domain/entities/prayer_times.dart';
import '../../domain/use_cases/get_prayer_times.dart';
import '../../data/data_sources/prayer_location_data_source.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({GetPrayerTimes? getPrayerTimes})
      : _getPrayerTimes = getPrayerTimes ?? GetPrayerTimes(PrayerTimesRepositoryImpl(PrayerLocationDataSource())),
        super(const PrayerTimesState());

  final GetPrayerTimes _getPrayerTimes;

  DateTime now = DateTime.now();
  PrayerTimes? prayerTimesModel;
  bool gotPrayerTimes = false;
  int elAsrHours = 0, elMaghribHours = 0, elIshaHours = 0, elDuhrHours = 0,
      elDuhrMins = 0, elFajrHours = 0, elAsrMins = 0, elMaghribMins = 0,
      elIshaMins = 0, elFajrMins = 0;
  bool azanElDuhr = false, azanElAsr = false, azanElMaghrib = false,
      azanElIsha = false, azanElFajr = false;
  Timer? _minuteTimer;
  bool isOnline = false;

  void setConnectivity(bool connected) {
    isOnline = connected;
    if (connected && state.status == PrayerTimesStatus.initial) getPrayerTime();
  }
  bool _azanTriggered = false;

  void startPrayerMonitoring() {
    _minuteTimer?.cancel();
    _minuteTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      azanElFajr = now.hour == elFajrHours && now.minute == elFajrMins;
      azanElDuhr = now.hour == elDuhrHours && now.minute == elDuhrMins;
      azanElAsr = now.hour == elAsrHours && now.minute == elAsrMins;
      azanElMaghrib = now.hour == elMaghribHours && now.minute == elMaghribMins;
      azanElIsha = now.hour == elIshaHours && now.minute == elIshaMins;
      if (azanElFajr || azanElDuhr || azanElAsr || azanElMaghrib || azanElIsha) {
        _minuteTimer?.cancel();
        _azanTriggered = true;
        emit(PrayerTimesState(prayerTimes: prayerTimesModel, status: PrayerTimesStatus.loaded, azanPrayer: currentAzanPrayer, displayTimes: state.displayTimes));
      }
    });
  }

  String? get currentAzanPrayer => azanElFajr ? 'الفَجرِ' : azanElDuhr ? 'الظُّهرِ' : azanElAsr ? 'العَصرِ' : azanElMaghrib ? 'المغرِب' : azanElIsha ? 'العِشَاءِ' : null;

  @override
  Future<void> close() {
    _minuteTimer?.cancel();
    return super.close();
  }

  Future<void> getPrayerTime() async {
    try {
      if (!isOnline) {
        emit(const PrayerTimesState(error: 'Internet connection required', status: PrayerTimesStatus.failure));
        return;
      }
      emit(const PrayerTimesState(status: PrayerTimesStatus.loading));
      final times = await _getPrayerTimes(now);
      prayerTimesModel = times;
      elDuhrHours = times.dhuhr.hour;
      elDuhrMins = times.dhuhr.minute;
      elAsrHours = times.asr.hour;
      elAsrMins = times.asr.minute;
      elMaghribHours = times.maghrib.hour;
      elMaghribMins = times.maghrib.minute;
      elIshaHours = times.isha.hour;
      elIshaMins = times.isha.minute;
      elFajrHours = times.fajr.hour;
      elFajrMins = times.fajr.minute;
      gotPrayerTimes = true;
      emit(PrayerTimesState(prayerTimes: times, status: PrayerTimesStatus.loaded, displayTimes: [
        _display('الفَجرِ', times.fajr, true),
        _display('الظُّهرِ', times.dhuhr, true),
        _display('العَصرِ', times.asr, false),
        _display('المغرِب', times.maghrib, false),
        _display('العِشَاءِ', times.isha, false),
      ]));
      if (!_azanTriggered) startPrayerMonitoring();
    } catch (error) {
      emit(PrayerTimesState(error: error.toString(), status: PrayerTimesStatus.failure));
    }
  }

  PrayerDisplayTime _display(String name, DateTime time, bool morning) => PrayerDisplayTime(
    name: name,
    time: '${(time.hour % 12 == 0 ? 12 : time.hour % 12).toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
    period: morning ? 'ص' : 'م',
  );
}
