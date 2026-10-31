import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../data/repositories/local_allah_names_repository.dart';
import '../../data/data_sources/local_allah_names_data_source.dart';
import 'allah_names_state.dart';
import '../../domain/repositories/allah_names_repository.dart';
import '../../../../core/assets/app_assets.dart';

class AllahNamesCubit extends Cubit<AllahNamesState> {
  AllahNamesCubit({AllahNamesRepository? repository, LocalAllahNamesDataSource? dataSource})
      : _injectedRepository = repository ?? (dataSource == null ? null : LocalAllahNamesRepository(dataSource)),
        super(const AllahNamesState());
  final AllahNamesRepository? _injectedRepository;
  Future<void> load() async {
    emit(AllahNamesState(names: state.names, isLoading: true));
    try {
      final repository = _injectedRepository ?? LocalAllahNamesRepository(
        LocalAllahNamesDataSource(jsonDecode(await rootBundle.loadString(AppAssets.allahNamesData))),
      );
      emit(AllahNamesState(names: repository.getNames()));
    } catch (error) {
      emit(AllahNamesState(names: state.names, error: error.toString()));
    }
  }
}
