import 'package:flutter/material.dart';
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_state.dart';

class PrayerScheduleItem {
  const PrayerScheduleItem({
    required this.display,
    required this.time,
    required this.icon,
  });

  final PrayerDisplayTime display;
  final DateTime time;
  final IconData icon;
}
