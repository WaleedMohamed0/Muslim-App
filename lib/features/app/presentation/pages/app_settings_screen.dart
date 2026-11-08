import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/widgets/app_widgets_impl.dart';
import 'package:muslim/core/widgets/app_back_arrow.dart';
import 'package:muslim/core/widgets/app_switch.dart';
import 'package:muslim/features/app/presentation/cubit/app_cubit.dart';
import 'package:muslim/features/app/presentation/cubit/app_state.dart';
import 'package:muslim/features/app/presentation/pages/device_permissions_screen.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/pages/quran_downloads_screen.dart';
import 'package:muslim/features/quran/presentation/pages/quran_reader_background_screen.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reciter_picker.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // QuranCubit is registered above MaterialApp in the app-wide providers.
    final quranCubit = context.read<QuranCubit>();
    return Scaffold(
      appBar: defaultAppBar(context: context, text: 'الإعدادات'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 28),
          children: [
            _SectionTitle(title: 'تفضيلات العرض'),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: BlocBuilder<AppCubit, AppState>(
                builder: (context, state) => AppSwitchListTile(
                  leading: const _SettingsLeadingIcon(
                    icon: Icons.dark_mode_rounded,
                  ),
                  title: const Text('الوضع الداكن'),
                  subtitle: Text(
                    state.themeMode == ThemeMode.dark
                        ? 'مفعّل'
                        : 'غير مفعّل',
                  ),
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (enabled) => context.read<AppCubit>().setThemeMode(
                    enabled ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'إعدادات الجهاز'),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const _SettingsLeadingIcon(
                  icon: Icons.admin_panel_settings_outlined,
                ),
                title: const Text('صلاحيات الجهاز'),
                subtitle: const Text('إدارة أذونات الإشعارات والموقع'),
                trailing: const _SettingsNavigationArrow(),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      name: '/device-permissions',
                    ),
                    builder: (_) => const DevicePermissionsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'إعدادات الْقُرْآن الكريم'),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: StreamBuilder<QuranState>(
                stream: quranCubit.stream,
                initialData: quranCubit.state,
                builder: (context, state) => ListTile(
                  titleAlignment: ListTileTitleAlignment.center,
                  leading: const _SettingsLeadingIcon(
                    icon: Icons.record_voice_over_rounded,
                  ),
                  title: const Text('القارئ المفضل'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('اختر القارئ للاستماع للقرآن الكريم'),
                      const SizedBox(height: 4),
                      Text(
                        quranCubit.selectedReciter.nameArabic,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  trailing: const _SettingsNavigationArrow(),
                  isThreeLine: true,
                  onTap: () => showQuranReciterPicker(context, quranCubit),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const _SettingsLeadingIcon(
                  icon: Icons.palette_outlined,
                ),
                title: const Text('لون خلفية القراءة'),
                subtitle: const Text('اختر لونًا مناسبًا لكل وضع لوني'),
                trailing: const _SettingsNavigationArrow(),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      name: '/quran-reader-background',
                    ),
                    builder: (_) => const QuranReaderBackgroundScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const _SettingsLeadingIcon(
                  icon: Icons.download_for_offline_rounded,
                ),
                title: const Text('إدارة التنزيلات'),
                subtitle: const Text('عرض وحذف السور المحفوظة للاستماع دون اتصال'),
                trailing: const _SettingsNavigationArrow(),
                isThreeLine: false,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: '/quran-downloads'),
                    builder: (_) => const QuranDownloadsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLeadingIcon extends StatelessWidget {
  const _SettingsLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 22,
        color: Theme.of(context).brightness == Brightness.light
            ? AppTheme.settingsIconLight
            : colors.primary,
      ),
    );
  }
}

class _SettingsNavigationArrow extends StatelessWidget {
  const _SettingsNavigationArrow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrow = AppBackArrow(
      size: 18,
      color: theme.brightness == Brightness.light
          ? AppTheme.settingsIconLight
          : theme.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      width: 32,
      height: 40,
      child: Center(
        child: arrow,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      );
}
