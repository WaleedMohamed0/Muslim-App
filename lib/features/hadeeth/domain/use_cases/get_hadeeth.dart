import '../entities/hadeeth_entry.dart';
import '../repositories/hadeeth_repository.dart';

class GetHadeeth {
  const GetHadeeth(this.repository);
  final HadeethRepository repository;
  Future<List<HadeethEntry>> call() => repository.getEntries();
}
