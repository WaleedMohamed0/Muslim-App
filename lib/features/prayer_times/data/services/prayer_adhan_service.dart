import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled8/features/prayer_times/domain/entities/prayer_alarm_time.dart';
import 'package:untitled8/features/prayer_times/domain/entities/adhan_audio_option.dart';

class PrayerAdhanSettings {
  const PrayerAdhanSettings({
    this.enabled = false,
    this.prayers = const {
      'fajr': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    },
    this.volume = .85,
    this.audioId = 'adhan_madinah',
  });

  final bool enabled;
  final Map<String, bool> prayers;
  final double volume;
  final String audioId;

  PrayerAdhanSettings copyWith({
    bool? enabled,
    Map<String, bool>? prayers,
    double? volume,
    String? audioId,
  }) =>
      PrayerAdhanSettings(
        enabled: enabled ?? this.enabled,
        prayers: prayers ?? this.prayers,
        volume: volume ?? this.volume,
        audioId: audioId ?? this.audioId,
      );
}

class PrayerAdhanService {
  PrayerAdhanService._();

  static final PrayerAdhanService instance = PrayerAdhanService._();
  static const _channel = MethodChannel('com.muslim/prayer_adhan');
  static const _enabledKey = 'adhan_enabled';
  static const _volumeKey = 'adhan_volume';
  static const _audioIdKey = 'adhan_audio_id';
  static const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  Future<PrayerAdhanSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PrayerAdhanSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      prayers: {
        for (final prayer in _prayers)
          prayer: prefs.getBool('adhan_$prayer') ?? true,
      },
      volume: prefs.getDouble(_volumeKey) ?? .85,
      audioId: AdhanAudioOption.byId(prefs.getString(_audioIdKey)).id,
    );
  }

  Future<void> saveSettings(PrayerAdhanSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setDouble(_volumeKey, settings.volume.clamp(0, 1).toDouble());
    await prefs.remove('adhan_audio_path');
    await prefs.remove('adhan_audio_name');
    for (final prayer in _prayers) {
      await prefs.setBool('adhan_$prayer', settings.prayers[prayer] ?? true);
    }
    final audioId = AdhanAudioOption.byId(settings.audioId).id;
    await prefs.setString(_audioIdKey, audioId);
    await _channel.invokeMethod<void>('saveSettings', {
      'enabled': settings.enabled,
      'volume': settings.volume.clamp(0, 1).toDouble(),
      'prayers': settings.prayers,
      'audioId': audioId,
    });
  }

  Future<void> updateSchedule(List<PrayerAlarmTime> alarms) async {
    await _channel.invokeMethod<void>('updateSchedule', {
      'alarms': [
        for (final alarm in alarms)
          {
            'id': '${alarm.prayerId}_${alarm.at.year}_${alarm.at.month}_${alarm.at.day}',
            'prayer': alarm.prayerId,
            'at': alarm.at.millisecondsSinceEpoch,
            'year': alarm.at.year,
            'month': alarm.at.month,
            'day': alarm.at.day,
            'hour': alarm.at.hour,
            'minute': alarm.at.minute,
          },
      ],
    });
  }

  Future<Map<String, bool>> permissionStatus() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('permissionStatus') ?? {};
    return {
      'exactAlarms': result['exactAlarms'] == true,
      'notifications': result['notifications'] == true,
      'batteryOptimized': result['batteryOptimized'] == true,
    };
  }

  Future<void> requestNotificationPermission() =>
      _channel.invokeMethod<void>('requestNotificationPermission');

  Future<void> requestExactAlarmPermission() =>
      _channel.invokeMethod<void>('requestExactAlarmPermission');

  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  Future<void> previewAudio(String audioId) =>
      _channel.invokeMethod<void>('previewAudio', {'audioId': audioId});

  Future<void> stopAudio() => _channel.invokeMethod<void>('stopAudio');
}
