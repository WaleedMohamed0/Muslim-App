import '../data_sources/local_azkar_data_source.dart';
import '../../domain/repositories/azkar_repository.dart';

class LocalAzkarRepository implements AzkarRepository {
  const LocalAzkarRepository(this.dataSource);
  final LocalAzkarDataSource dataSource;

  @override
  List<String> itemsFor(int category) => switch (category) {
    0 => dataSource.readCategory('أذكار الصباح'),
    1 => dataSource.readCategory('أذكار المساء'),
    2 => dataSource.readCategory('أذكار النوم'),
    3 => dataSource.readCategory('تسابيح'),
    4 => dataSource.readCategory('أدعية قرآنية'),
    _ => const [],
  };
}
