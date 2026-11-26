import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/error_reporting/diagnostic_context.dart';
import 'package:muslim/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_state.dart';

class TasbeehCubit extends Cubit<TasbeehState> with WidgetsBindingObserver {
  TasbeehCubit(TasbeehRepository repository)
      : _repository = repository,
        super(repository.cachedState ?? const TasbeehState()) {
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayRollover();
  }
  final TasbeehRepository _repository;
  Timer? _dayRolloverTimer;
  String? _activeLocalDate;
  Future<void>? _dateSync;

  String _localDateKey([DateTime? date]) {
    final localDate = date ?? DateTime.now();
    return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _dayRolloverTimer = Timer(nextMidnight.difference(now), () {
      unawaited(_syncDate().whenComplete(_scheduleDayRollover));
    });
  }

  Future<void> _syncDate() {
    final today = _localDateKey();
    if (_activeLocalDate == today || isClosed) return Future.value();
    final pending = _dateSync;
    if (pending != null) return pending;
    final sync = _repository.load().then((next) {
      if (!isClosed) emit(next);
      _activeLocalDate = today;
    });
    _dateSync = sync;
    return sync.whenComplete(() => _dateSync = null);
  }

  Future<void> load() async {
    try {
      emit(await _repository.load());
      _activeLocalDate = _localDateKey();
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduleDayRollover();
    unawaited(_syncDate().catchError((Object _) {}));
  }

  Future<void> increment() async {
    if (state.isLoading) return;
    final items = state.items
        .map((item) => item.dhikr == state.selectedDhikr ? item.copyWith(count: item.count + 1) : item)
        .toList(growable: false);
    final next = state.copyWith(items: items, dailyTotal: state.dailyTotal + 1);
    final previous = state.items.firstWhere(
      (item) => item.dhikr == state.selectedDhikr,
    );
    final updated = items.firstWhere(
      (item) => item.dhikr == state.selectedDhikr,
    );
    if (previous.count < updated.target &&
        updated.count >= updated.target) {
      DiagnosticContext.log('Tasbeeh: session target completed');
    }
    emit(next);
    await _repository.save(next);
  }

  Future<void> selectDhikr(String value) async {
    if (state.isLoading || state.selectedDhikr == value || !state.items.any((item) => item.dhikr == value)) return;
    final next = state.copyWith(selectedDhikr: value);
    emit(next);
    await _repository.save(next);
  }

  Future<void> setTarget(int value) async {
    if (state.isLoading) return;
    final items = state.items
        .map((item) => item.dhikr == state.selectedDhikr ? item.copyWith(target: value.clamp(1, 999999)) : item)
        .toList(growable: false);
    final next = state.copyWith(items: items);
    emit(next);
    await _repository.save(next);
  }

  Future<void> reset() async {
    if (state.isLoading) return;
    final items = state.items
        .map((item) => item.dhikr == state.selectedDhikr ? item.copyWith(count: 0) : item)
        .toList(growable: false);
    final next = state.copyWith(items: items);
    emit(next);
    await _repository.save(next);
  }

  Future<void> resetAll() async {
    if (state.isLoading) return;
    final next = state.copyWith(
      items: state.items
          .map((item) => item.copyWith(count: 0))
          .toList(growable: false),
      dailyTotal: 0,
    );
    emit(next);
    await _repository.save(next);
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _dayRolloverTimer?.cancel();
    return super.close();
  }
}
