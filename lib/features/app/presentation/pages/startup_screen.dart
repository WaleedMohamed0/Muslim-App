import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/azkar/presentation/azkar_categories.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/core/widgets/app_back_arrow.dart';
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
import 'package:muslim/features/khatmah/presentation/pages/khatmah_screen.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_audio_mini_player.dart';
import 'package:muslim/features/app/presentation/widgets/startup_home_widgets.dart';
import 'package:muslim/features/app/presentation/widgets/prayer_wird_home_section.dart';
import 'package:muslim/features/app/presentation/widgets/daily_wird_home_card.dart';
import 'package:muslim/features/app/presentation/pages/daily_reminder_settings_screen.dart';
import 'package:muslim/features/app/presentation/pages/app_settings_screen.dart';
import 'package:muslim/core/assets/app_assets.dart';
import 'package:muslim/features/tajweed/presentation/pages/tajweed_lessons_screen.dart';
import 'package:muslim/features/worship/presentation/pages/worship_guide_screen.dart';
import 'package:muslim/features/travel_prayer/presentation/pages/travel_prayer_guide_screen.dart';
import 'package:muslim/features/aqeedah/presentation/pillars_screen.dart';
import 'package:muslim/features/app/data/data_sources/startup_permissions_data_source.dart';
import 'package:muslim/features/app/data/data_sources/onboarding_preferences.dart';
import 'package:muslim/features/app/data/data_sources/quran_widget_intro_preferences.dart';
import 'package:muslim/features/app/presentation/pages/quran_widget_tutorial.dart';
import 'package:muslim/features/app/presentation/cubit/startup_cubit.dart';
import 'package:muslim/features/tasbeeh/presentation/pages/tasbeeh_screen.dart';

class StartUpScreen extends StatefulWidget {
  const StartUpScreen({super.key});

  @override
  State<StartUpScreen> createState() => _StartUpScreenState();
}

class _AzkarDiscoveryCarousel extends StatefulWidget {
  const _AzkarDiscoveryCarousel({required this.displayOrder});

  final List<int> displayOrder;

  @override
  State<_AzkarDiscoveryCarousel> createState() =>
      _AzkarDiscoveryCarouselState();
}

