import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_state.dart';
import 'package:untitled8/features/quran/presentation/widgets/surah_list.dart';
import 'package:untitled8/features/quran/presentation/widgets/juz_list.dart';
import 'package:untitled8/features/quran/presentation/widgets/saved_bookmarks_dialog.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_browse_mode_switcher.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_search_field.dart';

import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _surahSearchController = TextEditingController();
  final ValueNotifier<double> _miniPlayerHeight = ValueNotifier(0);
  String _surahSearchQuery = '';
  bool _showJuzView = false;

  @override
  void dispose() {
    _surahSearchController.dispose();
    _miniPlayerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<QuranCubit>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
            actions: [
              IconButton(
                tooltip: isArabic ? 'العلامات المرجعية' : 'Saved bookmarks',
                onPressed: () => unawaited(
                  SavedBookmarksDialog.show(context, cubit),
                ),
                icon: const Icon(Icons.bookmarks_outlined),
              ),
            ],
          ),
          body: myPanel(
            screen: Column(
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
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
                    child: QuranBrowseModeSwitcher(
                      showJuzView: _showJuzView,
                      isArabic: isArabic,
                      onChanged: (showJuzView) => setState(() {
                        _showJuzView = showJuzView;
                        _surahSearchController.clear();
                        _surahSearchQuery = '';
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          _showJuzView
                              ? (isArabic ? 'الأجزاء' : 'Juz')
                              : (isArabic ? 'السور' : 'Surahs'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          _showJuzView
                              ? (isArabic ? '٣٠ جزءًا' : '30 Juz')
                              : (isArabic ? '١١٤ سورة' : '114 Surahs'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                    child: QuranSearchField(
                      controller: _surahSearchController,
                      query: _surahSearchQuery,
                      hintText: _showJuzView
                          ? (isArabic ? 'ابحث عن جزء أو سورة' : 'Search Juz or Surah')
                          : (isArabic ? 'ابحث عن سورة' : 'Search Surah'),
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      clearTooltip: isArabic ? 'مسح البحث' : 'Clear search',
                      onChanged: (value) => setState(() => _surahSearchQuery = value),
                      onClear: () {
                        _surahSearchController.clear();
                        setState(() => _surahSearchQuery = '');
                      },
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _showJuzView
                          ? JuzList(
                              key: const ValueKey('juz-list'),
                              cubit: cubit,
                              online: cubit.isOnline,
                              searchQuery: _surahSearchQuery,
                              miniPlayerHeight: _miniPlayerHeight,
                            )
                          : SurahList(
                              key: const ValueKey('surah-list'),
                              cubit: cubit,
                              online: cubit.isOnline,
                              searchQuery: _surahSearchQuery,
                              miniPlayerHeight: _miniPlayerHeight,
                            ),
                    ),
                  ),
                ],
            ),
            context: context,
            cubit: cubit,
            onMiniPlayerHeightChanged: (height) {
              if (!mounted || (_miniPlayerHeight.value - height).abs() < .5) {
                return;
              }
              _miniPlayerHeight.value = height;
            },
          ),
        );
      },
    );
  }
}
