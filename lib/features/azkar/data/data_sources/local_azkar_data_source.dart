import '../../domain/entities/azkar_entry.dart';

class LocalAzkarDataSource {
  LocalAzkarDataSource(this._categories);
  final Map<String, dynamic> _categories;
  final Map<String, List<AzkarEntry>> _entryCache = {};

  List<AzkarEntry> readEntries(String name) => _entryCache.putIfAbsent(
        name,
        () => ((_categories[name] ?? []) as List)
            .map((item) => AzkarEntry.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  List<AzkarEntry> get allEntries => _categories.keys
      .expand(readEntries)
      .toList(growable: false);

  List<String> readCategory(String name) =>
      readEntries(name).map((entry) => entry.content).toList(growable: false);
}