class _AzkarDiscoveryCarouselState extends State<_AzkarDiscoveryCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudgeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);
  bool _hasScrolled = false;

  bool _handleScroll(ScrollNotification notification) {
    if (!_hasScrolled &&
        notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.horizontal &&
        notification.scrollDelta != null &&
        notification.scrollDelta!.abs() > .5) {
      setState(() => _hasScrolled = true);
      _nudgeController.stop();
    }
    return false;
  }

  @override
  void dispose() {
    _nudgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 144,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 12),
              scrollDirection: Axis.horizontal,
              itemCount: widget.displayOrder.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, displayIndex) {
                final index = widget.displayOrder[displayIndex];
                return WirdCard(
                  item: azkarCategories[index],
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: RouteSettings(
                            name: '/azkar-category-$index',
                          ),
                          builder:
                              (_) => AzkarAndHadeethScreen(index: index),
                        ),
                      ),
                );
              },
            ),
          ),
          PositionedDirectional(
            end: 4,
            top: 55,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _hasScrolled ? 0 : 1,
                duration: const Duration(milliseconds: 240),
                child: AnimatedBuilder(
                  animation: _nudgeController,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      (isRtl ? -1 : 1) * 3 * _nudgeController.value,
                      0,
                    ),
                    child: child,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: .92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(
                            alpha: theme.brightness == Brightness.dark ? .22 : .1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        isRtl
                            ? Icons.keyboard_double_arrow_left_rounded
                            : Icons.keyboard_double_arrow_right_rounded,
                        size: 19,
                        color: theme.colorScheme.primary.withValues(alpha: .8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartUpScreenState extends State<StartUpScreen> {
  late final StartupCubit _startupCubit;

  // Keep category indices tied to their existing routes/data while putting
  // the most frequently used Azkar shortcuts first in the carousel.
  static const _azkarDisplayOrder = [0, 1, 5, 2, 3, 4, 6, 7, 8, 9, 10, 11];
  final ValueNotifier<double> _miniPlayerHeight = ValueNotifier(0);
  bool _widgetIntroFlowStarted = false;

  @override
  void initState() {
    super.initState();
    _startupCubit = StartupCubit(permissions: StartupPermissionsDataSource());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startFirstLaunchFlow());
    });
  }

  Future<void> _startFirstLaunchFlow() async {
    // Notification launches can place Home underneath a destination reader.
    // Wait until Home is visible before showing first-launch permission prompts.
    while (mounted && !(ModalRoute.of(context)?.isCurrent ?? false)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    await _startupCubit.requestFirstLaunchPermissions(
          explainPermission: _explainPermission,
          isMounted: () => mounted,
      );
    if (!mounted || _widgetIntroFlowStarted) return;
    _widgetIntroFlowStarted = true;
    if (!await const OnboardingPreferences().isWidgetIntroEligible()) return;
    const introPreferences = QuranWidgetIntroPreferences();
    if (await introPreferences.hasBeenShown() || !mounted) return;

    // Poll the route until Home is active. This naturally waits out dialogs,
    // permission screens, and pushed pages without racing another sheet.
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    while (mounted && !(ModalRoute.of(context)?.isCurrent ?? false)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    await introPreferences.markShown();
    if (!mounted) return;
    await showQuranWidgetIntroduction(context);
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
        builder:
            (dialogContext) => Directionality(
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
                          onPressed:
                              () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  settings: const RouteSettings(
                                    name: '/settings',
                                  ),
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
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(
                                name: '/quran-home',
                              ),
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
                const SliverToBoxAdapter(child: PrayerWirdHomeSection()),
                const SliverToBoxAdapter(child: DailyWirdHomeCard()),
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
                      onTap:
                          () => navigateTo(
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
                  child: _AzkarDiscoveryCarousel(
                    displayOrder: _azkarDisplayOrder,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 30),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeSectionHeader(
                          title: 'أقسام أخرى',
                          subtitle: 'تعرّف إلى أسماء الله واستقبل قبلتك',
                        ),
                        const SizedBox(height: 12),
                        PillarsHomeCard(
                          onTap:
                              () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  settings: const RouteSettings(
                                    name: '/aqeedah-pillars',
                                  ),
                                  builder: (_) => const PillarsScreen(),
                                ),
                              ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const crossAxisSpacing = 10.0;
                            final tileWidth =
                                (constraints.maxWidth - crossAxisSpacing) / 2;
                            final textScale =
                                MediaQuery.textScalerOf(context).scale(16) /
                                16;
                            return GridView(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: crossAxisSpacing,
                                    mainAxisSpacing: 10,
                                    mainAxisExtent:
                                        (tileWidth / 1.38) +
                                        (9 * textScale),
                                  ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                            HomeFeatureTile(
                              icon: Icons.auto_awesome_rounded,
                              title: 'أسماء الله الحسنى',
                              onTap:
                                  () => navigateTo(
                                    context,
                                    const AsmaaAllahScreen(),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.menu_book_rounded,
                              title: 'علامات المصحف',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/mushaf-markings',
                                      ),
                                      builder:
                                          (_) => const MushafMarkingsScreen(),
                                    ),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.explore_rounded,
                              title: 'بوصلة القبلة',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/qibla',
                                      ),
                                      builder:
                                          (_) => const QiblaCompassScreen(),
                                    ),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.menu_book_rounded,
                              title: 'دروس التجويد',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/tajweed',
                                      ),
                                      builder:
                                          (_) => const TajweedLessonsScreen(),
                                    ),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.water_drop_rounded,
                              title: 'تعلم الوضوء',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/learn-wudu',
                                      ),
                                      builder:
                                          (_) => const WorshipGuideScreen(
                                            lesson: 'wudu',
                                          ),
                                    ),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.mosque_rounded,
                              title: 'تعلم الصلاة',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/learn-prayer',
                                      ),
                                      builder:
                                          (_) => const WorshipGuideScreen(
                                            lesson: 'prayer',
                                          ),
                                    ),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.flight_takeoff_rounded,
                              title: 'وضع المسافر',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/travel-prayer',
                                      ),
                                      builder:
                                          (_) =>
                                              const TravelPrayerGuideScreen(),
                                    ),
                                  ),
                            ),
                            HomeFeatureTile(
                              icon: Icons.auto_stories_rounded,
                              title: 'ختمة القرآن الكريم',
                              onTap:
                                  () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      settings: const RouteSettings(
                                        name: '/khatmah',
                                      ),
                                      builder: (_) => const KhatmahScreen(),
                                    ),
                                  ),
                            ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap:
                                () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    settings: const RouteSettings(
                                      name: '/electronic-tasbeeh',
                                    ),
                                    builder: (_) => const TasbeehScreen(),
                                  ),
                                ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                14,
                                16,
                                14,
                              ),
                              child: Row(
                                textDirection: Directionality.of(context),
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.touch_app_rounded,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'المسبحة الإلكترونية',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'اجعل لسانك رطبًا بذكر الله',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppBackArrow(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _miniPlayerHeight,
                    builder:
                        (context, playerHeight, _) => SizedBox(
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
