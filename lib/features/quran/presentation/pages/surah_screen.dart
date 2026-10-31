import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_state.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({super.key, required this.surahNumber});
  final int surahNumber;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late final QuranCubit _cubit;
  late final String _surahName;
  late final PageController _pageController;
  late List<List<int>> _versePages;
  double _fontSize = 27;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<QuranCubit>();
    final rawName = quran.getSurahNameArabic(widget.surahNumber);
    _surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    _versePages = _paginateVerses();
    final bookmarkedVerse = _cubit.bookmark?.surahNumber == widget.surahNumber
        ? _cubit.bookmark!.pageNumber.clamp(1, quran.getVerseCount(widget.surahNumber)).toInt()
        : 1;
    _pageIndex = _pageForVerse(bookmarkedVerse);
    _pageController = PageController(initialPage: _pageIndex);
    _cubit.setSurahInfo(widget.surahNumber, _surahName);
    _cubit.setCurrentPageNumber(bookmarkedVerse);
  }

  List<List<int>> _paginateVerses() {
    final total = quran.getVerseCount(widget.surahNumber);
    final pages = <List<int>>[];
    var currentPage = <int>[];
    var currentLength = 0;
    final targetLength = (380 * (27 / _fontSize)).round();
    for (var verse = 1; verse <= total; verse++) {
      final length = quran.getVerse(widget.surahNumber, verse).length;
      if (currentPage.isNotEmpty && currentLength + length > targetLength) {
        pages.add(currentPage);
        currentPage = <int>[];
        currentLength = 0;
      }
      currentPage.add(verse);
      currentLength += length;
    }
    if (currentPage.isNotEmpty) pages.add(currentPage);
    return pages;
  }

  int _pageForVerse(int verse) => _versePages.indexWhere((page) => page.contains(verse)).clamp(0, _versePages.length - 1).toInt();

  void _changeFontSize(double value) {
    final currentVerse = _cubit.currentPageNumber;
    setState(() {
      _fontSize = value.clamp(19, 42);
      _versePages = _paginateVerses();
      _pageIndex = _pageForVerse(currentVerse);
      _pageController.jumpToPage(_pageIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<QuranCubit, QuranState>(
        builder: (context, state) {
          final isBookmarked = _cubit.bookmark?.surahNumber == widget.surahNumber &&
              _cubit.bookmark?.pageNumber == _cubit.currentPageNumber;
          return Scaffold(
            appBar: AppBar(
              title: Column(
                children: [
                  Text(_surahName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('سورة ${widget.surahNumber}', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'حفظ موضع القراءة',
                  onPressed: () => _cubit.toggleBookmark(_surahName),
                  icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                ),
                playIconButton(cubit: _cubit, surahNumber: widget.surahNumber, context: context),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  _ReaderControls(
                    fontSize: _fontSize,
                    onDecrease: () => _changeFontSize(_fontSize - 2),
                    onIncrease: () => _changeFontSize(_fontSize + 2),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      reverse: Directionality.of(context) == TextDirection.rtl,
                      itemCount: _versePages.length,
                      onPageChanged: (index) {
                        setState(() => _pageIndex = index);
                        _cubit.setCurrentPageNumber(_versePages[index].first);
                      },
                      itemBuilder: (context, index) => _ReaderPage(
                        key: ValueKey('reader-$index-$_fontSize'),
                        surahName: _surahName,
                        surahNumber: widget.surahNumber,
                        verses: _versePages[index],
                        fontSize: _fontSize,
                        currentVerse: _cubit.currentPageNumber,
                        onVerseTap: _cubit.setCurrentPageNumber,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Text('الآية ${_versePages[_pageIndex].first} – ${_versePages[_pageIndex].last}',
                            style: Theme.of(context).textTheme.labelMedium),
                        const Spacer(),
                        Text('${_pageIndex + 1} / ${_versePages.length}',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(width: 8),
                        Icon(Icons.swipe, size: 18, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _ReaderControls extends StatelessWidget {
  const _ReaderControls({required this.fontSize, required this.onDecrease, required this.onIncrease});
  final double fontSize;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('حجم الخط', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            IconButton.filledTonal(onPressed: onDecrease, tooltip: 'تصغير الخط', icon: const Icon(Icons.remove)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(fontSize.toInt().toString(), style: Theme.of(context).textTheme.labelLarge),
            ),
            IconButton.filledTonal(onPressed: onIncrease, tooltip: 'تكبير الخط', icon: const Icon(Icons.add)),
          ],
        ),
      );
}

class _ReaderPage extends StatelessWidget {
  const _ReaderPage({super.key, required this.surahName, required this.surahNumber, required this.verses, required this.fontSize, required this.currentVerse, required this.onVerseTap});
  final String surahName;
  final int surahNumber;
  final List<int> verses;
  final double fontSize;
  final int currentVerse;
  final ValueChanged<int> onVerseTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            children: [
              if (verses.first == 1) ...[
                _SurahHeading(surahName: surahName, number: surahNumber),
                if (surahNumber != 1 && surahNumber != 9) ...[
                  const SizedBox(height: 18),
                  Text(quran.basmala, textDirection: TextDirection.rtl,
                      style: TextStyle(fontFamily: 'QuranFont', fontSize: fontSize * .85, color: colors.primary)),
                  const SizedBox(height: 18),
                ],
              ],
              for (final verse in verses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => onVerseTap(verse),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RichText(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          style: TextStyle(fontFamily: 'QuranFont', fontSize: fontSize, height: 2.05, color: colors.onSurface),
                          children: [
                            TextSpan(text: quran.getVerse(surahNumber, verse)),
                            const WidgetSpan(alignment: PlaceholderAlignment.middle, child: SizedBox(width: 7)),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: _VerseNumber(number: verse, highlighted: currentVerse == verse),
                            ),
                            const WidgetSpan(alignment: PlaceholderAlignment.middle, child: SizedBox(width: 7)),
                          ],
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
  }
}

class _VerseNumber extends StatelessWidget {
  const _VerseNumber({required this.number, required this.highlighted});
  final int number;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? colors.primary : colors.primaryContainer,
        border: Border.all(color: colors.primary.withValues(alpha: .65)),
      ),
      child: Text('$number', style: TextStyle(fontFamily: 'QuranFont', fontSize: 12, color: highlighted ? colors.onPrimary : colors.onPrimaryContainer, fontWeight: FontWeight.w700)),
    );
  }
}

class _SurahHeading extends StatelessWidget {
  const _SurahHeading({required this.surahName, required this.number});
  final String surahName;
  final int number;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(surahName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('سورة رقم $number', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
}
