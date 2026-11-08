import 'dart:async';
import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/data/repositories/quran_search_repository.dart';
import 'package:muslim/features/quran/domain/entities/quran_search_result.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';

class QuranVerseSearchScreen extends StatefulWidget {
  const QuranVerseSearchScreen({super.key});

  @override
  State<QuranVerseSearchScreen> createState() => _QuranVerseSearchScreenState();
}

class _QuranVerseSearchScreenState extends State<QuranVerseSearchScreen> {
  final _controller = TextEditingController();
  final _repository = QuranSearchRepository();
  Timer? _debounce;
  List<QuranSearchResult> _results = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _results = const []; _searching = false; _searched = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final results = await _repository.search(value);
      if (!mounted || value != _controller.text) return;
      setState(() { _results = results; _searching = false; _searched = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن آية أو جزء منها...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty ? null : IconButton(
                  onPressed: () { _controller.clear(); _onChanged(''); },
                  icon: const Icon(Icons.close_rounded),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: .55),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: _searching
              ? const Center(child: CircularProgressIndicator())
              : _results.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _resultCard(context, _results[index]),
                    )
                  : _emptyState(context)),
        ]),
      ),
    );
  }

  Widget _resultCard(BuildContext context, QuranSearchResult result) {
    final scheme = Theme.of(context).colorScheme;
    final query = QuranSearchRepository.normalizeArabic(_controller.text);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => SurahScreen(surahNumber: result.surahNumber, initialAyah: result.ayahNumber, highlightAyah: true),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _highlightedVerse(result.text, query, theme),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('سورة ${result.surahName}  •  الآية ${toArabicIndicDigits(result.ayahNumber)}', style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700))),
              Text('الجزء ${toArabicIndicDigits(result.juzNumber)}', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _highlightedVerse(String text, String query, ThemeData theme) {
    final normalized = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    var offset = 0;
    var previousSpace = false;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      final width = character.length;
      final isMark = RegExp(r'^[\u064B-\u065F\u0670\u06D6-\u06ED]$').hasMatch(character);
      if (!isMark) {
        final mapped = const {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي'}[character] ?? character;
        if (RegExp(r'\s').hasMatch(mapped)) {
          if (!previousSpace && normalized.isNotEmpty) {
            normalized.write(' ');
            starts.add(offset);
            ends.add(offset + width);
          }
          previousSpace = true;
        } else {
          for (final mappedRune in mapped.runes) {
            normalized.writeCharCode(mappedRune);
            starts.add(offset);
            ends.add(offset + width);
          }
          previousSpace = false;
        }
      }
      offset += width;
    }
    final matched = normalized.toString().trim();
    final matchStart = matched.indexOf(query);
    if (matchStart < 0 || query.isEmpty) {
      return Text(text, textAlign: TextAlign.justify, style: theme.textTheme.titleMedium?.copyWith(height: 2.0, fontSize: 20));
    }
    final start = starts[matchStart];
    final end = ends[matchStart + query.length - 1];
    return Text.rich(TextSpan(children: [
      TextSpan(text: text.substring(0, start)),
      TextSpan(text: text.substring(start, end), style: TextStyle(backgroundColor: theme.colorScheme.primaryContainer, color: theme.colorScheme.onPrimaryContainer)),
      TextSpan(text: text.substring(end)),
    ]), textAlign: TextAlign.justify, style: theme.textTheme.titleMedium?.copyWith(height: 2.0, fontSize: 20));
  }

  Widget _emptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final message = !_searched ? 'اكتب كلمة أو جزءًا من آية للبحث' : 'لم يتم العثور على نتائج';
    return Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_searched ? Icons.search_off_rounded : Icons.menu_book_rounded, size: 46, color: color.withValues(alpha: isDark ? .72 : .58)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color)),
      ]),
    ));
  }
}
