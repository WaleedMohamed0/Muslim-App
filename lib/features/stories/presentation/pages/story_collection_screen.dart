import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_widgets.dart';

import '../../data/repositories/local_stories_repository.dart';
import '../../domain/entities/story_record.dart';
import 'story_details_screen.dart';

class StoryCollectionScreen extends StatefulWidget {
  const StoryCollectionScreen({super.key, required this.isSeerah});
  final bool isSeerah;

  @override
  State<StoryCollectionScreen> createState() => _StoryCollectionScreenState();
}

class _StoryCollectionScreenState extends State<StoryCollectionScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _onlyBookmarks = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<LocalStoriesRepository>(
    future: LocalStoriesRepository.load(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: defaultAppBar(
            context: context,
            text: widget.isSeerah ? 'السيرة النبوية' : 'قصص الْأَنْبِيَاء',
          ),
          body: const Center(child: Text('تعذر تحميل المحتوى المحلي')),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final repository = snapshot.data!;
      final all = widget.isSeerah ? repository.seerah : repository.prophets;
      return Scaffold(
        appBar: defaultAppBar(
          context: context,
          text: widget.isSeerah ? 'السيرة النبوية' : 'قصص الْأَنْبِيَاء',
          actions: [
            IconButton(
              tooltip: _onlyBookmarks ? 'عرض الكل' : 'المحفوظات',
              onPressed: () => setState(() => _onlyBookmarks = !_onlyBookmarks),
              icon: Icon(
                _onlyBookmarks ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
            ),
          ],
        ),
        body: FutureBuilder<Set<String>>(
          future: repository.bookmarks(),
          builder: (context, bookmarkSnapshot) {
            final saved = bookmarkSnapshot.data ?? const <String>{};
            final query = _search.trim().toLowerCase();
            final stories = all.where((story) {
              final matchesText =
                  '${story.title} ${story.summary} ${story.date}'.toLowerCase().contains(query);
              return matchesText && (!_onlyBookmarks || saved.contains(story.id));
            }).toList(growable: false);
            return Column(
              children: [
                if (!widget.isSeerah && repository.chronologyNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
                    child: Text(
                      repository.chronologyNote,
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'ابحث في ${widget.isSeerah ? 'السيرة' : 'قصص الْأَنْبِيَاء'}',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                Expanded(
                  child: stories.isEmpty
                      ? const Center(child: Text('لا توجد نتائج'))
                      : ListView.builder(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return _StoryListCard(
                              story: story,
                              isBookmarked: saved.contains(story.id),
                              repository: repository,
                              onBookmark: () => setState(() {}),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _StoryListCard extends StatelessWidget {
  const _StoryListCard({
    required this.story,
    required this.isBookmarked,
    required this.repository,
    required this.onBookmark,
  });
  final StoryRecord story;
  final bool isBookmarked;
  final LocalStoriesRepository repository;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsetsDirectional.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
      title: Text(story.title, textDirection: TextDirection.rtl),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${story.date.isEmpty ? '' : '${story.date}\n'}${story.summary}',
          textDirection: TextDirection.rtl,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: IconButton(
        onPressed: () async {
          await repository.toggleBookmark(story.id);
          onBookmark();
        },
        icon: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
      ),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(name: '/stories/${story.id}'),
          builder: (_) => StoryDetailsScreen(story: story, repository: repository),
        ),
      ),
    ),
  );
}
