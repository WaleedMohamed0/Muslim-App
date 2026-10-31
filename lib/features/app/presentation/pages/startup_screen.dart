import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/assets/app_assets.dart';
import 'package:untitled8/core/theme/app_colors.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: theme.colorScheme.primaryContainer, child: Image.asset(AppAssets.quranLogo, width: 28, height: 28)),
                    const SizedBox(width: 10),
                    Text('مُسلم', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    BlocBuilder<AppCubit, AppState>(
                      builder: (context, state) => IconButton.filledTonal(
                        tooltip: state.themeMode == ThemeMode.dark ? 'الوضع النهاري' : 'الوضع الليلي',
                        onPressed: context.read<AppCubit>().toggleThemeMode,
                        icon: Icon(state.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              sliver: SliverToBoxAdapter(child: _WelcomeCard(onTap: () => navigateTo(context, const HomeScreen()))),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(children: [Text('وردك اليومي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), Text('اختر ما يطمئن قلبك', style: theme.textTheme.bodySmall)]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 144,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColors.azkarCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _WirdCard(
                    item: AppColors.azkarCategories[index],
                    onTap: () => navigateTo(context, AzkarAndHadeethScreen(index: index)),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _HomeFeatureTile(icon: Icons.schedule_rounded, title: 'مواقيت الصلاة', subtitle: 'كن قريبًا من مواعيد صلاتك', onTap: () => navigateTo(context, const PrayerTimes())),
                    const SizedBox(height: 10),
                    _HomeFeatureTile(icon: Icons.auto_awesome_rounded, title: 'أسماء الله الحسنى', subtitle: 'تعرّف إلى الأسماء ومعانيها', onTap: () => navigateTo(context, const AsmaaAllahScreen())),
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
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: const BoxConstraints(minHeight: 194),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: .78)], begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('السلام عليكم', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 9),
                    Text('لحظاتٌ من السكينة\nتبدأ بآية', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.35)),
                    const SizedBox(height: 16),
                    const Row(children: [Text('ابدأ القراءة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), SizedBox(width: 7), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)]),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.menu_book_rounded, size: 76, color: Colors.white.withValues(alpha: .88)),
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
                DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .02), Colors.black.withValues(alpha: .72)]))),
                Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.all(14), child: Text(item.$1, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)))),
              ],
            ),
          ),
        ),
      );
}

class _HomeFeatureTile extends StatelessWidget {
  const _HomeFeatureTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}
