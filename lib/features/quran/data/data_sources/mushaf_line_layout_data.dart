import 'dart:convert';

import 'package:flutter/services.dart';

enum MushafLayoutLineType { text, surahName, basmallah, blank }

class MushafLayoutWord {
  const MushafLayoutWord({
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordPosition,
    required this.isAyahMarker,
  });

  final int surahNumber;
  final int ayahNumber;
  final int wordPosition;
  final bool isAyahMarker;
}

class MushafLayoutLine {
  const MushafLayoutLine({
    required this.type,
    this.isCentered = false,
    this.surahNumber,
    this.words = const <MushafLayoutWord>[],
  });

  final MushafLayoutLineType type;
  final bool isCentered;
  final int? surahNumber;
  final List<MushafLayoutWord> words;
}

/// The Madinah V2 line map contains layout metadata only. Quran display text
/// continues to come exclusively from [UthmaniQuranText].
abstract final class MushafLineLayoutData {
  static Map<int, List<MushafLayoutLine>>? _pages;
  static Map<int, List<Map<String, int>>>? _pageSections;
  static Map<(int, int), int>? _pageForAyah;

  static Future<void> initialize() async {
    if (_pages != null) return;

    final source = await rootBundle.loadString(
      'assets/features/quran/data/madinah-v2-line-layout.json',
    );
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final rawPages = decoded['pages'] as Map<String, dynamic>;
    if (rawPages.length != 604) {
      throw StateError('Invalid Madinah Mushaf page layout data.');
    }

    final pages = <int, List<MushafLayoutLine>>{};
    for (var pageNumber = 1; pageNumber <= 604; pageNumber++) {
      final rawLines = rawPages['$pageNumber'] as List<dynamic>?;
      if (rawLines == null || rawLines.length != 15) {
        throw StateError('Invalid line layout for Mushaf page $pageNumber.');
      }
      pages[pageNumber] = rawLines
          .map((rawLine) {
            final line = rawLine as Map<String, dynamic>;
            final type = switch (line['t']) {
              'text' => MushafLayoutLineType.text,
              'surah_name' => MushafLayoutLineType.surahName,
              'basmallah' => MushafLayoutLineType.basmallah,
              'blank' => MushafLayoutLineType.blank,
              _ =>
                throw StateError(
                  'Unknown Mushaf line type on page $pageNumber.',
                ),
            };
            final rawWords = line['w'] as List<dynamic>? ?? const <dynamic>[];
            final words = rawWords
                .map((rawWord) {
                  final word = rawWord as List<dynamic>;
                  if (word.length != 4) {
                    throw StateError(
                      'Invalid word position on Mushaf page $pageNumber.',
                    );
                  }
                  return MushafLayoutWord(
                    surahNumber: word[0] as int,
                    ayahNumber: word[1] as int,
                    wordPosition: word[2] as int,
                    isAyahMarker: word[3] == 1,
                  );
                })
                .toList(growable: false);
            return MushafLayoutLine(
              type: type,
              isCentered: line['c'] == 1,
              surahNumber: line['s'] as int?,
              words: words,
            );
          })
          .toList(growable: false);
    }
    final pageSections = <int, List<Map<String, int>>>{};
    final pageForAyah = <(int, int), int>{};
    for (var pageNumber = 1; pageNumber <= 604; pageNumber++) {
      final locations = <(int, int)>[];
      for (final line in pages[pageNumber]!) {
        for (final word in line.words) {
          final location = (word.surahNumber, word.ayahNumber);
          if (locations.isEmpty || locations.last != location) {
            locations.add(location);
          }
        }
      }

      final sections = <Map<String, int>>[];
      for (final (surahNumber, ayahNumber) in locations) {
        if (sections.isNotEmpty &&
            sections.last['surah'] == surahNumber &&
            sections.last['end']! + 1 == ayahNumber) {
          sections.last['end'] = ayahNumber;
        } else {
          sections.add({
            'surah': surahNumber,
            'start': ayahNumber,
            'end': ayahNumber,
          });
        }
      }
      pageSections[pageNumber] = sections;
      for (final section in sections) {
        final surahNumber = section['surah']!;
        for (var ayah = section['start']!; ayah <= section['end']!; ayah++) {
          final previousPage = pageForAyah[(surahNumber, ayah)];
          if (previousPage != null) {
            throw StateError(
              'Ayah $surahNumber:$ayah appears on pages '
              '$previousPage and $pageNumber in the Mushaf layout.',
            );
          }
          pageForAyah[(surahNumber, ayah)] = pageNumber;
        }
      }
    }
    if (pageForAyah.length != 6236) {
      throw StateError('Madinah Mushaf layout must cover all 6,236 ayahs.');
    }
    _pages = pages;
    _pageSections = pageSections;
    _pageForAyah = pageForAyah;
  }

  static List<MushafLayoutLine> page(int pageNumber) {
    final page = _pages?[pageNumber];
    if (page == null) {
      throw StateError(
        'Mushaf line layout is not available for page $pageNumber.',
      );
    }
    return page;
  }

  /// Page and ayah boundaries from the same edition as the line map.
  static List<Map<String, int>> pageData(int pageNumber) {
    final sections = _pageSections?[pageNumber];
    if (sections == null) {
      throw StateError(
        'Mushaf page data is not available for page $pageNumber.',
      );
    }
    return sections;
  }

  static int pageNumber(int surahNumber, int ayahNumber) {
    final page = _pageForAyah?[(surahNumber, ayahNumber)];
    if (page == null) {
      throw StateError(
        'Mushaf page is not available for $surahNumber:$ayahNumber.',
      );
    }
    return page;
  }
}
