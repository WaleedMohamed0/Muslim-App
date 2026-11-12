part of 'mushaf_text_page.dart';

class _VerseMarker extends StatelessWidget {
  const _VerseMarker({
    required this.number,
    required this.palette,
    this.isHighlighted = false,
    this.isBookmarked = false,
  });

  final int number;
  final QuranReaderPalette palette;
  final bool isHighlighted;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 29,
      height: 29,
      child: CustomPaint(
        painter: _VerseMarkerPainter(
          palette: palette,
          isHighlighted: isHighlighted,
          isBookmarked: isBookmarked,
        ),
        child: Center(
          child: Text(
            toArabicIndicDigits(number),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
}

class _VerseMarkerPainter extends CustomPainter {
  const _VerseMarkerPainter({
    required this.palette,
    required this.isHighlighted,
    required this.isBookmarked,
  });

  final QuranReaderPalette palette;
  final bool isHighlighted;
  final bool isBookmarked;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outline = isHighlighted
        ? palette.accent
        : isBookmarked
            ? palette.bookmarkBorder
            : palette.ornament;
    final fill = isHighlighted
        ? palette.activeAyahHighlight.withValues(alpha: .8)
        : isBookmarked
            ? palette.bookmarkHighlight
            : palette.highlight;
    final fillPaint = Paint()..color = fill;
    final linePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 1.3 : 1;

    // Fine scalloped medallion, matching the small ornamental verse markers
    // in a printed Mushaf while retaining the reader's adaptive palette.
    final medallion = Path();
    const scallopCount = 24;
    for (var point = 0; point < scallopCount; point++) {
      final angle = point * math.pi * 2 / scallopCount - math.pi / 2;
      final radius = point.isEven ? 11.5 : 9.9;
      final offset = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (point == 0) {
        medallion.moveTo(offset.dx, offset.dy);
      } else {
        medallion.lineTo(offset.dx, offset.dy);
      }
    }
    medallion.close();
    canvas.drawPath(medallion, fillPaint);
    canvas.drawPath(medallion, linePaint);
    canvas.drawCircle(center, 8.1, linePaint);
    canvas.drawCircle(
      center,
      6.8,
      Paint()
        ..color = outline.withValues(alpha: .68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65,
    );
    for (var petal = 0; petal < 8; petal++) {
      final angle = petal * math.pi / 4;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * 10.6,
          center.dy + math.sin(angle) * 10.6,
        ),
        .65,
        Paint()..color = outline,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerseMarkerPainter oldDelegate) =>
      oldDelegate.isHighlighted != isHighlighted ||
      oldDelegate.isBookmarked != isBookmarked ||
      oldDelegate.palette.background != palette.background ||
      oldDelegate.palette.ornament != palette.ornament ||
      oldDelegate.palette.accent != palette.accent ||
      oldDelegate.palette.highlight != palette.highlight ||
      oldDelegate.palette.activeAyahHighlight != palette.activeAyahHighlight ||
      oldDelegate.palette.bookmarkHighlight != palette.bookmarkHighlight ||
      oldDelegate.palette.bookmarkBorder != palette.bookmarkBorder;
}

