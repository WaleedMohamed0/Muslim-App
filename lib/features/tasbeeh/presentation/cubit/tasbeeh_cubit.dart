import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/error_reporting/diagnostic_context.dart';
import 'package:muslim/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_state.dart';

class TasbeehCubit extends Cubit<TasbeehState> {
  TasbeehCubit(this._repository) : super(const TasbeehState());
  final TasbeehRepository _repository;

  Future<void> load() async {
    try {
      emit(await _repository.load());
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
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
}
