import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

class ReaderControlsOverlay extends StatelessWidget {
  const ReaderControlsOverlay({
    required this.pageNumber,
    required this.pageCount,
    required this.fontSize,
    required this.palette,
    required this.bookmarked,
    required this.onBookmark,
    required this.onFontDecrease,
    required this.onFontIncrease,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
    required this.audioControls,
  });

  final int pageNumber;
  final int pageCount;
  final double fontSize;
  final QuranReaderPalette palette;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onFontDecrease;
  final VoidCallback onFontIncrease;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onBack;
  final Widget audioControls;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PositionedDirectional(
        top: 0,
        start: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8, top: 4),
            child: IconButton(
              tooltip: 'رجوع',
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: palette.surface,
                foregroundColor: palette.text,
                side: BorderSide(color: palette.muted.withValues(alpha: .35)),
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: .35),
              ),
              icon: const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: SingleChildScrollView(
              reverse: true,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: .14), blurRadius: 18, offset: const Offset(0, -4)),
                    ],
                  ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    12,
                    12,
                    12,
                    MediaQuery.viewPaddingOf(context).bottom + 8,
                  ),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 4, 8),
                      child: audioControls,
                    ),
                    Divider(height: 1, color: palette.muted.withValues(alpha: .16)),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 8),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          _ReaderIconButton(icon: Icons.chevron_left_rounded, tooltip: 'الصفحة السابقة', palette: palette, onPressed: onPrevious),
                          const SizedBox(width: 4),
                          _ReaderIconButton(icon: Icons.chevron_right_rounded, tooltip: 'الصفحة التالية', palette: palette, onPressed: onNext),
                          const Spacer(),
                          _ReaderIconButton(icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, tooltip: bookmarked ? 'إزالة علامة الصفحة' : 'حفظ الصفحة', palette: palette, onPressed: onBookmark),
                        ]),
                        Row(children: [
                          _ReaderIconButton(icon: Icons.remove, tooltip: 'تصغير الخط', palette: palette, size: 36, onPressed: fontSize > 22 ? onFontDecrease : null),
                          Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: 12), child: Text('حجم الخط  ${fontSize.round()}', style: TextStyle(color: palette.text, fontSize: 12, fontWeight: FontWeight.w600))),
                          _ReaderIconButton(icon: Icons.add, tooltip: 'تكبير الخط', palette: palette, size: 36, onPressed: fontSize < 32 ? onFontIncrease : null),
                          const Spacer(),
                          Text('صفحة ${toArabicIndicDigits(pageNumber)} من ${toArabicIndicDigits(pageCount)}', style: TextStyle(color: palette.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ReaderIconButton extends StatelessWidget {
  const _ReaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    required this.onPressed,
    this.size = 44,
  });
  final IconData icon;
  final String tooltip;
  final QuranReaderPalette palette;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: palette.surface,
      foregroundColor: palette.text,
      disabledForegroundColor: palette.muted.withValues(alpha: .4),
    ),
    constraints: BoxConstraints.tightFor(width: size, height: size),
    padding: EdgeInsets.zero,
    icon:
        icon == Icons.arrow_forward_rounded
            ? Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(icon),
            )
            : Icon(icon),
  );
}


