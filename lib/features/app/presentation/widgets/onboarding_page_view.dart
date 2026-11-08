import 'package:flutter/material.dart';

class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({
    super.key,
    required this.data,
    required this.pageNumber,
  });

  final OnboardingPageData data;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight =
            (constraints.maxHeight * .40).clamp(170.0, 250.0).toDouble();
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: _FeatureIllustration(
                    icon: data.icon,
                    pageNumber: pageNumber,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(13, 7, 13, 7),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: .76),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.eyebrow,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: data.features
                        .map((feature) => _FeatureChip(label: feature))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}

class _FeatureIllustration extends StatelessWidget {
  const _FeatureIllustration({required this.icon, required this.pageNumber});

  static const _arabicPageNumbers = ['١', '٢', '٣', '٤'];
  static const _supportingIcons = <List<IconData>>[
    [Icons.search_rounded, Icons.bookmark_rounded, Icons.headphones_rounded],
    [Icons.access_time_rounded, Icons.notifications_active_rounded, Icons.tune_rounded],
    [Icons.favorite_rounded, Icons.explore_rounded, Icons.auto_awesome_rounded],
    [Icons.auto_stories_rounded, Icons.checklist_rounded, Icons.flag_rounded],
  ];

  final IconData icon;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors:
              isDark
                  ? [
                    colors.primaryContainer.withValues(alpha: .78),
                    colors.secondaryContainer.withValues(alpha: .64),
                  ]
                  : [colors.surface, colors.secondaryContainer],
        ),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? .55 : .95),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            top: 42,
            start: 38,
            child: _IllustrationGlyph(icon: _supportingIcons[pageNumber - 1][0]),
          ),
          PositionedDirectional(
            top: 54,
            end: 40,
            child: _IllustrationGlyph(icon: _supportingIcons[pageNumber - 1][1]),
          ),
          PositionedDirectional(
            bottom: 48,
            start: 66,
            child: _IllustrationGlyph(icon: _supportingIcons[pageNumber - 1][2]),
          ),
          PositionedDirectional(
            top: 22,
            end: 26,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 24,
              color:
                  isDark
                      ? colors.secondary.withValues(alpha: .72)
                      : colors.primary.withValues(alpha: .64),
            ),
          ),
          PositionedDirectional(
            bottom: 25,
            start: 28,
            child: Icon(
              Icons.circle_outlined,
              size: 19,
              color: colors.primary.withValues(alpha: .45),
            ),
          ),
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface.withValues(alpha: isDark ? .76 : .96),
              border: Border.all(
                color: colors.primary.withValues(alpha: .17),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: .08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(child: Icon(icon, size: 72, color: colors.primary)),
          ),
          PositionedDirectional(
            bottom: 22,
            end: 24,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
                border: Border.all(color: colors.surface, width: 3),
              ),
              child: Text(
                _arabicPageNumbers[pageNumber - 1],
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationGlyph extends StatelessWidget {
  const _IllustrationGlyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, size: 21, color: colors.primary),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.features,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> features;
}

