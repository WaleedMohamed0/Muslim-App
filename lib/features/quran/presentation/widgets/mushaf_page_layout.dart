part of 'mushaf_text_page.dart';

const _mushafBasmala = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

class _MushafBasmala extends StatelessWidget {
  const _MushafBasmala({required this.palette, required this.fontSize});

  final QuranReaderPalette palette;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    _mushafBasmala,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'UthmanicHafs',
      fontFeatures: const [
        FontFeature.enable('mark'),
        FontFeature.enable('mkmk'),
      ],
      fontSize: fontSize * 1.1,
      fontWeight: FontWeight.w700,
      height: 1.8,
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
      final sections = quran.getPageData(pageNumber).cast<Map>();
      final firstSection = sections.first;
      final firstSurah = (firstSection['surah'] as num).toInt();
      final firstVerse = (firstSection['start'] as num).toInt();
      final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
      final pageText = <Widget>[];
      final isFatihaOpening = pageNumber == 1 && firstSurah == 1;
      final isBaqarahOpening = pageNumber == 2 && firstSurah == 2;
      final isSurahOpening = isFatihaOpening || isBaqarahOpening;

      if (isSurahOpening) {
        pageText.add(
          SurahNameHeader(
            surahName: _arabicSurahName(firstSurah),
            palette: palette,
            fontSize: fontSize + 1,
          ),
        );
        pageText.add(const SizedBox(height: 14));
        if (isBaqarahOpening) {
          pageText.add(
            _MushafBasmala(palette: palette, fontSize: fontSize),
          );
          pageText.add(const SizedBox(height: 12));
        } else {
          pageText.add(const SizedBox(height: 8));
        }

        for (final section in sections) {
          final surahNumber = (section['surah'] as num).toInt();
          final startVerse = (section['start'] as num).toInt();
          final endVerse = (section['end'] as num).toInt();
          for (var verse = startVerse; verse <= endVerse; verse++) {
            pageText.add(
              _PageVerseText(
                surahNumber: surahNumber,
                startVerse: verse,
                endVerse: verse,
                palette: palette,
                fontSize: fontSize,
                highlightedSurahNumber: highlightedSurahNumber,
                highlightedAyahNumber: highlightedAyahNumber,
                bookmarkedAyahKeys: bookmarkedAyahKeys,
                separateBasmala: isBaqarahOpening &&
                    surahNumber == firstSurah,
                textAlign: TextAlign.center,
                onAyahLongPress: onAyahLongPress,
              ),
            );
            if (verse != endVerse) pageText.add(const SizedBox(height: 5));
          }
        }
      } else {
        for (final section in sections) {
          final surahNumber = (section['surah'] as num).toInt();
          final startVerse = (section['start'] as num).toInt();
          final endVerse = (section['end'] as num).toInt();
          if (startVerse == 1) {
            pageText.add(
              SurahNameHeader(
                surahName: _arabicSurahName(surahNumber),
                palette: palette,
                fontSize: fontSize + 1,
              ),
            );
            if (surahNumber != 1 && surahNumber != 9) {
              pageText.add(const SizedBox(height: 8));
              pageText.add(
                _MushafBasmala(palette: palette, fontSize: fontSize - 1),
              );
            }
            pageText.add(const SizedBox(height: 10));
          }

          pageText.add(
            _PageVerseText(
              surahNumber: surahNumber,
              startVerse: startVerse,
              endVerse: endVerse,
              palette: palette,
              fontSize: fontSize,
              highlightedSurahNumber: highlightedSurahNumber,
              highlightedAyahNumber: highlightedAyahNumber,
              bookmarkedAyahKeys: bookmarkedAyahKeys,
              separateBasmala:
                  startVerse == 1 && surahNumber != 1 && surahNumber != 9,
              onAyahLongPress: onAyahLongPress,
            ),
          );
        }
      }

      final horizontalInset = constraints.maxWidth < 380 ? 8.0 : 12.0;
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
              16,
              horizontalInset,
              6,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) => ClipRect(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.hardEdge,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: bodyConstraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: SizedBox(
                              width: bodyConstraints.maxWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _MushafRunningHeader(
                                    surahName: _arabicSurahName(firstSurah),
                                    juzNumber: juzNumber,
                                    palette: palette,
                                  ),
                                  const SizedBox(height: 12),
                                  ...pageText,
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Center(
                                      child: _MushafPageNumber(
                                        pageNumber: pageNumber,
                                        palette: palette,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

String _displayVerseText(
  int surahNumber,
  int verseNumber, {
  required bool separateBasmala,
}) {
  final verseText = UthmaniQuranText.getVerse(surahNumber, verseNumber);
  if (!separateBasmala ||
      verseNumber != 1 ||
      surahNumber == 1 ||
      surahNumber == 9) {
    return verseText;
  }
  final leadingText = verseText.trimLeft();
  final prefix = RegExp(r'^\S+\s+\S+\s+\S+\s+\S+').firstMatch(leadingText);
  if (prefix == null) return verseText;
  final basmalaWords = leadingText
      .substring(0, prefix.end)
      .split(RegExp(r'\s+'))
      .map(_normalizeBasmalaWord)
      .toList(growable: false);
  const expectedWords = ['بسم', 'الله', 'الرحمن', 'الرحيم'];
  if (basmalaWords.length != expectedWords.length) return verseText;
  for (var index = 0; index < expectedWords.length; index++) {
    if (basmalaWords[index] != expectedWords[index]) return verseText;
  }
  return leadingText.substring(prefix.end).trimLeft();
}

String _normalizeBasmalaWord(String word) => word
    .replaceAll(RegExp(r'[\u0640\u064B-\u065F\u0670]'), '')
    .replaceAll('ٱ', 'ا');

class _MushafRunningHeader extends StatelessWidget {
  static const _arabicJuzOrdinals = [
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع',
    'الثامن', 'التاسع', 'العاشر', 'الحادي عشر', 'الثاني عشر', 'الثالث عشر',
    'الرابع عشر', 'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر',
    'التاسع عشر', 'العشرون', 'الحادي والعشرون', 'الثاني والعشرون',
    'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون',
    'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
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
      Text(
        surahName,
        style: TextStyle(
          color: palette.metadata,
          fontFamily: 'UthmanicHafs',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      Text(
        'الجزء ${_arabicJuzOrdinals[juzNumber - 1]}',
        style: TextStyle(
          color: palette.metadata,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

