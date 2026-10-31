import '../../../../core/network/dio_client.dart';
import '../../domain/entities/hadeeth_entry.dart';

class HadeethRemoteDataSource {
  Future<List<HadeethEntry>> fetch() async {
    final ids = <String>[];
    for (var page = 1; page <= 2; page++) {
      final response = await DioHelper.getHadeeth(endPoint: 'hadeeths/list', query: {
        'language': 'ar', 'category_id': 1, 'page': page,
      });
      ids.addAll((response.data['data'] as List).map((item) => item['id'].toString()));
    }
    return Future.wait(ids.map((id) async {
      final response = await DioHelper.getHadeeth(endPoint: 'hadeeths/one', query: {
        'language': 'ar', 'id': id,
      });
      final data = response.data as Map<String, dynamic>;
      return HadeethEntry(text: data['hadeeth'] as String, explanation: data['explanation'] as String);
    }));
  }
}
