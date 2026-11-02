import '../data_sources/local_azkar_data_source.dart';
import '../../domain/entities/azkar_entry.dart';
import '../../domain/repositories/azkar_repository.dart';

class LocalAzkarRepository implements AzkarRepository {
  const LocalAzkarRepository(this.dataSource);
  final LocalAzkarDataSource dataSource;

  @override
  List<AzkarEntry> entriesFor(int category) {
    final name = switch (category) {
      0 => 'أذكار الصباح',
      1 => 'أذكار المساء',
      2 => 'أذكار النوم',
      3 => 'أذكار الاستيقاظ',
      4 => 'أذكار بعد السلام من الصلاة المفروضة',
      5 => 'تسابيح',
      6 => 'أدعية قرآنية',
      7 => 'أدعية الأنبياء',
      8 => 'أدعية من السنة النبوية',
      9 => 'أدعية للمواقف اليومية',
      _ => null,
    };
    return name == null ? const [] : dataSource.readEntries(name);
  }

  @override
  List<String> itemsFor(int category) =>
      entriesFor(category).map((entry) => entry.content).toList(growable: false);
}
