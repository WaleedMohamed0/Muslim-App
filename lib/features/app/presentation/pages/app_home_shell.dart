import 'package:material_ui/material_ui.dart';
import 'package:muslim/features/app/presentation/pages/more_screen.dart';
import 'package:muslim/features/app/presentation/widgets/app_bottom_navigation_bar.dart';
import 'package:muslim/features/app/presentation/widgets/app_bottom_navigation_scope.dart';
import 'package:muslim/features/app/presentation/pages/startup_screen.dart';
import 'package:muslim/features/azkar/presentation/pages/azkar_overview_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:muslim/features/quran/presentation/pages/home_screen.dart';

class AppHomeShell extends StatefulWidget {
  const AppHomeShell({super.key, this.initialSelectedIndex = 0});

  final int initialSelectedIndex;

  static final GlobalKey<AppHomeShellState> navigationKey =
      GlobalKey<AppHomeShellState>();

  static bool selectTab(int index) =>
      navigationKey.currentState?._selectTab(index) ?? false;

  @override
  State<AppHomeShell> createState() => AppHomeShellState();
}

class AppHomeShellState extends State<AppHomeShell> {
  late int _selectedIndex = widget.initialSelectedIndex.clamp(0, 4);

  bool _selectTab(int index) {
    if (index < 0 || index >= 5 || !mounted) return false;
    setState(() => _selectedIndex = index);
    return true;
  }
  late final List<Widget> _pages = [
    const StartUpScreen(),
    const HomeScreen(),
    const AzkarOverviewScreen(),
    const PrayerTimes(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _selectedIndex == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _selectedIndex != 0) setState(() => _selectedIndex = 0);
    },
    child: Scaffold(
      body: AppBottomNavigationScope(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      ),
    ),
  );
}
