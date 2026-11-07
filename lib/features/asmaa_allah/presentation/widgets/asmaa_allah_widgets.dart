import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/asmaa_allah/domain/entities/allah_name.dart';
class AsmaNameCard extends StatelessWidget {
  const AsmaNameCard({required this.name, required this.number, required this.onTap});
  final AllahName name;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: colors.primary.withValues(alpha: .48), width: 3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 28, height: 28, alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: .65), shape: BoxShape.circle),
                child: Text(toArabicIndicDigits(number), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700))),
              const Spacer(),
              Icon(Icons.open_in_new_rounded, size: 16, color: colors.onSurfaceVariant.withValues(alpha: .7)),
            ]),
            const SizedBox(height: 9),
            Text(name.name, textDirection: TextDirection.rtl, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700, height: 1.5)),
            const SizedBox(height: 5),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final meaningStyle = Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant, height: 1.5);
                  final measure = TextPainter(
                    text: TextSpan(text: name.meaning, style: meaningStyle),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: constraints.maxWidth);
                  final isTruncated = measure.didExceedMaxLines;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name.meaning,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: meaningStyle,
                      ),
                      if (isTruncated) ...[
                        const SizedBox(height: 4),
                        Text(
                          'اضغط لقراءة المزيد',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class AsmaNameDetails extends StatefulWidget {
  const AsmaNameDetails({required this.name, required this.number});
  final AllahName name;
  final int number;

  @override
  State<AsmaNameDetails> createState() => AsmaNameDetailsState();
}

class AsmaNameDetailsState extends State<AsmaNameDetails> {
  static const _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 28),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(toArabicIndicDigits(widget.number), textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(widget.name.name, textDirection: TextDirection.rtl, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700, height: 1.6)),
        const SizedBox(height: 16),
        Divider(color: colors.outlineVariant.withValues(alpha: .65)),
        const SizedBox(height: 12),
        Text('المعنى', textDirection: TextDirection.rtl, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final meaningStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.9,
            color: colors.onSurface,
          );
          final measure = TextPainter(
            text: TextSpan(text: widget.name.meaning, style: meaningStyle),
            textDirection: TextDirection.rtl,
            maxLines: _collapsedLines,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final hasMore = measure.didExceedMaxLines;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Text(
                  widget.name.meaning,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  maxLines: _expanded || !hasMore ? null : _collapsedLines,
                  overflow: _expanded || !hasMore
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: meaningStyle,
                ),
              ),
              if (hasMore)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsetsDirectional.only(start: 0, end: 8),
                    ),
                    child: Text(_expanded ? 'اقرأ أقل' : 'اقرأ المزيد'),
                  ),
                ),
            ],
          );
        }),
      ])),
    );
  }
}

class AsmaNamesLoadError extends StatelessWidget {
  const AsmaNamesLoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 40, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12), const Text('تعذر تحميل الأسماء'), const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
      ]),
    ),
  );
}

