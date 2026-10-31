import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/data_sources/local_azkar_data_source.dart';
import '../../domain/use_cases/get_azkar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'azkar_state.dart';
import '../../../../core/assets/app_assets.dart';

class AzkarCubit extends Cubit<AzkarState> {
  AzkarCubit({GetAzkar? getAzkar, LocalAzkarDataSource? dataSource})
      : _getAzkar = getAzkar,
        _dataSource = dataSource,
        super(const AzkarState());

  final GetAzkar? _getAzkar;
  final LocalAzkarDataSource? _dataSource;

  List<int> azkarTimes = [];
  LocalAzkarDataSource? _content;
  bool isOnline = false;
  void setConnectivity(bool connected) => isOnline = connected;

  Future<void> loadContent() async {
    final data = await rootBundle.loadString(AppAssets.azkarData);
    _content = _dataSource ?? LocalAzkarDataSource(jsonDecode(data) as Map<String, dynamic>);
    emit(AzkarState(counters: List.unmodifiable(azkarTimes), revision: state.revision + 1));
  }

  List<String> itemsFor(int category) {
    const names = ['أذكار الصباح', 'أذكار المساء', 'أذكار النوم', 'تسابيح', 'أدعية قرآنية'];
    if (category < 0 || category >= names.length) return const [];
    return _content?.readCategory(names[category]) ?? _getAzkar?.call(category) ?? const [];
  }

  void initializeCounters(int count) {
    azkarTimes = List.filled(count, 0);
    emit(AzkarState(counters: List.unmodifiable(azkarTimes), revision: state.revision + 1));
  }

  void incrementAzkarTimes(int index) {
    azkarTimes[index]++;
    emit(AzkarState(counters: List.unmodifiable(azkarTimes), revision: state.revision + 1));
  }

  void clearTimes(int index) {
    azkarTimes[index] = 0;
    emit(AzkarState(counters: List.unmodifiable(azkarTimes), revision: state.revision + 1));
  }
}
