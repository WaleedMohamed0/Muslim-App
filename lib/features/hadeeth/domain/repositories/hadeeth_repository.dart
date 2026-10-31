import '../entities/hadeeth_entry.dart';

abstract interface class HadeethRepository {
  Future<List<HadeethEntry>> getEntries();
}
