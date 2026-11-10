import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/data/services/kahf_reminder_service.dart';
import '../../domain/khatmah_plan.dart';

class KhatmahCubit extends Cubit<KhatmahPlan?> {
  KhatmahCubit() : super(null) { load(); }
  static const _key = 'khatmah_plan_v1';
  Future<void> _saveQueue = Future<void>.value();
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
    final encoded = jsonEncode(plan.toJson());
    final write = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, encoded);
    });
    _saveQueue = write.then<void>((_) {}, onError: (Object _) {});
    await write;
  }
  Future<void> create(int days) => _save(KhatmahPlan(durationDays: days, startedAt: DateTime.now(), completedPages: <int>{}, checkpointPage: 1, checkpointSurah: 1, checkpointAyah: 1));
  Future<void> recordReadingPosition({required int page, required int surah, required int ayah}) async {
    final plan = state;
    if (plan == null || plan.paused || page < 1 || page > 604 || surah < 1 || surah > 114 || ayah < 1) return;
    final alreadyRead = plan.completedPages.contains(page);
    if (alreadyRead && plan.checkpointPage == page && plan.checkpointSurah == surah && plan.checkpointAyah == ayah) return;
    final updated = plan.copyWith(completedPages: {...plan.completedPages, page}, checkpointPage: page, checkpointSurah: surah, checkpointAyah: ayah);
    await _save(updated);
    if (!alreadyRead && updated.reminderEnabled && updated.isDayComplete(updated.schedule[updated.currentDay - 1])) {
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
