import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/data_sources/hadeeth_remote_data_source.dart';
import '../../data/repositories/hadeeth_repository_impl.dart';
import 'hadeeth_state.dart';
import '../../domain/use_cases/get_hadeeth.dart';


class HadeethCubit extends Cubit<HadeethState> {
  HadeethCubit({GetHadeeth? getHadeeth})
      : _getHadeeth = getHadeeth ?? GetHadeeth(HadeethRepositoryImpl(HadeethRemoteDataSource())),
        super(const HadeethState());

  final GetHadeeth _getHadeeth;

  bool gotHadeeths = false;

  Future<void> getHadeeth() async {
    if (gotHadeeths) return;
    try {
      emit(const HadeethState(isLoading: true));
      final entries = await _getHadeeth();
      gotHadeeths = true;
      emit(HadeethState(entries: entries));
    } catch (error) {
      emit(HadeethState(error: error.toString()));
    }
  }
}
