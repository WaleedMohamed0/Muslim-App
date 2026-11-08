import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_state.dart';

class TasbeehCubit extends Cubit<TasbeehState> {
  TasbeehCubit(this._repository) : super(const TasbeehState());
  final TasbeehRepository _repository;

  Future<void> load() async {
    try { emit(await _repository.load()); } catch (_) { emit(state.copyWith(isLoading: false)); }
  }

  Future<void> increment() async {
    if (state.isLoading) return;
    final stored = await _repository.load();
    final dailyTotal = stored.dailyTotal + 1;
    final next = state.copyWith(count: state.count + 1, dailyTotal: dailyTotal);
    emit(next);
    await _repository.save(next);
  }

  Future<void> selectDhikr(String value) async {
    if (state.isLoading || state.dhikr == value) return;
    // Save the current dhikr before switching, then load its own saved count.
    await _repository.save(state);
    final saved = await _repository.loadCountForDhikr(value);
    final next = state.copyWith(dhikr: value, count: saved);
    emit(next);
    await _repository.save(next);
  }

  Future<void> setTarget(int value) async {
    final next = state.copyWith(target: value.clamp(1, 999999));
    emit(next);
    await _repository.save(next);
  }

  Future<void> reset() async {
    final next = state.copyWith(count: 0);
    emit(next);
    await _repository.save(next);
  }
}
