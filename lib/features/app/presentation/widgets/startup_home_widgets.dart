import 'package:flutter/material.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:untitled8/features/prayer_times/presentation/pages/prayer_adhan_settings_screen.dart';

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
                child: Icon(Icons.mosque_rounded, color: colors.onPrimaryContainer),
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
                        color: enabled ? colors.primary : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
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
  const DailyReminderCard({super.key});

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
