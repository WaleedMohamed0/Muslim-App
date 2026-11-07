import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/assets/app_assets.dart';
import '../../domain/entities/story_record.dart';

class LocalStoriesRepository {
  LocalStoriesRepository._(this.chronologyNote, this.prophets, this.seerah);

  final String chronologyNote;
  final List<StoryRecord> prophets;
  final List<StoryRecord> seerah;
  static Future<LocalStoriesRepository>? _instance;
  static const _bookmarksKey = 'stories_bookmarks_v1';
  static const _progressKey = 'stories_reading_progress_v1';

  static Future<LocalStoriesRepository> load() =>
      _instance ??= _loadFromAssets();

  static Future<LocalStoriesRepository> _loadFromAssets() async {
    final raw = await rootBundle.loadString(AppAssets.storiesData);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    List<StoryRecord> records(String key) =>
        (json[key] as List<dynamic>)
            .map((item) => StoryRecord.fromJson(item as Map<String, dynamic>))
            .toList(growable: false)
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return LocalStoriesRepository._(
      json['chronologyNote'] as String? ?? '',
      records('prophets'),
      records('seerah'),
    );
  }

  Future<Set<String>> bookmarks() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_bookmarksKey) ?? const []).toSet();
  }

  Future<void> toggleBookmark(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = (preferences.getStringList(_bookmarksKey) ?? const []).toSet();
    if (!saved.add(id)) saved.remove(id);
    await preferences.setStringList(_bookmarksKey, saved.toList()..sort());
  }

  Future<int> progressFor(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_progressKey);
    if (saved == null) return 0;
    final progress = (jsonDecode(saved) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as int));
    return progress[id] ?? 0;
  }

  Future<void> saveProgress(String id, int chapterIndex) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_progressKey);
    final progress = saved == null
        ? <String, int>{}
        : (jsonDecode(saved) as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value as int));
    progress[id] = chapterIndex;
    await preferences.setString(_progressKey, jsonEncode(progress));
  }
}
