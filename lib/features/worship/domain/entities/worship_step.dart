class WorshipStep {
  const WorshipStep({
    required this.title,
    required this.description,
    this.recitation,
    this.note,
  });

  final String title;
  final String description;
  final String? recitation;
  final String? note;
}
