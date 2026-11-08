import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';
import '../../domain/entities/mushaf_marking.dart';

class MushafMarkingCard extends StatelessWidget {
  const MushafMarkingCard({super.key, required this.marking});
  final MushafMarking marking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.outlineVariant, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(textDirection: TextDirection.rtl, crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                constraints: const BoxConstraints(minWidth: 68, minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                  border: Border.all(color: colors.primary.withValues(alpha: .35)),
                ),
                child: Text(marking.symbol, textDirection: TextDirection.rtl, textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimaryContainer, fontWeight: FontWeight.w800, fontFamily: 'UthmanicHafs',
                  )),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(marking.name, textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.onSurface))),
            ]),
            const SizedBox(height: 12),
            Text(marking.meaning, textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.65, color: colors.onSurface)),
            if (marking.example != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: _buildExample(context, marking),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExample(BuildContext context, MushafMarking marking) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final example = marking.example!;
    final match = _findRelevantMark(marking.symbol, example);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.9,
      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) + 2,
      color: colors.onSurface,
      fontFamily: 'UthmanicHafs',
    );
    final emphasizedStyle = baseStyle?.copyWith(
      fontSize: (baseStyle.fontSize ?? 16) + 5,
      fontWeight: FontWeight.w900,
      color: colors.onPrimaryContainer,
      backgroundColor: colors.primaryContainer,
      height: 1.35,
    );

    if (match == null) {
      return Text.rich(
        TextSpan(children: [
          TextSpan(text: '${marking.symbol}  ', style: emphasizedStyle),
          TextSpan(text: example, style: baseStyle),
        ]),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.start,
      );
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: example.substring(0, match.start), style: baseStyle),
        TextSpan(text: example.substring(match.start, match.end), style: emphasizedStyle),
        TextSpan(text: example.substring(match.end), style: baseStyle),
      ]),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.start,
    );
  }

  RegExpMatch? _findRelevantMark(String symbol, String example) {
    // Madani print symbols are often represented by Unicode combining marks in
    // the example text, while the card heading uses their traditional names.
    final candidates = switch (symbol) {
      'مـ' => ['ۘ'],
      'لا' => ['ۙ', 'لا'],
      'ج' => ['ۚ', 'ج'],
      'صلى' => ['ۖ', 'صلى'],
      'قلى' => ['ۗ', 'قلى'],
      '∴  ∴' => ['ۛ'],
      'س' => ['ۜ', 'س'],
      'ٓ' => ['ٓ'],
      'ۖ' => ['ۖ'],
      'ۗ' => ['ۗ'],
      'مّ' => ['ۢ', 'مّ'],
      'ْ' => ['ْ'],
      'ّ' => ['ّ'],
      'ً ٍ ٌ' => ['ً', 'ٍ', 'ٌ'],
      _ => [symbol],
    };
    RegExpMatch? best;
    for (final candidate in candidates) {
      final match = RegExp(RegExp.escape(candidate)).firstMatch(example);
      if (match != null && (best == null || match.start < best.start)) best = match;
    }
    return best;
  }
}

class MushafCategoryChip extends StatelessWidget {
  const MushafCategoryChip({super.key, required this.category, required this.selected, required this.onTap});
  final MushafMarkingCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(category.label),
        selected: selected,
        side: const BorderSide(color: Colors.grey, width: 1.5),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
