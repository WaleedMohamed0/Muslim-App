import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

/// A reusable, theme-aware Surah nameplate for Mushaf page openings.
///
/// The decoration is a standalone SVG; the title remains live Arabic text so
/// it uses the same Uthmanic font and Surah data as the rest of the reader.
class SurahNameHeader extends StatelessWidget {
  const SurahNameHeader({
    super.key,
    required this.surahName,
    required this.palette,
    this.fontSize = 21,
  });

  static const double _aspectRatio = 1000 / 120;

  final String surahName;
  final QuranReaderPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: _aspectRatio,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/features/quran/images/surah_header_frame.svg',
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(palette.ornament, BlendMode.srcIn),
            semanticsLabel: 'Traditional symmetrical Surah header frame',
          ),
        ),
        FractionallySizedBox(
          widthFactor: .43,
          heightFactor: .67,
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
      ],
    ),
  );
}
