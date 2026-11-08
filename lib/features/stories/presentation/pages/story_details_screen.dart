import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_widgets.dart';

import '../../data/repositories/local_stories_repository.dart';
import '../../domain/entities/story_record.dart';

class StoryDetailsScreen extends StatefulWidget {
  const StoryDetailsScreen({super.key, required this.story, required this.repository});
  final StoryRecord story;
  final LocalStoriesRepository repository;

  @override
  State<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends State<StoryDetailsScreen> {
  int _chapterIndex = 0;
  double _fontSize = 19;
  double _lineHeight = 1.9;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final progress = await widget.repository.progressFor(widget.story.id);
    final bookmarks = await widget.repository.bookmarks();
    if (!mounted) return;
    setState(() {
      _chapterIndex = progress.clamp(0, widget.story.chapters.length - 1);
      _isBookmarked = bookmarks.contains(widget.story.id);
    });
    await widget.repository.saveProgress(widget.story.id, _chapterIndex);
  }

  Future<void> _moveTo(int index) async {
    final target = index.clamp(0, widget.story.chapters.length - 1);
    setState(() => _chapterIndex = target);
    await widget.repository.saveProgress(widget.story.id, target);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.chapters.isEmpty) {
      return Scaffold(
        appBar: defaultAppBar(context: context, text: widget.story.title),
      );
    }
    final chapter = widget.story.chapters[_chapterIndex];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: defaultAppBar(
        context: context,
        text: widget.story.title,
        actions: [
          IconButton(
            tooltip: 'حجم الخط وتباعده',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setSheetState) => Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('حجم الخط'),
                      Slider(
                        min: 16,
                        max: 30,
                        value: _fontSize,
                        label: _fontSize.round().toString(),
                        onChanged: (value) {
                          setState(() => _fontSize = value);
                          setSheetState(() {});
                        },
                      ),
                      const Text('تباعد الأسطر'),
                      Slider(
                        min: 1.5,
                        max: 2.3,
                        divisions: 8,
                        value: _lineHeight,
                        onChanged: (value) {
                          setState(() => _lineHeight = value);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.text_fields_rounded),
          ),
          IconButton(
            tooltip: _isBookmarked ? 'إزالة من المحفوظات' : 'حفظ القصة',
            onPressed: () async {
              await widget.repository.toggleBookmark(widget.story.id);
              if (mounted) setState(() => _isBookmarked = !_isBookmarked);
            },
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.story.summary, textDirection: TextDirection.rtl),
                ),
                Text('${_chapterIndex + 1}/${widget.story.chapters.length}'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 24),
              children: [
                Text(
                  chapter.title,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  chapter.content,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _fontSize,
                    height: _lineHeight,
                  ),
                ),
                if (chapter.events.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _StoryInfo(title: 'أحداث مهمة', text: chapter.events),
                ],
                const SizedBox(height: 18),
                _StoryInfo(title: 'دروس مستفادة', text: chapter.lessons),
                if (chapter.quranReferences.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReferenceList(
                    title: 'آيات قرآنية',
                    references: chapter.quranReferences,
                  ),
                ],
                if (chapter.hadithReferences.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReferenceList(
                    title: 'مراجع الحديث والسيرة',
                    references: chapter.hadithReferences,
                  ),
                ],
                if (chapter.historicalReferences.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ReferenceList(
                    title: 'مصادر السيرة والتاريخ',
                    references: chapter.historicalReferences,
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _chapterIndex > 0
                          ? () => _moveTo(_chapterIndex - 1)
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('السابق'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _chapterIndex + 1 < widget.story.chapters.length
                          ? () => _moveTo(_chapterIndex + 1)
                          : null,
                      iconAlignment: IconAlignment.end,
                      label: const Text('التالي'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryInfo extends StatelessWidget {
  const _StoryInfo({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
        ),
      ],
    ),
  );
}

class _ReferenceList extends StatelessWidget {
  const _ReferenceList({required this.title, required this.references});
  final String title;
  final List<String> references;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      for (final reference in references)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 4),
          child: Text(
            '• $reference',
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ),
    ],
  );
}
