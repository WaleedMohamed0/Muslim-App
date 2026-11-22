import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';

class AzkarSectionHeader extends StatelessWidget {
  const AzkarSectionHeader({
    super.key,
    required this.isHadith,
    required this.totalCount,
    this.showTasbeehHint = false,
    this.showCounterHint = false,
    this.showTotalCount = true,
    this.onScheduleTap,
    this.scheduleHintTitle = 'فعّل تذكير الأذكار',
    this.scheduleHintMessage = 'اختر موعدًا لتذكيرك صباحًا ومساءً',
  });

  final bool isHadith;
  final int totalCount;
  final bool showTasbeehHint;
  final bool showCounterHint;
  final bool showTotalCount;
  final VoidCallback? onScheduleTap;
  final String scheduleHintTitle;
  final String scheduleHintMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isHadith ? Icons.menu_book_rounded : Icons.spa_rounded,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHadith
                            ? 'من هدي النَّبِيّ'
                            : 'اذكر اللَّه بقلبٍ حاضر',
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                      if (isHadith) ...[
                        const SizedBox(height: 3),
                        Text(
                          'اضغط على أي حديث لعرض المزيد من التفاصيل والمصدر.',
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (showTotalCount) ...[
                        const SizedBox(height: 4),
                        Text(
                          isHadith
                              ? 'عدد الْأَحَادِيث المتاحة: ${toArabicIndicDigits(totalCount)}'
                              : 'المتاح في هذا القسم: ${toArabicIndicDigits(totalCount)}',
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (showTasbeehHint) ...[
                        const SizedBox(height: 6),
                        Text(
                          'اضغط رمز المعلومات بجانب التسبيحة لعرض فضلها ومصدرها.',
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: showCounterHint
                ? const Padding(
                    padding: EdgeInsetsDirectional.only(top: 8),
                    child: _CounterHint(),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
          if (onScheduleTap != null) ...[
            const SizedBox(height: 4),
            _AzkarScheduleHint(
              onTap: onScheduleTap!,
              title: scheduleHintTitle,
              message: scheduleHintMessage,
            ),
          ],
        ],
      ),
    );
  }
}

class _CounterHint extends StatelessWidget {
  const _CounterHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.touch_app_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'اضغط على الذكر لزيادة العدد',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AzkarScheduleHint extends StatelessWidget {
  const _AzkarScheduleHint({required this.onTap, required this.title, required this.message});

  final VoidCallback onTap;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
          child: Row(
              textDirection: TextDirection.rtl,
              children: [
              Container(
              width: 32,
              height: 32,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
              title,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
              message,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              ],
          ),
        ),
      ),
    );
  }
}
