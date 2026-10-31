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
  Future<void>? _loadFuture;
  bool isOnline = false;
  void setConnectivity(bool connected) => isOnline = connected;

  Future<void> loadContent() {
    if (_content != null) return Future.value();
    if (_loadFuture != null) return _loadFuture!;
    return _loadFuture = _loadContent();
  }

  Future<void> _loadContent() async {
    emit(
      AzkarState(
        counters: List.unmodifiable(azkarTimes),
        revision: state.revision + 1,
        isLoading: true,
      ),
    );
    try {
      if (_dataSource == null) {
        final data = await rootBundle.loadString(AppAssets.azkarData);
        _content = LocalAzkarDataSource(
          jsonDecode(data) as Map<String, dynamic>,
        );
      } else {
        _content = _dataSource;
      }
      // Initialize Tasbeeh counters as part of loading so the page never builds
      // against loaded content with an uninitialized counter list.
      azkarTimes = List<int>.filled(itemsFor(3).length, 0);
      emit(
        AzkarState(
          counters: List.unmodifiable(azkarTimes),
          revision: state.revision + 1,
        ),
      );
    } catch (_) {
      emit(
        AzkarState(
          counters: List.unmodifiable(azkarTimes),
          revision: state.revision + 1,
          error: 'تعذر تحميل الأذكار',
        ),
      );
    } finally {
      _loadFuture = null;
    }
  }

  List<String> itemsFor(int category) {
    const names = [
      'أذكار الصباح',
      'أذكار المساء',
      'أذكار النوم',
      'تسابيح',
      'أدعية قرآنية',
    ];
    if (category < 0 || category >= names.length) return const [];
    return _content?.readCategory(names[category]) ??
        _getAzkar?.call(category) ??
        const [];
  }

  void initializeCounters(int count) {
    if (isClosed) return;
    if (azkarTimes.length == count) return;
    azkarTimes = List.filled(count, 0);
    emit(
      AzkarState(
        counters: List.unmodifiable(azkarTimes),
        revision: state.revision + 1,
      ),
    );
  }

  void incrementAzkarTimes(int index) {
    if (isClosed || index < 0 || index >= azkarTimes.length) return;
    azkarTimes[index]++;
    emit(
      AzkarState(
        counters: List.unmodifiable(azkarTimes),
        revision: state.revision + 1,
      ),
    );
  }

  void clearTimes(int index) {
    if (isClosed || index < 0 || index >= azkarTimes.length) return;
    azkarTimes[index] = 0;
    emit(
      AzkarState(
        counters: List.unmodifiable(azkarTimes),
        revision: state.revision + 1,
      ),
    );
  }
}
