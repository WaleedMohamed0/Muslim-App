import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/app/presentation/widgets/notification_logo.dart';

/// A self-contained, opaque card used only when exporting Azkar and Dua text.
class AzkarShareCard extends StatelessWidget {
  const AzkarShareCard({
    super.key,
    required this.text,
    required this.category,
    required this.captureKey,
  });

  final String text;
  final String? category;
  final GlobalKey captureKey;

  IconData _categoryIcon() {
    final label = category ?? '';
    if (label.contains('صباح') || label.contains('استيقاظ')) {
      return Icons.wb_sunny_outlined;
    }
    if (label.contains('مساء') || label.contains('نوم')) {
      return Icons.nightlight_outlined;
    }
    if (label.contains('صلاة') || label.contains('أذان')) {
      return Icons.mosque_outlined;
    }
    if (label.contains('دعاء') || label.contains('أدعية')) {
      return Icons.volunteer_activism_outlined;
    }
    if (label.contains('حديث')) return Icons.menu_book_outlined;
    return Icons.auto_awesome_outlined;
  }

  String? _subtitle() {
    final label = category ?? '';
    if (label.contains('صباح') || label.contains('مساء') || label.contains('نوم')) {
      return 'من الأذكار اليومية';
    }
    if (label.contains('دعاء') || label.contains('أدعية')) {
      return 'دعاء من القرآن والسُّنَّة';
    }
    if (label.contains('صلاة') || label.contains('أذان')) {
      return 'من الأذكار المرتبطة بالصلاة';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = scheme.primary;
    return RepaintBoundary(
      key: captureKey,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: dark
                  ? [const Color(0xFF263B33), const Color(0xFF17251F)]
                  : [const Color(0xFFF5F8F4), const Color(0xFFE5EEE7)],
            ),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: scheme.primary.withValues(alpha: .22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .28 : .12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_categoryIcon(), color: headerColor, size: 25),
                  const SizedBox(height: 8),
                  if (category != null && category!.trim().isNotEmpty)
                    Text(
                      category!,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: headerColor,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  if (_subtitle() case final subtitle?) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: headerColor.withValues(alpha: .22))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.circle, size: 6, color: headerColor.withValues(alpha: .6)),
                      ),
                      Expanded(child: Divider(color: headerColor.withValues(alpha: .22))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    toArabicIndicDigits(text),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontSize: 20,
                      height: 1.9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  NotificationLogo(
                    color: dark
                        ? const Color(0xFFB8F2D5)
                        : scheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
