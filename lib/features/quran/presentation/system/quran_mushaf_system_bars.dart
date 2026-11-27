import 'package:material_ui/material_ui.dart';

abstract final class QuranMushafSystemBars {
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  static final ValueNotifier<({PageRoute<dynamic> route, int color})?>
      activeBackground = ValueNotifier(null);
}
