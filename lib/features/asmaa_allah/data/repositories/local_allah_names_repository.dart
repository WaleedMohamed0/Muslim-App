import '../data_sources/local_allah_names_data_source.dart';
import '../../domain/entities/allah_name.dart';
import '../../domain/repositories/allah_names_repository.dart';

class LocalAllahNamesRepository implements AllahNamesRepository {
  const LocalAllahNamesRepository(this.dataSource);
  final LocalAllahNamesDataSource dataSource;

  @override
  List<AllahName> getNames() => dataSource.read();
}
