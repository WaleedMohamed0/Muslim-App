import 'package:dio/dio.dart';

class DioHelper {
  static Dio? dioAdhan;
  static Dio? dioHadeeth;

  static init() {
    dioAdhan = Dio(BaseOptions(
      baseUrl: 'http://api.aladhan.com/v1/',
      headers: {
        'Content-Type': 'application/json',
      },
      receiveDataWhenStatusError: true,
    ));
  }

  static initHadeeth() {
    dioHadeeth = Dio(BaseOptions(
      baseUrl: 'https://hadeethenc.com/api/v1/',
      headers: {
        'Content-Type': 'application/json',
      },
      receiveDataWhenStatusError: true,
    ));
  }

  static Future<Response> getData({
    required String endPoint,
    Map<String, dynamic>? query,
    String? lang='en',
  }) async {
    dioAdhan!.options.headers=
    {
      'lang' : lang,
    };
    return await dioAdhan!.get(endPoint, queryParameters: query);
  }
  static Future<Response> getHadeeth({
    required String endPoint,
    Map<String, dynamic>? query,
    String? lang='en',
  }) async {
    dioHadeeth!.options.headers=
    {
      'lang' : lang,
    };
    return await dioHadeeth!.get(endPoint, queryParameters: query);
  }
}
