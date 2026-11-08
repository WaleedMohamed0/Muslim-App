import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_sources/local_azkar_data_source.dart';
import '../../domain/entities/azkar_entry.dart';
import '../../data/repositories/local_azkar_repository.dart';
import '../../domain/use_cases/get_azkar.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'azkar_state.dart';
import '../../../../core/assets/app_assets.dart';

class AzkarCubit extends Cubit<AzkarState> with WidgetsBindingObserver {
  AzkarCubit({GetAzkar? getAzkar, LocalAzkarDataSource? dataSource})
    : _getAzkar = getAzkar,
      _dataSource = dataSource,
      super(const AzkarState()) {
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayRollover();
  }

  final GetAzkar? _getAzkar;
  final LocalAzkarDataSource? _dataSource;

  List<int> azkarTimes = [];
  final Map<String, int> _progress = {};
  final Set<String> _favoriteEntryIds = {};
  Map<int, List<AzkarEntry>> _entriesByCategory = const {};
  LocalAzkarDataSource? _content;
  LocalAzkarRepository? _repository;
  Future<void>? _loadFuture;
  Future<void>? _dateSync;
  Timer? _dayRolloverTimer;
  String? _activeLocalDate;
  static const _progressDateKey = 'azkar_progress_local_date';
  static const _progressKeyPrefix = 'azkar_progress_';
  static const _favoriteEntryIdsKey = 'azkar_favorite_entry_ids';
  static const MethodChannel _shareChannel = MethodChannel('com.muslim/quran_share');
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
        favoriteEntryIds: Set.unmodifiable(_favoriteEntryIds),
        revision: state.revision + 1,
        isLoading: true,
      ),
    );
    try {
      if (_dataSource == null) {
        final data = await rootBundle.loadString(AppAssets.azkarData);
        final categories = jsonDecode(data) as Map<String, dynamic>;
        _content = LocalAzkarDataSource(categories);
      } else {
        _content = _dataSource;
      }
      _repository = LocalAzkarRepository(_content!);
      _entriesByCategory = Map.unmodifiable({
        for (var category = 0; category < 10; category++)
          category: List<AzkarEntry>.unmodifiable(
            _repository!.entriesFor(category),
          ),
      });
      // Initialize Tasbeeh counters as part of loading so the page never builds
      // against loaded content with an uninitialized counter list.
      final prefs = await SharedPreferences.getInstance();
      await _ensureCurrentLocalDate(prefs: prefs);
      for (final entry in _content!.allEntries) {
        _progress[entry.id] = prefs.getInt(_progressKey(entry.id)) ?? 0;
      }
      _favoriteEntryIds
        ..clear()
        ..addAll(prefs.getStringList(_favoriteEntryIdsKey) ?? const []);
      azkarTimes = entriesFor(5).map(progressFor).toList(growable: false);
      emit(
        AzkarState(
          counters: List.unmodifiable(azkarTimes),
          entriesByCategory: _entriesByCategory,
          favoriteEntryIds: Set.unmodifiable(_favoriteEntryIds),
          revision: state.revision + 1,
        ),
      );
    } catch (_) {
      emit(
        AzkarState(
          counters: List.unmodifiable(azkarTimes),
          entriesByCategory: _entriesByCategory,
          favoriteEntryIds: Set.unmodifiable(_favoriteEntryIds),
          revision: state.revision + 1,
          error: 'تعذر تحميل الْأَذْكَار',
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
      'أذكار الاستيقاظ',
      'أذكار بعد السلام من الصَّلَاة المفروضة',
      'تسابيح',
      'أدعية قرآنية',
      'أدعية الْأَنْبِيَاء',
      'أدعية من السُّنَّة النبوية',
      'أدعية للمواقف اليومية',
    ];
    if (category < 0 || category >= names.length) return const [];
    return _repository?.itemsFor(category) ??
        _content?.readCategory(names[category]) ??
        _getAzkar?.call(category) ??
        const [];
  }

  List<AzkarEntry> entriesFor(int category) {
    const names = [
      'أذكار الصباح',
      'أذكار المساء',
      'أذكار النوم',
      'أذكار الاستيقاظ',
      'أذكار بعد السلام من الصَّلَاة المفروضة',
      'تسابيح',
      'أدعية قرآنية',
      'أدعية الْأَنْبِيَاء',
      'أدعية من السُّنَّة النبوية',
      'أدعية للمواقف اليومية',
    ];
    if (category < 0 || category >= names.length) return const [];
    final repository = _repository;
    if (repository != null) return repository.entriesFor(category);
    final source = _content;
    if (source != null) return source.readEntries(names[category]);
    if (_getAzkar != null) return _getAzkar.entriesFor(category);
    return itemsFor(category)
        .map((content) => AzkarEntry(
              category: names[category],
              countText: '',
              countStatus: null,
              description: '',
              reference: '',
              instructions: '',
              verified: false,
              content: content,
            ))
        .toList(growable: false);
  }

  int progressFor(AzkarEntry entry) {
    if (_activeLocalDate != _localDateKey()) {
      unawaited(_ensureCurrentLocalDate().catchError((Object _) {}));
      return 0;
    }
    return _progress[entry.id] ?? 0;
  }

  bool isFavorite(AzkarEntry entry) => _favoriteEntryIds.contains(entry.id);

  Future<void> toggleFavorite(AzkarEntry entry) async {
    if (isClosed) return;
    if (!_favoriteEntryIds.add(entry.id)) _favoriteEntryIds.remove(entry.id);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _favoriteEntryIdsKey,
      _favoriteEntryIds.toList(growable: false),
    );
    if (!isClosed) _emitProgress();
  }

  Future<void> shareEntry(AzkarEntry entry) => _shareChannel.invokeMethod<void>(
        'shareText',
        {
          'text': [entry.content, if (entry.reference.isNotEmpty) entry.reference]
              .join('\n\n'),
          'title': entry.subCategory.isEmpty ? 'مشاركة ذكر' : entry.subCategory,
        },
      );

  Future<void> incrementEntry(AzkarEntry entry) async {
    if (isClosed) return;
    await _ensureCurrentLocalDate();
    if (isClosed) return;
    _progress[entry.id] = progressFor(entry) + 1;
    final tasbeehIndex = entry.category == 'تسابيح'
        ? entriesFor(5).indexWhere((item) => item.id == entry.id)
        : -1;
    if (tasbeehIndex >= 0 && tasbeehIndex < azkarTimes.length) {
      azkarTimes[tasbeehIndex] = _progress[entry.id]!;
    }
    _emitProgress();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey(entry.id), _progress[entry.id]!);
  }

  Future<void> resetEntry(AzkarEntry entry) async {
    if (isClosed) return;
    await _ensureCurrentLocalDate();
    if (isClosed) return;
    _progress[entry.id] = 0;
    final tasbeehIndex = entry.category == 'تسابيح'
        ? entriesFor(5).indexWhere((item) => item.id == entry.id)
        : -1;
    if (tasbeehIndex >= 0 && tasbeehIndex < azkarTimes.length) {
      azkarTimes[tasbeehIndex] = 0;
    }
    _emitProgress();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey(entry.id));
  }

  String _progressKey(String id) => '$_progressKeyPrefix$id';

  String _localDateKey([DateTime? date]) {
    final localDate = date ?? DateTime.now();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}-$month-$day';
  }

  Future<void> _ensureCurrentLocalDate({SharedPreferences? prefs}) {
    final today = _localDateKey();
    if (_activeLocalDate == today) return Future.value();
    final pendingSync = _dateSync;
    if (pendingSync != null) return pendingSync;

    final sync = _synchronizeLocalDate(today, prefs: prefs);
    _dateSync = sync;
    return sync.whenComplete(() => _dateSync = null);
  }

  Future<void> _synchronizeLocalDate(
    String today, {
    SharedPreferences? prefs,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final savedDate = preferences.getString(_progressDateKey);

    if (savedDate != null && savedDate != today) {
      final oldProgressKeys = preferences
          .getKeys()
          .where(
            (key) =>
                key.startsWith(_progressKeyPrefix) &&
                key != _progressDateKey,
          )
          .toList(growable: false);
      for (final key in oldProgressKeys) {
        await preferences.remove(key);
      }
      _progress.clear();
      if (_content != null) {
        azkarTimes = List.filled(entriesFor(5).length, 0);
        _emitProgress();
      }
    }

    if (savedDate != today) {
      await preferences.setString(_progressDateKey, today);
    }
    _activeLocalDate = today;
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final nextLocalMidnight = DateTime(now.year, now.month, now.day + 1);
    _dayRolloverTimer = Timer(
      nextLocalMidnight.difference(now),
      () {
        unawaited(
          _ensureCurrentLocalDate()
              .catchError((Object _) {})
              .whenComplete(_scheduleDayRollover),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduleDayRollover();
    unawaited(_ensureCurrentLocalDate().catchError((Object _) {}));
  }

  void _emitProgress() => emit(
        AzkarState(
          counters: List.unmodifiable(azkarTimes),
          entriesByCategory: _entriesByCategory,
          favoriteEntryIds: Set.unmodifiable(_favoriteEntryIds),
          revision: state.revision + 1,
        ),
      );

  void initializeCounters(int count) {
    if (isClosed) return;
    if (azkarTimes.length == count) return;
    azkarTimes = List.filled(count, 0);
    emit(
      AzkarState(
        counters: List.unmodifiable(azkarTimes),
        entriesByCategory: _entriesByCategory,
        favoriteEntryIds: Set.unmodifiable(_favoriteEntryIds),
        revision: state.revision + 1,
      ),
    );
  }

  void incrementAzkarTimes(int index) {
    if (isClosed || index < 0 || index >= azkarTimes.length) return;
    unawaited(incrementEntry(entriesFor(5)[index]));
  }

  void clearTimes(int index) {
    if (isClosed || index < 0 || index >= azkarTimes.length) return;
    unawaited(resetEntry(entriesFor(5)[index]));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _dayRolloverTimer?.cancel();
    return super.close();
  }
}
