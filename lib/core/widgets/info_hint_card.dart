import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';

/// A compact, theme-aware informational hint used at the top of content pages.
class InfoHintCard extends StatelessWidget {
  const InfoHintCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .65)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onTertiaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
