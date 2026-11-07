import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';

class QuranBrowseModeSwitcher extends StatelessWidget {
  const QuranBrowseModeSwitcher({
    super.key,
    required this.showJuzView,
    required this.isArabic,
    required this.onChanged,
  });

  final bool showJuzView;
  final bool isArabic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          _QuranBrowseModeOption(
            selected: !showJuzView,
            label: isArabic ? 'السور' : 'Surahs',
            icon: Icons.menu_book_rounded,
            onTap: () => onChanged(false),
          ),
          _QuranBrowseModeOption(
            selected: showJuzView,
            label: isArabic ? 'الأجزاء' : 'Juz',
            icon: Icons.auto_stories_rounded,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _QuranBrowseModeOption extends StatelessWidget {
  const _QuranBrowseModeOption({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
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
