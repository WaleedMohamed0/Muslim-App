import '../entities/azkar_entry.dart';

abstract interface class AzkarRepository {
  List<AzkarEntry> entriesFor(int category);
  List<String> itemsFor(int category);
}
