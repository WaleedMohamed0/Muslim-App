import 'package:flutter/material.dart';
import 'package:muslim/features/app/presentation/pages/startup_screen.dart';

class AppEntryNavigation {
  const AppEntryNavigation._();

  static void openHome(BuildContext context, {WidgetBuilder? homeBuilder}) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder:
            (context) => homeBuilder?.call(context) ?? const StartUpScreen(),
      ),
    );
  }

  static void openDestination(
    BuildContext context, {
    required Widget destination,
    required String? routeName,
  }) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final navigator = Navigator.of(context);
    if (routeName?.startsWith('/quran-reader/') == true) {
      navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: (_) => destination,
        ),
        (_) => false,
      );
      return;
    }
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => destination,
      ),
      (_) => false,
    );
  }
}
