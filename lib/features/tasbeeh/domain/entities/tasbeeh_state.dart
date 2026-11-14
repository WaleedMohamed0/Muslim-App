import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_item.dart';

class TasbeehState {
  const TasbeehState({
    this.items = const [],
    this.selectedDhikr = 'سُبْحَانَ اللَّهِ',
    this.dailyTotal = 0,
    this.isLoading = true,
  });

  final List<TasbeehItem> items;
  final String selectedDhikr;
  final int dailyTotal;
  final bool isLoading;

  TasbeehItem get selectedItem => items.firstWhere(
    (item) => item.dhikr == selectedDhikr,
    orElse: () => const TasbeehItem(dhikr: 'سُبْحَانَ اللَّهِ', count: 0, target: 33),
  );

  int get count => selectedItem.count;
  int get target => selectedItem.target;
  String get dhikr => selectedDhikr;
  double get progress => selectedItem.progress;
  bool get isComplete => selectedItem.isComplete;

  TasbeehState copyWith({List<TasbeehItem>? items, String? selectedDhikr, int? dailyTotal, bool? isLoading}) => TasbeehState(
    items: items ?? this.items,
    selectedDhikr: selectedDhikr ?? this.selectedDhikr,
    dailyTotal: dailyTotal ?? this.dailyTotal,
    isLoading: isLoading ?? this.isLoading,
  );
}
