import 'package:material_ui/material_ui.dart';
import 'package:muslim/features/app/presentation/pages/app_home_shell.dart';

class AppEntryNavigation {
  const AppEntryNavigation._();

  static void openHome(BuildContext context, {WidgetBuilder? homeBuilder}) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder:
            (context) =>
                homeBuilder?.call(context) ??
                AppHomeShell(key: AppHomeShell.navigationKey),
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
    if (routeName == '/daily-wird') {
      navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/home'),
          builder: (_) => AppHomeShell(key: AppHomeShell.navigationKey),
        ),
        (_) => false,
      );
      navigator.push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: (_) => destination,
        ),
      );
      return;
    }
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
