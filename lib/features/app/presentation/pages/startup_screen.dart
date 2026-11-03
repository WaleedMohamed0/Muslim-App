import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled8/core/theme/app_colors.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/app/presentation/cubit/app_cubit.dart';
import 'package:untitled8/features/app/presentation/cubit/app_state.dart';
import 'package:untitled8/features/asmaa_allah/presentation/pages/asmaa_allah_screen.dart';
import 'package:untitled8/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:untitled8/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:untitled8/features/prayer_times/presentation/pages/elazan_screen.dart';
import 'package:untitled8/features/prayer_times/presentation/widgets/prayer_experience_card.dart';
import 'package:untitled8/features/qibla/presentation/pages/qibla_compass_screen.dart';
import 'package:untitled8/features/quran/presentation/pages/home_screen.dart';
import 'package:untitled8/features/app/presentation/widgets/startup_home_widgets.dart';
import 'package:untitled8/features/app/presentation/pages/daily_reminder_settings_screen.dart';
import 'package:untitled8/core/assets/app_assets.dart';
import 'package:untitled8/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:untitled8/features/stories/presentation/pages/story_collection_screen.dart';

class StartUpScreen extends StatefulWidget {
  const StartUpScreen({super.key});

  @override
  State<StartUpScreen> createState() => _StartUpScreenState();
}

class _StartUpScreenState extends State<StartUpScreen> {
  static const _notificationDecisionKey = 'first_launch_notifications_decided';
  static const _locationDecisionKey = 'first_launch_location_decided';
  // Keep category indices tied to their existing routes/data while putting
  // the most frequently used Azkar shortcuts first in the carousel.
  static const _azkarDisplayOrder = [0, 1, 5, 2, 3, 4, 6, 7, 8, 9, 10];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestFirstLaunchPermissions());
    });
  }

  Future<void> _requestFirstLaunchPermissions() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final adhan = PrayerAdhanService.instance;
      final permissionStatus = await adhan.permissionStatus();

      if (preferences.getBool(_notificationDecisionKey) != true) {
        if (permissionStatus['notifications'] != true) {
          final accepted = await _explainPermission(
            'السماح بالإشعارات',
            'نستخدم الإشعارات لعرض تنبيهات الصلاة والأذان في أوقاتها.',
          );
          await preferences.setBool(_notificationDecisionKey, true);
          if (accepted) await adhan.requestNotificationPermission();
        } else {
          await preferences.setBool(_notificationDecisionKey, true);
        }
      }

      if (!mounted || preferences.getBool(_locationDecisionKey) == true) return;
      final locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.deniedForever ||
          locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always) {
        await preferences.setBool(_locationDecisionKey, true);
        return;
      }
      final accepted = await _explainPermission(
        'السماح بالوصول إلى الموقع',
        'نحتاج إلى موقعك لحساب مواقيت الصلاة المناسبة لمكانك. يمكنك المتابعة وتفعيل الإذن لاحقًا من صلاحيات الجهاز.',
      );
      await preferences.setBool(_locationDecisionKey, true);
      if (accepted && mounted) await Geolocator.requestPermission();
    } catch (_) {
      // Permission setup is optional; the user can grant access in settings.
    }
  }

  Future<bool> _explainPermission(String title, String description) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title, textDirection: TextDirection.rtl),
          content: Text(
            description,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.start,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ليس الآن'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('متابعة'),
            ),
          ],
        ),
      ) ??
      false;

  void _openPrayerTimes() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/prayer-times'),
        builder: (_) => const PrayerTimes(),
      ),
    );
  }

  void _openElAzan(String prayerId) {
    final prayerName = switch (prayerId) {
      'fajr' => 'الفجر',
      'dhuhr' => 'الظهر',
      'asr' => 'العصر',
      'maghrib' => 'المغرب',
      'isha' => 'العشاء',
      _ => null,
    };
    if (prayerName == null) return;
    final routeName = '/elazan-screen/$prayerId';
    final navigator = Navigator.of(context);
    var screenIsOpen = false;
    navigator.popUntil((route) {
      if (route.settings.name == routeName) {
        screenIsOpen = true;
        return true;
      }
      return route.isFirst;
    });
    if (!screenIsOpen) {
      navigator.push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: routeName),
          builder: (_) => ElAzanScreen(prayer: prayerName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Image.asset(
                        AppAssets.quranLogo,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'مُسْلِم',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<AppCubit, AppState>(
                      builder:
                          (context, state) => IconButton.filledTonal(
                            tooltip:
                                state.themeMode == ThemeMode.dark
                                    ? 'الوضع النهاري'
                                    : 'الوضع الليلي',
                            onPressed: context.read<AppCubit>().toggleThemeMode,
                            icon: Icon(
                              state.themeMode == ThemeMode.dark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 14),
              sliver: SliverToBoxAdapter(
                child: WelcomeCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: '/quran-home'),
                      builder: (_) => const HomeScreen(),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 18),
              sliver: SliverToBoxAdapter(
                child: PrayerExperienceCard(
                  onTap: _openPrayerTimes,
                  onPlayingTap: _openElAzan,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _HomeSectionHeader(
                  title: 'التذكيرات',
                  subtitle: 'حافظ على صلاتك وأذكارك يوميًا.',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
              sliver: SliverToBoxAdapter(
                child: DailyReminderCard(
                  onTap: () => navigateTo(
                    context,
                    const DailyReminderSettingsScreen(),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
              sliver: const SliverToBoxAdapter(child: AdhanSettingsCard()),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _HomeSectionHeader(
                  title: 'أذكارك وأدعيتك اليومية',
                  subtitle: 'اختر ما يطمئن قلبك',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 144,
                child: ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _azkarDisplayOrder.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, displayIndex) {
                    final index = _azkarDisplayOrder[displayIndex];
                    return WirdCard(
                      item: AppColors.azkarCategories[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: RouteSettings(
                            name: '/azkar-category-$index',
                          ),
                          builder: (_) => AzkarAndHadeethScreen(index: index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 6),
              sliver: SliverToBoxAdapter(
                child: const _HomeSectionHeader(
                  title: 'قصص وهدي',
                  subtitle: 'رحلة قراءة في قصص الأنبياء والسيرة',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 158,
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StoryHomeCard(
                      title: 'قصص الأنبياء',
                      subtitle: 'عبر ودروس من القرآن',
                      image: AppAssets.prophetsCardBackground,
                      icon: Icons.auto_stories_rounded,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: '/stories/prophets'),
                          builder: (_) => const StoryCollectionScreen(isSeerah: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StoryHomeCard(
                      title: 'السيرة النبوية',
                      subtitle: 'مراحل من حياة النبي ﷺ',
                      image: AppAssets.seerahCardBackground,
                      icon: Icons.mosque_rounded,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: '/stories/seerah'),
                          builder: (_) => const StoryCollectionScreen(isSeerah: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 30),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeSectionHeader(
                      title: 'زادك الإيماني',
                      subtitle: 'تعرّف إلى أسماء الله واستقبل قبلتك',
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.38,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        HomeFeatureTile(
                          icon: Icons.auto_awesome_rounded,
                          title: 'أسماء الله الحسنى',
                          onTap:
                              () =>
                                  navigateTo(context, const AsmaaAllahScreen()),
                        ),
                        HomeFeatureTile(
                          icon: Icons.explore_rounded,
                          title: 'بوصلة القبلة',
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/qibla'),
                              builder: (_) => const QiblaCompassScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StoryHomeCard extends StatelessWidget {
  const _StoryHomeCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 224,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .12),
                    Colors.black.withValues(alpha: .76),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: .9),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
