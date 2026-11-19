import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/app/presentation/pages/app_settings_screen.dart';
import 'package:muslim/features/aqeedah/presentation/pillars_screen.dart';
import 'package:muslim/features/khatmah/presentation/pages/khatmah_screen.dart';
import 'package:muslim/features/qibla/presentation/pages/qibla_compass_screen.dart';
import 'package:muslim/features/tasbeeh/presentation/pages/tasbeeh_screen.dart';
import 'package:muslim/features/worship/presentation/pages/worship_guide_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <({String title, String subtitle, IconData icon, Widget page})>[
      (title: 'القبلة', subtitle: 'اتجاه القبلة والبوصلة', icon: Icons.explore_rounded, page: const QiblaCompassScreen()),
      (title: 'ختمة القرآن', subtitle: 'تابع خطتك ومقدار إنجازك', icon: Icons.auto_stories_rounded, page: const KhatmahScreen()),
      (title: 'السبحة الإلكترونية', subtitle: 'حافظ على ورد التسبيح', icon: Icons.touch_app_rounded, page: const TasbeehScreen()),
      (title: 'تعلم الوضوء', subtitle: 'تعرف على خطوات الوضوء وأحكامه', icon: Icons.water_drop_rounded, page: const WorshipGuideScreen(lesson: 'wudu')),
      (title: 'تعلم الصلاة', subtitle: 'تعرف على خطوات الصلاة وأحكامها', icon: Icons.mosque_rounded, page: const WorshipGuideScreen(lesson: 'prayer')),
      (title: 'أركان الإسلام و الإيمان', subtitle: 'تعرف على أركان دينك', icon: Icons.mosque_rounded, page: const PillarsScreen()),
      (title: 'الإعدادات', subtitle: 'التفضيلات والتنبيهات', icon: Icons.settings_rounded, page: const AppSettingsScreen()),
    ];
    return Scaffold(
      appBar: defaultAppBar(context: context, text: 'المزيد'),
      body: ListView(padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 28), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .65), borderRadius: BorderRadius.circular(22)), child: Row(children: [Icon(Icons.spa_rounded, color: scheme.primary, size: 28), const SizedBox(width: 12), Expanded(child: Text('كل ما تحتاجه لرحلتك الإيمانية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)))])),
        const SizedBox(height: 18),
        for (final item in items)
          Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 7, 14, 7), leading: CircleAvatar(backgroundColor: scheme.primaryContainer.withValues(alpha: .7), child: Icon(item.icon, color: scheme.primary)), title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(item.subtitle), trailing: const Directionality(textDirection: TextDirection.ltr, child: Icon(Icons.chevron_left_rounded)), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => item.page)))),
      ]),
    );
  }
}
