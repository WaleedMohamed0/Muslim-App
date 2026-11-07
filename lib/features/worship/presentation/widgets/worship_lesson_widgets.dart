import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';

import '../../data/worship_ui_strings.dart';
import '../../domain/entities/worship_step.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WorshipStepCard extends StatelessWidget {
  const WorshipStepCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.assetPath,
  });

  final WorshipStep step;
  final int index;
  final int total;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: .10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              // Raster illustrations contain opaque pixels right up to their
              // image bounds. Save-layer clipping prevents those edge pixels
              // from bleeding into the rounded corners on light surfaces.
              clipBehavior: theme.brightness == Brightness.light
                  ? Clip.antiAliasWithSaveLayer
                  : Clip.antiAlias,
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: colors.surfaceContainerLow,
                child: SizedBox(
                  height: 270,
                  width: double.infinity,
                  child: assetPath.endsWith('.svg')
                      ? SvgPicture.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          semanticsLabel: WorshipUiStrings.illustrationSemantics(step: toArabicIndicDigits(index + 1), title: step.title),
                          placeholderBuilder: (_) => Center(
                            child: Icon(Icons.auto_awesome_rounded, size: 54, color: colors.primary.withValues(alpha: .35)),
                          ),
                        )
                      : Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          semanticLabel: WorshipUiStrings.illustrationSemantics(step: toArabicIndicDigits(index + 1), title: step.title),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(30)),
                  child: Text(WorshipUiStrings.stepProgress(current: toArabicIndicDigits(index + 1), total: toArabicIndicDigits(total)), style: theme.textTheme.labelLarge?.copyWith(color: colors.onPrimaryContainer, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(value: (index + 1) / total, minHeight: 6, backgroundColor: colors.surfaceContainerHighest),
            ),
            const SizedBox(height: 18),
            Text(step.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.35)),
            const SizedBox(height: 8),
            Text(step.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.8, color: colors.onSurfaceVariant)),
            if (step.recitation != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outlineVariant.withValues(alpha: .65))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(WorshipUiStrings.recitationLabel, style: theme.textTheme.labelLarge?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    step.recitation!,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 2.1,
                      fontWeight: FontWeight.w700,
                      // Use the same Uthmani font as the Mushaf so the
                      // end-of-ayah glyph encloses its Arabic-Indic number.
                      fontFamily: step.recitation!.contains('۝')
                          ? 'UthmanicHafs'
                          : null,
                    ),
                  ),
                ]),
              ),
            ],
            if (step.note != null) ...[
              const SizedBox(height: 14),
              _InlineNote(text: step.note!),
            ],
          ],
        ),
      ),
    );
  }
}

class WorshipSectionCard extends StatelessWidget {
  const WorshipSectionCard({super.key, required this.title, required this.icon, required this.items, this.intro});
  final String title;
  final IconData icon;
  final List<String> items;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: colors.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)))]),
          if (intro != null) ...[const SizedBox(height: 6), Text(intro!, style: theme.textTheme.bodySmall?.copyWith(height: 1.6, color: colors.onSurfaceVariant))],
          const SizedBox(height: 6),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 7, height: 7, margin: const EdgeInsetsDirectional.only(top: 9, end: 10), decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)),
                Expanded(child: Text(items[i], style: theme.textTheme.bodyMedium?.copyWith(height: 1.65))),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.tertiaryContainer.withValues(alpha: .55), borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline_rounded, size: 19, color: colors.onTertiaryContainer), const SizedBox(width: 9), Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6, color: colors.onTertiaryContainer)))]),
    );
  }
}
