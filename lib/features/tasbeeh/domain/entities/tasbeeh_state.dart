class TasbeehState {
  const TasbeehState({
    this.count = 0,
    this.dhikr = 'سُبْحَانَ اللَّهِ',
    this.target = 33,
    this.dailyTotal = 0,
    this.isLoading = true,
  });

  final int count;
  final String dhikr;
  final int target;
  final int dailyTotal;
  final bool isLoading;

  double get progress => target <= 0 ? 0 : (count / target).clamp(0.0, 1.0);
  bool get isComplete => count >= target;

  TasbeehState copyWith({int? count, String? dhikr, int? target, int? dailyTotal, bool? isLoading}) => TasbeehState(
    count: count ?? this.count,
    dhikr: dhikr ?? this.dhikr,
    target: target ?? this.target,
    dailyTotal: dailyTotal ?? this.dailyTotal,
    isLoading: isLoading ?? this.isLoading,
  );
}
