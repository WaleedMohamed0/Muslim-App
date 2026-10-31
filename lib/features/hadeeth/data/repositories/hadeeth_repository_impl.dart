import '../../domain/entities/hadeeth_entry.dart';
import '../../domain/repositories/hadeeth_repository.dart';
import '../data_sources/hadeeth_remote_data_source.dart';

class HadeethRepositoryImpl implements HadeethRepository {
  const HadeethRepositoryImpl(this.dataSource);
  final HadeethRemoteDataSource dataSource;
  @override
  Future<List<HadeethEntry>> getEntries() => dataSource.fetch();
}
