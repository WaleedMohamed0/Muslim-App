class TasbeehItem {
  const TasbeehItem({required this.dhikr, required this.count, required this.target});

  final String dhikr;
  final int count;
  final int target;

  double get progress => target <= 0 ? 0 : (count / target).clamp(0.0, 1.0);
  bool get isComplete => count >= target;

  TasbeehItem copyWith({int? count, int? target}) => TasbeehItem(
    dhikr: dhikr,
    count: count ?? this.count,
    target: target ?? this.target,
  );
}
