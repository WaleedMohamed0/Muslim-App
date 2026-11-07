enum MushafMarkingCategory {
  waqf('علامات الوقف'),
  recitation('علامات التلاوة'),
  notation('علامات الضبط والرسم');

  const MushafMarkingCategory(this.label);
  final String label;
}

class MushafMarking {
  const MushafMarking({
    required this.symbol,
    required this.name,
    required this.meaning,
    required this.category,
    this.example,
    this.reference,
  });

  final String symbol;
  final String name;
  final String meaning;
  final MushafMarkingCategory category;
  final String? example;
  final String? reference;
}
