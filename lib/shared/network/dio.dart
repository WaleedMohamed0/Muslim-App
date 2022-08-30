import 'package:dio/dio.dart';

class DioHelper {
  static Dio? dioAdhan;
  static Dio? dioSound;

  static init() {
    dioAdhan = Dio(BaseOptions(
      baseUrl: 'http://api.aladhan.com/v1/',
      headers: {
        'Content-Type': 'application/json',
      },
      receiveDataWhenStatusError: true,
    ));
  }
  static initSound() {
    dioSound = Dio(BaseOptions(
      baseUrl: 'http://api.alquran.cloud/v1/surah/',
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
    String? token,
  }) async {
    dioAdhan!.options.headers=
    {
      'lang' : lang,
      'Authorization':token,
    };
    return await dioAdhan!.get(endPoint, queryParameters: query);
  }

  static Future<Response> getDataSound({
    required String endPoint,
    Map<String, dynamic>? query,
    String? lang='en',
    String? token,
  }) async {
    dioSound!.options.headers=
    {
      'lang' : lang,
      'Authorization':token,
    };
    return await dioSound!.get(endPoint, queryParameters: query);
  }




  // static Future<Response> postData({
  //   required String url,
  //   Map<String, dynamic>? query,
  //   required Map<String, dynamic> data,
  //   String? lang='en',
  //   String? token,
  // }) async {
  //   dio!.options.headers=
  //   {
  //     'lang' : lang,
  //     'Authorization':token,
  //   };
  //   return await dio!.post(url, queryParameters: query, data: data);
  // }
  //
  //
  // static Future<Response> putData({
  //   required String url,
  //   Map<String, dynamic>? query,
  //   required Map<String, dynamic> data,
  //   String? lang='en',
  //   String? token,
  // }) async {
  //   dio!.options.headers=
  //   {
  //     'lang' : lang,
  //     'Authorization':token,
  //   };
  //   return await dio!.put(url, queryParameters: query, data: data);
  // }
}
