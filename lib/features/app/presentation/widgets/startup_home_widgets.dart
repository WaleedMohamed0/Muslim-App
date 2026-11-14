import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/widgets/app_back_arrow.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/prayer_times/presentation/pages/prayer_adhan_settings_screen.dart';

class AdhanSettingsCard extends StatefulWidget {
  const AdhanSettingsCard({super.key});

  @override
  State<AdhanSettingsCard> createState() => AdhanSettingsCardState();
}

class AdhanSettingsCardState extends State<AdhanSettingsCard> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final settings = await PrayerAdhanService.instance.loadSettings();
    if (mounted) setState(() => _enabled = settings.enabled);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/adhan-settings'),
        builder: (_) => const PrayerAdhanSettingsScreen(),
      ),
    );
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = _enabled == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openSettings,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.mosque_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إعدادات الأذان',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _enabled == null
                          ? 'جارٍ التحقق من الحالة…'
                          : enabled
                          ? 'الأذان مفعّل'
                          : 'الأذان غير مفعّل',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            enabled ? colors.primary : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppBackArrow(),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = colors.onSurface;
    final accent = colors.primary;
    final cardColor =
        Color.lerp(
          isDark ? colors.surfaceContainerHigh : colors.surface,
          colors.primaryContainer,
          isDark ? .42 : .62,
        )!;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(AppRadii.dialog),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        child: Container(
          constraints: const BoxConstraints(minHeight: 164),
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.dialog),
            border: Border.all(color: accent.withValues(alpha: .32)),
            gradient: LinearGradient(
              colors: [cardColor, Color.lerp(cardColor, colors.primary, .08)!],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'القرآن الكريم',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'المصحف الشريف',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            11,
                            7,
                            11,
                            7,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: isDark ? .22 : .13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: accent,
                                size: 17,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'افتح المصحف',
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 88,
                height: 112,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? .18 : .11),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: .28)),
                ),
                child: Icon(Icons.menu_book_rounded, size: 52, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WirdCard extends StatelessWidget {
  const WirdCard({super.key, required this.item, required this.onTap});

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
            Image.asset(
              item.$2,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 516,
            ),
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

class HomeFeatureTile extends StatelessWidget {
  const HomeFeatureTile({
    super.key,
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

class DailyReminderCard extends StatelessWidget {
  const DailyReminderCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.tertiaryContainer,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: colors.onTertiaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'التذكيرات\nأذكار الصباح والمساء ووردك اليومي',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onTertiaryContainer,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppBackArrow(),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

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

class PillarsHomeCard extends StatelessWidget {
  const PillarsHomeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [colors.primaryContainer, colors.surface],
            ),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 16, 15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primary.withValues(alpha: .12),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أَرْكَان الْإِسْلَام والإيمان',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تعرّف على أَرْكَان دينك وتعلّم أساسيات العقيدة الإسلامية.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
