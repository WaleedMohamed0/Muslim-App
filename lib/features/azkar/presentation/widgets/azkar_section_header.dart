import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';

class AzkarSectionHeader extends StatelessWidget {
  const AzkarSectionHeader({
    super.key,
    required this.isHadith,
    required this.totalCount,
    this.showTasbeehHint = false,
  });

  final bool isHadith;
  final int totalCount;
  final bool showTasbeehHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Container(
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
                    isHadith ? 'من هدي النَّبِيّ' : 'اذكر اللَّه بقلبٍ حاضر',
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
    );
  }
}
