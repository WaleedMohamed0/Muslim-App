import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
class AzkarTextCard extends StatelessWidget {
  const AzkarTextCard({
    required this.text,
    required this.onCopy,
    this.repetitionCount,
    this.reference,
    this.instructions,
    this.counter,
    this.onTap,
    this.onIncrement,
    this.isFavorite = false,
    this.onFavorite,
    this.onShare,
    this.sectionLabel,
  });
  final String text;
  final int? counter;
  final int? repetitionCount;
  final String? reference;
  final String? instructions;
  final VoidCallback? onTap;
  final VoidCallback onCopy;
  final VoidCallback? onIncrement;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sectionLabel != null && sectionLabel!.isNotEmpty) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    toArabicIndicDigits(sectionLabel!),
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
            Text(
              toArabicIndicDigits(text),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(
                fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) + 2,
                height: 1.9,
              ),
            ),
            if (instructions != null && instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                toArabicIndicDigits(instructions!),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ],
            if (reference != null && reference!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                toArabicIndicDigits('المصدر: $reference'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (repetitionCount != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Text(
                    'عدد التكرار: ${toArabicIndicDigits(repetitionCount!)}',
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (counter != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _TasbeehActionButton(
                                onPressed: onIncrement,
                                tooltip: 'زيادة العداد',
                                icon: Icons.add_rounded,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const Spacer(),
                              _TasbeehActionButton(
                                onPressed: onCopy,
                                tooltip: 'نسخ الذِّكْر',
                                icon: Icons.content_copy_rounded,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                          IgnorePointer(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                toArabicIndicDigits(
                                  '$counter${repetitionCount == null ? '' : ' / $repetitionCount'}',
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontSize: (Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.fontSize ??
                                              16) +
                                          2,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  if (repetitionCount != null) ...[
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Text(
                        'التكرار: ${toArabicIndicDigits(repetitionCount!)}',
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  _TasbeehActionButton(
                    onPressed: onCopy,
                    tooltip: 'نسخ الذِّكْر',
                    icon: Icons.content_copy_rounded,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ],
            ),
            if (counter != null && repetitionCount != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  counter! >= repetitionCount!
                      ? 'اكتمل الذِّكْر'
                      : 'المتبقي: ${toArabicIndicDigits(repetitionCount! - counter!)}',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
            if (onFavorite != null || onShare != null) ...[
              const SizedBox(height: 4),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  if (onFavorite != null)
                    IconButton(
                      onPressed: onFavorite,
                      tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (onShare != null)
                    IconButton(
                      onPressed: onShare,
                      tooltip: 'مشاركة الدُّعَاء',
                      icon: const Icon(Icons.share_rounded),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TasbeehActionButton extends StatelessWidget {
  const _TasbeehActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor.withValues(alpha: .45),
      disabledForegroundColor: foregroundColor.withValues(alpha: .55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
    ),
    icon: Icon(icon, size: 20),
  );
}

