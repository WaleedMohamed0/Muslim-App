import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/data/services/kahf_reminder_service.dart';
import '../../domain/khatmah_plan.dart';

class KhatmahCubit extends Cubit<KhatmahPlan?> {
  KhatmahCubit() : super(null) { load(); }
  static const _key = 'khatmah_plan_v1';
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || isClosed) return;
    try {
      final plan = KhatmahPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      emit(plan);
      if (plan.reminderEnabled) {
        await KahfReminderService.instance.scheduleKhatmah(enabled: true, hour: plan.reminderHour, minute: plan.reminderMinute);
      }
    } catch (_) { await prefs.remove(_key); }
  }
  Future<void> _save(KhatmahPlan plan) async {
    emit(plan);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plan.toJson()));
  }
  Future<void> create(int days) => _save(KhatmahPlan(durationDays: days, startedAt: DateTime.now(), completedPages: <int>{}));
  Future<void> recordPage(int page) async {
    final plan = state;
    if (plan == null || plan.paused || page < 1 || page > 604 || plan.completedPages.contains(page)) return;
    final updated = plan.copyWith(completedPages: {...plan.completedPages, page});
    await _save(updated);
    if (updated.reminderEnabled && updated.isDayComplete(updated.schedule[updated.currentDay - 1])) {
      await KahfReminderService.instance.scheduleKhatmah(enabled: true, hour: updated.reminderHour, minute: updated.reminderMinute, skipToday: true);
    }
  }
  Future<void> setPaused(bool value) async { if (state case final plan?) await _save(plan.copyWith(paused: value)); }
  Future<void> setReminder({required bool enabled, required int hour, required int minute}) async {
    if (state case final plan?) {
      if (enabled) await KahfReminderService.instance.requestPermission();
      await _save(plan.copyWith(reminderEnabled: enabled, reminderHour: hour, reminderMinute: minute));
      await KahfReminderService.instance.scheduleKhatmah(enabled: enabled, hour: hour, minute: minute);
    }
  }
  Future<void> restart() async { if (state case final plan?) await create(plan.durationDays); }
  Future<void> cancel() async { emit(null); final prefs = await SharedPreferences.getInstance(); await prefs.remove(_key); }
}
