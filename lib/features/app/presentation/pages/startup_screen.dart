import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/theme/app_colors.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/asmaa_allah/presentation/pages/asmaa_allah_screen.dart';
import 'package:muslim/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:muslim/features/prayer_times/presentation/pages/elazan_screen.dart';
import 'package:muslim/features/prayer_times/presentation/widgets/prayer_experience_card.dart';
import 'package:muslim/features/qibla/presentation/pages/qibla_compass_screen.dart';
import 'package:muslim/features/quran/presentation/pages/home_screen.dart';
import 'package:muslim/features/quran/presentation/pages/mushaf_markings_screen.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_audio_mini_player.dart';
import 'package:muslim/features/app/presentation/widgets/startup_home_widgets.dart';
import 'package:muslim/features/app/presentation/pages/daily_reminder_settings_screen.dart';
import 'package:muslim/features/app/presentation/pages/app_settings_screen.dart';
import 'package:muslim/core/assets/app_assets.dart';
import 'package:muslim/features/stories/presentation/pages/story_collection_screen.dart';
import 'package:muslim/features/tajweed/presentation/pages/tajweed_lessons_screen.dart';
import 'package:muslim/features/worship/presentation/pages/worship_guide_screen.dart';
import 'package:muslim/features/aqeedah/presentation/pillars_screen.dart';
import 'package:muslim/features/app/data/data_sources/startup_permissions_data_source.dart';
import 'package:muslim/features/app/presentation/cubit/startup_cubit.dart';
import 'package:muslim/features/zakat/presentation/pages/zakat_calculator_screen.dart';

class StartUpScreen extends StatefulWidget {
  const StartUpScreen({super.key});

  @override
  State<StartUpScreen> createState() => _StartUpScreenState();
}

class _StartUpScreenState extends State<StartUpScreen> {
  late final StartupCubit _startupCubit;
  // Keep category indices tied to their existing routes/data while putting
  // the most frequently used Azkar shortcuts first in the carousel.
  static const _azkarDisplayOrder = [0, 1, 5, 2, 3, 4, 6, 7, 8, 9, 10];
  final ValueNotifier<double> _miniPlayerHeight = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _startupCubit = StartupCubit(
      permissions: StartupPermissionsDataSource(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _startupCubit.requestFirstLaunchPermissions(
          explainPermission: _explainPermission,
          isMounted: () => mounted,
        ),
      );
    });
  }

  @override
  void dispose() {
    _miniPlayerHeight.dispose();
    _startupCubit.close();
    super.dispose();
  }

  Future<bool> _explainPermission(String title, String description) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            actionsAlignment: MainAxisAlignment.spaceBetween,
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
  Widget build(BuildContext context) => BlocBuilder<QuranCubit, QuranState>(
    builder: (context, _) {
      final theme = Theme.of(context);
      final quranCubit = context.read<QuranCubit>();
      return Scaffold(
        body: myPanel(
          context: context,
          cubit: quranCubit,
          onMiniPlayerHeightChanged: (height) {
            if (!mounted || (_miniPlayerHeight.value - height).abs() < .5) {
              return;
            }
            _miniPlayerHeight.value = height;
          },
          screen: SafeArea(
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
                        color:
                            theme.brightness == Brightness.light
                                ? theme.colorScheme.primary
                                : null,
                        colorBlendMode: BlendMode.srcIn,
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
                    IconButton.filledTonal(
                      tooltip: 'الإعدادات',
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: '/settings'),
                          builder: (_) => const AppSettingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.settings_rounded),
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
                child: HomeSectionHeader(
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
                child: HomeSectionHeader(
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
                child: const HomeSectionHeader(
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
                    StoryHomeCard(
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
                    StoryHomeCard(
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
                    HomeSectionHeader(
                      title: 'زادك الإيماني',
                      subtitle: 'تعرّف إلى أسماء الله واستقبل قبلتك',
                    ),
                    const SizedBox(height: 12),
                    PillarsHomeCard(onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/aqeedah-pillars'),
                        builder: (_) => const PillarsScreen(),
                      ),
                    )),
                    const SizedBox(height: 10),
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
                          icon: Icons.savings_rounded,
                          title: 'حاسبة الزكاة',
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/zakat'),
                              builder: (_) => const ZakatCalculatorScreen(),
                            ),
                          ),
                        ),
                        HomeFeatureTile(
                          icon: Icons.menu_book_rounded,
                          title: 'علامات المصحف',
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/mushaf-markings'),
                              builder: (_) => const MushafMarkingsScreen(),
                            ),
                          ),
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
                        HomeFeatureTile(
                          icon: Icons.menu_book_rounded,
                          title: 'دروس التجويد',
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/tajweed'),
                              builder: (_) => const TajweedLessonsScreen(),
                            ),
                          ),
                        ),
                        HomeFeatureTile(
                          icon: Icons.water_drop_rounded,
                          title: 'تعلم الوضوء',
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/learn-wudu'),
                              builder: (_) => const WorshipGuideScreen(lesson: 'wudu'),
                            ),
                          ),
                        ),
                        HomeFeatureTile(
                          icon: Icons.mosque_rounded,
                          title: 'تعلم الصلاة',
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: '/learn-prayer'),
                              builder: (_) => const WorshipGuideScreen(lesson: 'prayer'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<double>(
                valueListenable: _miniPlayerHeight,
                builder: (context, playerHeight, _) => SizedBox(
                  height: quranMiniPlayerBottomInset(
                    context,
                    visible: quranCubit.quranSoundActive,
                    measuredHeight: playerHeight,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
    },
  );
}


