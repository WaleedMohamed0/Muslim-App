part of 'mushaf_text_page.dart';

String _mushafBasmalaText() =>
    UthmaniQuranText.getVerse(2, 1).split(' ').take(4).join(' ');

class _MushafBasmala extends StatelessWidget {
  const _MushafBasmala({required this.palette, required this.fontSize});

  final QuranReaderPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    _mushafBasmalaText(),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'UthmanicHafs',
      fontFeatures: const [
        FontFeature.enable('mark'),
        FontFeature.enable('mkmk'),
      ],
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      height: 1.55,
      color: palette.text,
    ),
  );
}

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent({
    required this.pageNumber,
    required this.palette,
    required this.fontSize,
    required this.highlightedSurahNumber,
    required this.highlightedAyahNumber,
    required this.bookmarkedAyahKeys,
    required this.onAyahLongPress,
  });

  final int pageNumber;
  final QuranReaderPalette palette;
  final double fontSize;
  final int? highlightedSurahNumber;
  final int? highlightedAyahNumber;
  final Set<String> bookmarkedAyahKeys;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sections = MushafLineLayoutData.pageData(pageNumber);
      final firstSection = sections.first;
      final firstSurah = (firstSection['surah'] as num).toInt();
      final firstVerse = (firstSection['start'] as num).toInt();
      final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
      // Keep the text comfortably balanced inside the Mushaf frame while
      // leaving enough room for long rows at the fixed font size.
      // Leave a little extra room for the widest Arabic lines and header text
      // on fractional-width screens, where an exact fit can round outward.
      const horizontalInset = 8.5;
      const verseLineHeight = 1.55;
      final pageRows = <({Widget child, bool flexible})>[];
      var openingBlankLinesToSkip = pageNumber <= 2 ? 1 : 0;
      for (final line in MushafLineLayoutData.page(pageNumber)) {
        switch (line.type) {
          case MushafLayoutLineType.surahName:
            final surahNumber = line.surahNumber!;
            pageRows.add((
              child: SurahNameHeader(
                surahName: _arabicSurahName(surahNumber),
                palette: palette,
                fontSize: fontSize + 1,
              ),
              flexible: true,
            ));
            if (pageNumber <= 2) {
              pageRows.add((child: const SizedBox(height: 8), flexible: false));
            }
          case MushafLayoutLineType.basmallah:
            pageRows.add((
              child: _MushafBasmala(palette: palette, fontSize: fontSize),
              flexible: true,
            ));
          case MushafLayoutLineType.blank:
            if (openingBlankLinesToSkip > 0) {
              openingBlankLinesToSkip--;
            } else {
              pageRows.add((child: const SizedBox.expand(), flexible: true));
            }
          case MushafLayoutLineType.text:
            pageRows.add((
              child: _PageVerseText(
                words: line.words,
                isCentered: line.isCentered,
                palette: palette,
                fontSize: fontSize,
                lineHeight: verseLineHeight,
                highlightedSurahNumber: highlightedSurahNumber,
                highlightedAyahNumber: highlightedAyahNumber,
                bookmarkedAyahKeys: bookmarkedAyahKeys,
                onAyahLongPress: onAyahLongPress,
              ),
              flexible: true,
            ));
        }
      }

      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          // This is the Mushaf paper itself; use the reader-specific color
          // selected in Settings rather than the app's generic card surface.
          color: palette.background,
          border: Border.all(color: palette.frame, width: 1.4),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: palette.frame.withValues(alpha: .6)),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontalInset,
              8,
              horizontalInset,
              6,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 38,
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      final content = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MushafRunningHeader(
                            surahName: _arabicSurahName(firstSurah),
                            juzNumber: juzNumber,
                            palette: palette,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final row in pageRows)
                                  if (row.flexible)
                                    Expanded(
                                      child: Center(child: row.child),
                                    )
                                  else
                                    row.child,
                              ],
                            ),
                          ),
                        ],
                      );
                      return SizedBox(
                        width: bodyConstraints.maxWidth,
                        height: bodyConstraints.maxHeight,
                        child: content,
                      );
                    },
                  ),
                ),
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Center(
                      child: _MushafPageNumber(
                        pageNumber: pageNumber,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _arabicSurahName(int surahNumber) {
  final name = UthmaniQuranText.getSurahName(surahNumber);
  return name == 'اللهب' ? 'المسد' : name;
}

class _MushafRunningHeader extends StatelessWidget {
  static const _arabicJuzOrdinals = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];

  const _MushafRunningHeader({
    required this.surahName,
    required this.juzNumber,
    required this.palette,
  });

  final String surahName;
  final int juzNumber;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.rtl,
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            surahName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.metadata,
              fontFamily: 'UthmanicHafs',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'الجزء ${_arabicJuzOrdinals[juzNumber - 1]}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: palette.metadata,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}
