import '../repositories/azkar_repository.dart';

class GetAzkar {
  const GetAzkar(this.repository);
  final AzkarRepository repository;
  List<String> call(int category) => repository.itemsFor(category);
}
