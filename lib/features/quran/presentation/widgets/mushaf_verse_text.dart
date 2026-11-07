part of 'mushaf_text_page.dart';

class _PageVerseText extends StatefulWidget {
  const _PageVerseText({
    required this.surahNumber,
    required this.startVerse,
    required this.endVerse,
    required this.palette,
    required this.fontSize,
    required this.highlightedSurahNumber,
    required this.highlightedAyahNumber,
    required this.bookmarkedAyahKeys,
    this.separateBasmala = false,
    required this.onAyahLongPress,
    this.textAlign = TextAlign.justify,
  });

  final int surahNumber;
  final int startVerse;
  final int endVerse;
  final QuranReaderPalette palette;
  final double fontSize;
  final int? highlightedSurahNumber;
  final int? highlightedAyahNumber;
  final Set<String> bookmarkedAyahKeys;
  final bool separateBasmala;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;
  final TextAlign textAlign;

  @override
  State<_PageVerseText> createState() => _PageVerseTextState();
}

class _PageVerseTextState extends State<_PageVerseText> {
  final Map<String, LongPressGestureRecognizer> _recognizers = {};

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final activeRecognizerKeys = <String>{};
    for (var verse = widget.startVerse; verse <= widget.endVerse; verse++) {
      final verseNumber = verse;
      final isHighlighted =
          widget.highlightedSurahNumber == widget.surahNumber &&
          widget.highlightedAyahNumber == verseNumber;
      final isBookmarked = widget.bookmarkedAyahKeys.contains(
        '${widget.surahNumber}:$verseNumber',
      );
      final key = '${widget.surahNumber}:$verseNumber';
      activeRecognizerKeys.add(key);
      final recognizer = _recognizers.putIfAbsent(
        key,
        () => LongPressGestureRecognizer(debugOwner: this),
      );
      recognizer.onLongPress =
          () => widget.onAyahLongPress(widget.surahNumber, verseNumber);
      spans.add(
        TextSpan(
          text: _displayVerseText(
            widget.surahNumber,
            verseNumber,
            separateBasmala: widget.separateBasmala,
          ),
          recognizer: recognizer,
          style: isHighlighted || isBookmarked
              ? TextStyle(
                  backgroundColor: isHighlighted
                      ? widget.palette.activeAyahHighlight.withValues(
                          alpha: .52,
                        )
                      : widget.palette.bookmarkHighlight,
                  decoration: isBookmarked ? TextDecoration.underline : null,
                  decorationColor: isBookmarked
                      ? widget.palette.bookmarkBorder
                      : null,
                  decorationThickness: isBookmarked ? 1.1 : null,
                )
              : null,
        ),
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress:
                () => widget.onAyahLongPress(
                  widget.surahNumber,
                  verseNumber,
                ),
            child: _VerseMarker(
              number: verseNumber,
              palette: widget.palette,
              isHighlighted: isHighlighted,
              isBookmarked: isBookmarked,
            ),
          ),
        ),
      );
      spans.add(
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(width: 0),
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
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: widget.textAlign,
      text: TextSpan(
        style: TextStyle(
          color: widget.palette.text,
          fontFamily: 'UthmanicHafs',
          fontFeatures: const [
            FontFeature.enable('mark'),
            FontFeature.enable('mkmk'),
          ],
          fontSize: widget.fontSize,
          fontWeight: Theme.of(context).brightness == Brightness.dark
              ? FontWeight.w500
              : FontWeight.w600,
          height: 1.55,
          wordSpacing: -4 * (widget.fontSize / 19),
        ),
        children: spans,
      ),
    );
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }
}

