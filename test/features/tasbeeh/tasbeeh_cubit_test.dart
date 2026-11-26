import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:muslim/features/tasbeeh/presentation/cubit/tasbeeh_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasbeehCubit', () {
    late TasbeehCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cubit = TasbeehCubit(TasbeehRepository());
      await cubit.load();
    });

    tearDown(() => cubit.close());

    test('keeps counts and targets independent when switching dhikr', () async {
      final first = TasbeehRepository.dhikrs[0];
      final second = TasbeehRepository.dhikrs[1];

      await cubit.setTarget(100);
      await cubit.increment();
      await cubit.selectDhikr(second);
      expect(cubit.state.count, 0);
      expect(cubit.state.target, 33);

      await cubit.increment();
      await cubit.increment();
      await cubit.selectDhikr(first);
      expect(cubit.state.count, 1);
      expect(cubit.state.target, 100);
      await cubit.selectDhikr(second);
      expect(cubit.state.count, 2);
      expect(cubit.state.target, 33);
    });

    test('migrates the legacy shared counter and target to the selected dhikr', () async {
      await cubit.close();
      SharedPreferences.setMockInitialValues({
        'electronic_tasbeeh_count': 12,
        'electronic_tasbeeh_target': 100,
        'electronic_tasbeeh_dhikr': 'الْحَمْدُ لِلَّهِ',
      });
      cubit = TasbeehCubit(TasbeehRepository());
      await cubit.load();

      expect(cubit.state.count, 12);
      expect(cubit.state.target, 100);
      await cubit.selectDhikr(TasbeehRepository.dhikrs.first);
      expect(cubit.state.count, 0);
      expect(cubit.state.target, 33);
    });

  });
}
