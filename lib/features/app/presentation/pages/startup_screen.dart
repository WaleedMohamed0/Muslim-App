import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/assets/app_assets.dart';
import 'package:untitled8/core/theme/app_colors.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/app/presentation/cubit/app_cubit.dart';
import 'package:untitled8/features/app/presentation/cubit/app_state.dart';
import 'package:untitled8/features/asmaa_allah/presentation/pages/asmaa_allah_screen.dart';
import 'package:untitled8/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:untitled8/features/prayer_times/presentation/pages/prayer_times_screen.dart';
import 'package:untitled8/features/quran/presentation/pages/home_screen.dart';

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
                child: _WelcomeCard(
                  onTap: () => navigateTo(context, const HomeScreen()),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 18),
              sliver: const SliverToBoxAdapter(child: _DailyReminderCard()),
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
                      (context, index) => _WirdCard(
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
                        _HomeFeatureTile(
                          icon: Icons.schedule_rounded,
                          title: 'مواقيت الصلاة',
                          onTap: () => navigateTo(context, const PrayerTimes()),
                        ),
                        _HomeFeatureTile(
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? colors.onPrimaryContainer : colors.onPrimary;
    final bannerColors =
        isDark
            ? [colors.primaryContainer, colors.surfaceContainerHigh]
            : [colors.primary, Color.lerp(colors.primary, Colors.black, .12)!];
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppRadii.dialog),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        child: Container(
          constraints: const BoxConstraints(minHeight: 194),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.dialog),
            gradient: LinearGradient(
              colors: bannerColors,
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'السلام عليكم',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground.withValues(alpha: .78),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'لحظاتٌ من السكينة\nتبدأ بآية',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'ابدأ القراءة',
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: foreground,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.menu_book_rounded,
                size: 76,
                color: foreground.withValues(alpha: .88),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WirdCard extends StatelessWidget {
  const _WirdCard({required this.item, required this.onTap});
  final (String, String) item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 172,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(item.$2, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .02),
                    Colors.black.withValues(alpha: .72),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(14),
                child: Text(
                  item.$1,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeFeatureTile extends StatelessWidget {
  const _HomeFeatureTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 10, 9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.onPrimaryContainer, size: 21),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyReminderCard extends StatelessWidget {
  const _DailyReminderCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تذكير اليوم\nلا تنسَ وردك من القرآن والأذكار',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onTertiaryContainer,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
