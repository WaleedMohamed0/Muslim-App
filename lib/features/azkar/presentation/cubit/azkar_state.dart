import '../../domain/entities/azkar_entry.dart';

class AzkarState {
  const AzkarState({
    this.counters = const [],
    this.entriesByCategory = const {},
    this.revision = 0,
    this.isLoading = false,
    this.error,
  });

  final List<int> counters;
  final Map<int, List<AzkarEntry>> entriesByCategory;
  final int revision;
  final bool isLoading;
  final String? error;

  List<AzkarEntry> entriesFor(int category) =>
      entriesByCategory[category] ?? const [];
}
