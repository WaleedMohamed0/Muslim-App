import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/theme/app_colors.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/app/presentation/cubit/app_cubit.dart';
import 'package:untitled8/features/app/presentation/cubit/app_state.dart';
import 'package:untitled8/features/asmaa_allah/presentation/pages/asmaa_allah_screen.dart';
import 'package:untitled8/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:untitled8/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:untitled8/features/quran/presentation/pages/home_screen.dart';
import 'package:untitled8/features/app/presentation/widgets/startup_home_widgets.dart';
import 'package:untitled8/core/assets/app_assets.dart';

class StartUpScreen extends StatelessWidget {
  const StartUpScreen({super.key});

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
                  onTap: () => navigateTo(context, const HomeScreen()),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 18),
              sliver: const SliverToBoxAdapter(child: DailyReminderCard()),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
              sliver: const SliverToBoxAdapter(child: AdhanSettingsCard()),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'وردك اليومي',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'اختر ما يطمئن قلبك',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 144,
                child: ListView.separated(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColors.azkarCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder:
                      (context, index) => WirdCard(
                        item: AppColors.azkarCategories[index],
                        onTap:
                            () => navigateTo(
                              context,
                              AzkarAndHadeethScreen(index: index),
                            ),
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 30),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'عباداتك اليومية',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                          icon: Icons.schedule_rounded,
                          title: 'مواقيت الصلاة',
                          onTap: () => navigateTo(context, const PrayerTimes()),
                        ),
                        HomeFeatureTile(
                          icon: Icons.auto_awesome_rounded,
                          title: 'أسماء الله الحسنى',
                          onTap:
                              () =>
                                  navigateTo(context, const AsmaaAllahScreen()),
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

