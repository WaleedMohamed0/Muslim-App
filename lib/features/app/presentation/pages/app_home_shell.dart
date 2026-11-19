import 'package:material_ui/material_ui.dart';
import 'package:muslim/features/app/presentation/pages/more_screen.dart';
import 'package:muslim/features/app/presentation/widgets/app_bottom_navigation_bar.dart';
import 'package:muslim/features/app/presentation/pages/startup_screen.dart';
import 'package:muslim/features/azkar/presentation/pages/azkar_overview_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:muslim/features/quran/presentation/pages/home_screen.dart';

class AppHomeShell extends StatefulWidget {
  const AppHomeShell({super.key});

  @override
  State<AppHomeShell> createState() => _AppHomeShellState();
}

class _AppHomeShellState extends State<AppHomeShell> {
  int _selectedIndex = 0;
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
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      ),
    ),
  );
}
