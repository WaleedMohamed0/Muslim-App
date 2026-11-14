import 'package:dio/dio.dart';

class DioHelper {
  static Dio? dioHadeeth;

  static void initHadeeth() {
    dioHadeeth = Dio(
      BaseOptions(
        baseUrl: 'https://hadeethenc.com/api/v1/',
        headers: {'Content-Type': 'application/json'},
        receiveDataWhenStatusError: true,
      ),
    );
  }

  static Future<Response> getHadeeth({
    required String endPoint,
    Map<String, dynamic>? query,
    String? lang = 'en',
  }) async {
    dioHadeeth!.options.headers = {'lang': lang};
    return await dioHadeeth!.get(endPoint, queryParameters: query);
  }
}
