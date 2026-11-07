import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

/// A traditional, dynamically titled nameplate for the opening of each Surah.
/// Its ink colors follow the selected Mushaf paper color.
class SurahNameHeader extends StatelessWidget {
  const SurahNameHeader({
    super.key,
    required this.surahName,
    required this.palette,
    this.fontSize = 21,
  });

  final String surahName;
  final QuranReaderPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    width: double.infinity,
    child: CustomPaint(
      painter: _SurahHeaderFramePainter(palette: palette),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .59,
          heightFactor: .72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.background,
              border: Border.all(color: palette.ornament, width: .9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'سُورَةُ $surahName',
                    maxLines: 1,
                    softWrap: false,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.metadata,
                      fontFamily: 'UthmanicHafs',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SurahHeaderFramePainter extends CustomPainter {
  const _SurahHeaderFramePainter({required this.palette});

  final QuranReaderPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = palette.ornament
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fineLine = Paint()
      ..color = palette.frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 2.5, size.width - 3, size.height - 5),
      const Radius.circular(5),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(4.5, 5.5, size.width - 9, size.height - 11),
      const Radius.circular(3),
    );
    canvas.drawRRect(outer, line);
    canvas.drawRRect(inner, fineLine);

    final sideWidth = math.min(size.width * .22, 72.0);
    _paintEndOrnament(
      canvas,
      width: sideWidth,
      height: size.height,
      paint: line,
    );
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    _paintEndOrnament(
      canvas,
      width: sideWidth,
      height: size.height,
      paint: line,
    );
    canvas.restore();
  }

  void _paintEndOrnament(
    Canvas canvas, {
    required double width,
    required double height,
    required Paint paint,
  }) {
    final centerY = height / 2;
    final usableWidth = math.max(0.0, width - 8);
    final path = Path()
      ..moveTo(7, centerY)
      ..cubicTo(13, centerY - 13, 18, centerY - 13, 24, centerY)
      ..cubicTo(18, centerY + 13, 13, centerY + 13, 7, centerY)
      ..moveTo(11, centerY)
      ..cubicTo(22, centerY - 5, 28, centerY - 14, 35, centerY - 7)
      ..cubicTo(40, centerY - 2, 34, centerY + 2, 35, centerY + 7)
      ..cubicTo(28, centerY + 14, 22, centerY + 5, 11, centerY)
      ..moveTo(22, centerY)
      ..cubicTo(31, centerY - 9, 40, centerY - 11, 47, centerY)
      ..cubicTo(40, centerY + 11, 31, centerY + 9, 22, centerY)
      ..moveTo(40, centerY)
      ..cubicTo(48, centerY - 6, 55, centerY - 6, 62, centerY)
      ..cubicTo(55, centerY + 6, 48, centerY + 6, 40, centerY);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(4, 4, usableWidth, height - 8));
    canvas.drawPath(path, paint);

    final nodePaint = Paint()..color = palette.ornament;
    for (final point in [
      Offset(7, centerY),
      Offset(22, centerY),
      Offset(35, centerY - 7),
      Offset(35, centerY + 7),
      Offset(47, centerY),
      Offset(62, centerY),
    ]) {
      canvas.drawCircle(point, 1.15, nodePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SurahHeaderFramePainter oldDelegate) =>
      oldDelegate.palette.background != palette.background ||
      oldDelegate.palette.ornament != palette.ornament ||
      oldDelegate.palette.frame != palette.frame;
}
