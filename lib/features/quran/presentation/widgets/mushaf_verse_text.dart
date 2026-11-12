part of 'mushaf_text_page.dart';

class _PageVerseText extends StatefulWidget {
  const _PageVerseText({
    required this.words,
    required this.isCentered,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
    required this.highlightedSurahNumber,
    required this.highlightedAyahNumber,
    required this.bookmarkedAyahKeys,
    required this.onAyahLongPress,
  });

  final List<MushafLayoutWord> words;
  final bool isCentered;
  final QuranReaderPalette palette;
  final double fontSize;
  final double lineHeight;
  final int? highlightedSurahNumber;
  final int? highlightedAyahNumber;
  final Set<String> bookmarkedAyahKeys;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;

  @override
  State<_PageVerseText> createState() => _PageVerseTextState();
}

class _PageVerseTextState extends State<_PageVerseText> {
  final Map<String, LongPressGestureRecognizer> _recognizers = {};

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final activeRecognizerKeys = <String>{};
      final items = <_MushafLineItem>[];
      final baseStyle = TextStyle(
        color: widget.palette.text,
        fontFamily: 'UthmanicHafs',
        fontFeatures: const [
          FontFeature.enable('mark'),
          FontFeature.enable('mkmk'),
        ],
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w500,
        height: widget.lineHeight,
      );
      // Mushaf typography is fixed to the page design; device accessibility
      // text scaling must not make one page differ from another.
      const textScaler = TextScaler.noScaling;

      for (final word in widget.words) {
        final key = '${word.surahNumber}:${word.ayahNumber}';
        activeRecognizerKeys.add(key);
        final recognizer = _recognizers.putIfAbsent(
          key,
          () => LongPressGestureRecognizer(debugOwner: this),
        );
        recognizer.onLongPress =
            () => widget.onAyahLongPress(word.surahNumber, word.ayahNumber);

        if (word.isAyahMarker) {
          items.add(
            _MushafLineItem(
              // The medallion is 29px wide; keep its layout box at that
              // width so the surrounding word gaps stay close to the print.
              width: 29,
              build: () => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: recognizer.onLongPress,
                    child: _VerseMarker(
                        number: word.ayahNumber,
                        palette: widget.palette,
                        isHighlighted:
                            widget.highlightedSurahNumber == word.surahNumber &&
                            widget.highlightedAyahNumber == word.ayahNumber,
                        isBookmarked: widget.bookmarkedAyahKeys.contains(key),
                    ),
                  ),
            ),
          );
          continue;
        }

        final sourceWords = _mushafSourceWords(
          word.surahNumber,
          word.ayahNumber,
        );
        if (word.wordPosition < 1 || word.wordPosition > sourceWords.length) {
          throw StateError(
            'Mushaf layout references missing word '
            '${word.surahNumber}:${word.ayahNumber}:${word.wordPosition}.',
          );
        }
        final text = sourceWords[word.wordPosition - 1];
        final isHighlighted =
            widget.highlightedSurahNumber == word.surahNumber &&
            widget.highlightedAyahNumber == word.ayahNumber;
        final isBookmarked = widget.bookmarkedAyahKeys.contains(key);
        final textStyle = baseStyle.copyWith(
          backgroundColor:
              isHighlighted
                  ? widget.palette.activeAyahHighlight.withValues(alpha: .52)
                  : isBookmarked
                  ? widget.palette.bookmarkHighlight
                  : null,
          decoration: isBookmarked ? TextDecoration.underline : null,
          decorationColor: isBookmarked ? widget.palette.bookmarkBorder : null,
          decorationThickness: isBookmarked ? 1.1 : null,
        );
        final painter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: TextDirection.rtl,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        items.add(
          _MushafLineItem(
            width: painter.width,
              build: () => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: recognizer.onLongPress,
                  child: Text(
                    text,
                    maxLines: 1,
                    softWrap: false,
                    textDirection: TextDirection.rtl,
                    textScaler: textScaler,
                    style: textStyle,
                  ),
                ),
          ),
        );
      }

      final staleKeys =
          _recognizers.keys
              .where((key) => !activeRecognizerKeys.contains(key))
              .toList();
      for (final key in staleKeys) {
        _recognizers.remove(key)?.dispose();
      }
      if (items.isEmpty || constraints.maxWidth <= 0) {
        return const SizedBox.shrink();
      }

      const minimumGap = 0.0;
      final gapCount = items.length - 1;
      final naturalWidth =
          items.fold<double>(0, (sum, item) => sum + item.width) +
          minimumGap * gapCount;
      final extraGap =
          widget.isCentered || gapCount == 0
              ? 0.0
              : math.max(0.0, (constraints.maxWidth - naturalWidth) / gapCount);
      final children = <Widget>[];
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        children.add(
          SizedBox(
            width: item.width,
            child: Center(child: item.build()),
          ),
        );
        if (index < gapCount) {
          children.add(SizedBox(width: minimumGap + extraGap));
        }
      }

      final line = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );

      // Keep every Quran line at the shared Mushaf font size. The Madinah
      // line map supplies the line breaks, so avoid scaling individual lines
      // to compensate for a width mismatch.
      final alignment = widget.isCentered
          ? Alignment.center
          : AlignmentDirectional.centerStart;
      final lineContent = SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          // The Madinah line map is designed for a reference page width.
          // On narrower or fractional-width screens, scale only the rare
          // line that cannot fit instead of letting its Row overflow.
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: line,
        ),
      );

      return Directionality(
        textDirection: TextDirection.rtl,
        child: lineContent,
      );
    },
  );

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }
}

class _MushafLineItem {
  const _MushafLineItem({required this.width, required this.build});

  final double width;
  final Widget Function() build;
}

final Map<(int, int), List<String>> _sourceWordCache = {};

/// Resolves layout word positions against the bundled Quran text without
/// changing its source characters. Only word boundaries are adapted where
/// this Unicode file groups/splits a word differently from the Madinah map.
List<String> _mushafSourceWords(
  int surahNumber,
  int ayahNumber,
) => _sourceWordCache.putIfAbsent((surahNumber, ayahNumber), () {
  final rawWords = UthmaniQuranText.getVerse(
    surahNumber,
    ayahNumber,
  ).split(' ');
  final words = <String>[];
  for (var index = 0; index < rawWords.length; index++) {
    final word = rawWords[index];
    if (word == '\u06de' && index + 1 < rawWords.length) {
      // Keep this Quranic annotation and its original separating space
      // attached to the next word so it remains in the displayed text.
      words.add('$word ${rawWords[++index]}');
    } else {
      words.add(word);
    }
  }

  if (surahNumber == 2 && ayahNumber == 1) {
    // The source stores the opening basmala in 2:1; the page layout has
    // its own basmala row, so this ayah's positioned word is only Alif-Lam-Mim.
    return words.skip(4).toList(growable: false);
  }
  if (surahNumber == 15 && ayahNumber == 7) {
    // The Madinah word map places لَّوْ and مَا separately. The bundled
    // Unicode source writes their characters together; partition at the
    // existing meem without inserting, deleting, or replacing a character.
    final combined = words[0];
    final splitAt = combined.indexOf('م');
    if (splitAt > 0) {
      words
        ..[0] = combined.substring(0, splitAt)
        ..insert(1, combined.substring(splitAt));
    }
  }
  if (surahNumber == 37 && ayahNumber == 130 && words.length == 4) {
    // The source has a space inside one calligraphic word; retain the
    // complete original substring as the single mapped layout word.
    words[2] = '${words[2]} ${words.removeAt(3)}';
  }
  return words;
});
