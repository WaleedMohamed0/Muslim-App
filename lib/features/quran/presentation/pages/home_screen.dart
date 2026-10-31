import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/utils/arabic_digits.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_state.dart';
import 'package:untitled8/features/quran/presentation/widgets/surah_list.dart';
import 'package:untitled8/features/quran/presentation/pages/surah_screen.dart';
import 'package:untitled8/features/quran/domain/entities/quran_bookmark.dart';

import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bookmarkPromptShownForEntry = false;
  bool _bookmarkLoadStarted = false;
  final TextEditingController _surahSearchController = TextEditingController();
  String _surahSearchQuery = '';

  @override
  void dispose() {
    _surahSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBookmarkAndPrompt();
  }

  Future<void> _loadBookmarkAndPrompt() async {
    final cubit = context.read<QuranCubit>();
    try {
      if (cubit.bookmark == null && !_bookmarkLoadStarted) {
        _bookmarkLoadStarted = true;
        await cubit.initialize();
      }
    } catch (_) {
      return;
    }
    if (!mounted || _bookmarkPromptShownForEntry) return;
    _bookmarkPromptShownForEntry = true;
    final bookmark = cubit.bookmark;
    if (bookmark == null) return;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            icon: Icon(
              Icons.bookmark_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('متابعة القراءة؟'),
            content: Text(
              'آخر موضع قراءة: سورة ${bookmark.surahName}، الآية ${toArabicIndicDigits(bookmark.pageNumber)}',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('البدء من جديد'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  unawaited(_continueReading(cubit, bookmark));
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('متابعة القراءة'),
              ),
            ],
          ),
    );
  }

  Future<void> _continueReading(
    QuranCubit cubit,
    QuranBookmark bookmark,
  ) async {
    await cubit.selectSurah(
      bookmark.surahNumber,
      bookmark.surahName,
      online: cubit.isOnline,
    );
    cubit.setCurrentPageNumber(bookmark.pageNumber);
    if (!mounted) return;
    navigateTo(context, SurahScreen(surahNumber: bookmark.surahNumber));
  }

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<QuranCubit>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerForeground =
        isDark ? scheme.onPrimaryContainer : scheme.onPrimary;
    final bannerColors =
        isDark
            ? [scheme.primaryContainer, scheme.surfaceContainerHigh]
            : [scheme.primary, scheme.primary.withValues(alpha: .78)];
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        return Scaffold(
          appBar: defaultAppBar(
            context: context,
            text: "القراّن الكريم",
            onBack: () {
              if (cubit.isPlaying) cubit.togglePlay();
              Navigator.pop(context);
            },
          ),
          body: myPanel(
            screen: WillPopScope(
              onWillPop: () async {
                if (cubit.isPlaying) {
                  cubit.togglePlay();
                }
                return true;
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      18,
                      8,
                      18,
                      12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        gradient: LinearGradient(
                          colors: bannerColors,
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            color: bannerForeground,
                            size: 34,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'اقرأ بتدبّر وطمأنينة',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: bannerForeground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.spa_outlined,
                            color: bannerForeground.withValues(alpha: .78),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'السور',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '١١٤ سورة',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                    child: TextField(
                      controller: _surahSearchController,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _surahSearchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن سورة',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _surahSearchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () {
                                  _surahSearchController.clear();
                                  setState(() => _surahSearchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SurahList(
                      cubit: cubit,
                      online: cubit.isOnline,
                      searchQuery: _surahSearchQuery,
                    ),
                  ),
                ],
              ),
            ),
            context: context,
            cubit: cubit,
          ),
        );
      },
    );
  }
}
