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
      openFromRootNavigator(
        navigator,
        destination: destination,
        routeName: routeName!,
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

  /// Opens an external destination above the app shell, creating the shell
  /// only when this is a cold start without one already in the route stack.
  static void openFromRootNavigator(
    NavigatorState navigator, {
    required Widget destination,
    required String routeName,
  }) {
    // The shell key identifies an existing shell and preserves its tab state.
    if (AppHomeShell.navigationKey.currentState != null) {
      navigator.popUntil((route) => route.settings.name == '/home');
    } else {
      navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/home'),
          builder: (_) => AppHomeShell(key: AppHomeShell.navigationKey),
        ),
        (_) => false,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      navigator.push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: (_) => destination,
        ),
      );
    });
  }
}
