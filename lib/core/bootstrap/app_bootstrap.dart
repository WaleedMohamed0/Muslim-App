import '../network/dio_client.dart';
import '../storage/cache_helper.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    await DioHelper.init();
    await DioHelper.initHadeeth();
    await CacheHelper.init();
  }
}
