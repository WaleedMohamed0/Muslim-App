import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_state.dart';
import 'package:muslim/features/azkar/domain/entities/azkar_entry.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_state.dart';

import '../../../../core/widgets/app_widgets.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_text_card.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_section_header.dart';

class AzkarAndHadeethScreen extends StatefulWidget {
  const AzkarAndHadeethScreen({super.key, required this.index});
  final int index;

  @override
  State<AzkarAndHadeethScreen> createState() => _AzkarAndHadeethScreenState();
}

class _AzkarAndHadeethScreenState extends State<AzkarAndHadeethScreen> {
  final TextEditingController _duaSearchController = TextEditingController();
  String _duaSearch = '';
  String _selectedDuaCategory = 'الكل';
  late final String title = switch (widget.index) {
    0 => 'أَذْكَارُ الصَّبَاحِ',
    1 => 'أَذْكَارُ المساءِ',
    2 => 'أَذْكَارُ النَوْم',
    3 => 'أذكار الاستيقاظ',
    4 => 'أذكار ما بعد الصَّلَاة',
    5 => 'التسابيح',
    6 => 'أدعية قرآنية',
    7 => 'أدعية الْأَنْبِيَاء',
    8 => 'أدعية من السُّنَّة النبوية',
    9 => 'أدعية للمواقف اليومية',
    _ => 'الْأَحَادِيث النبوية',
  };

  @override
  void initState() {
    super.initState();
    if (widget.index != 10) {
      context.read<AzkarCubit>().loadContent();
    }
    if (widget.index == 10) context.read<HadeethCubit>().getHadeeth();
  }

  @override
  void dispose() {
    _duaSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.index;
    if (category == 10) {
      return BlocBuilder<HadeethCubit, HadeethState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: defaultAppBar(context: context, text: title),
            body: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      itemCount: state.entries.isEmpty
                          ? 2
                          : state.entries.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return AzkarSectionHeader(
                            isHadith: true,
                            totalCount: state.entries.length,
                          );
                        }
                        if (state.entries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                state.error ?? 'لا توجد بيانات للعرض',
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final entry = state.entries[index - 1];
                        return AzkarTextCard(
                          text: entry.text,
                          onCopy:
                              () => Clipboard.setData(
                                ClipboardData(text: entry.text),
                              ),
                          onTap:
                              () => awesomeDialog(
                                context,
                                title,
                                entry.explanation,
                              ),
                        );
                      },
                    ),
          );
        },
      );
    }

    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) {
        final cubit = context.read<AzkarCubit>();
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.error != null) {
          return Scaffold(
            appBar: defaultAppBar(context: context, text: title),
            body: Center(child: Text(state.error!)),
          );
        }
        final allEntries = state.entriesFor(category);
        final duaCategories = <String>[
          'الكل',
          ...allEntries
              .map((entry) => entry.subCategory)
              .where((name) => name.isNotEmpty)
              .toSet(),
        ];
        final normalizedQuery = _duaSearch.trim().toLowerCase();
        final entries = category == 9
            ? allEntries.where((entry) {
                final matchesCategory = _selectedDuaCategory == 'الكل' ||
                    entry.subCategory == _selectedDuaCategory;
                final searchable =
                    '${entry.content} ${entry.instructions} ${entry.reference} ${entry.subCategory}'
                        .toLowerCase();
                return matchesCategory && searchable.contains(normalizedQuery);
              }).toList(growable: false)
            : allEntries;
        return Scaffold(
          appBar: defaultAppBar(context: context, text: title),
          body:
              category == 9
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            12,
                            16,
                            4,
                          ),
                          child: TextField(
                            controller: _duaSearchController,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            onChanged: (value) =>
                                setState(() => _duaSearch = value),
                            decoration: InputDecoration(
                              hintText: 'ابحث في الْأَدْعِيَة',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _duaSearch.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'مسح البحث',
                                      onPressed: () {
                                        _duaSearchController.clear();
                                        setState(() => _duaSearch = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: duaCategories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final name = duaCategories[index];
                              return ChoiceChip(
                                label: Text(name),
                                selected: _selectedDuaCategory == name,
                                onSelected: (_) => setState(
                                  () => _selectedDuaCategory = name,
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: entries.isEmpty
                              ? const Center(child: Text('لا توجد نتائج'))
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  itemCount: entries.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return AzkarSectionHeader(
                                        isHadith: false,
                                        totalCount: allEntries.length,
                                      );
                                    }
                                    final entry = entries[index - 1];
                                    return AzkarTextCard(
                                      text: entry.content,
                                      sectionLabel: entry.subCategory,
                                      repetitionCount: entry.repetitionCount,
                                      counter: cubit.progressFor(entry),
                                      reference: entry.verified
                                          ? _entryReference(entry)
                                          : null,
                                      instructions: entry.verified
                                          ? entry.instructions
                                          : null,
                                      onCopy: () => Clipboard.setData(
                                        ClipboardData(text: entry.content),
                                      ),
                                      onIncrement: () =>
                                          cubit.incrementEntry(entry),
                                      onReset: () => cubit.resetEntry(entry),
                                    );
                                  },
                                ),
                        ),
                      ],
                    )
                  : entries.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount: entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return AzkarSectionHeader(
                          isHadith: false,
                          totalCount: entries.length,
                        );
                      }
                      final itemIndex = index - 1;
                      final entry = entries[itemIndex];
                      final text = entry.content;
                      return AzkarTextCard(
                        text: text,
                        repetitionCount: entry.repetitionCount,
                        counter: cubit.progressFor(entry),
                        reference: entry.verified
                            ? _entryReference(entry)
                            : null,
                        instructions: entry.verified ? entry.instructions : null,
                        onCopy:
                            () => Clipboard.setData(ClipboardData(text: text)),
                        onIncrement: () => cubit.incrementEntry(entry),
                        onReset: () => cubit.resetEntry(entry),
                      );
                    },
                  ),
        );
      },
    );
  }

  String _entryReference(AzkarEntry entry) => entry.authenticityGrade.isEmpty
      ? entry.reference
      : '${entry.reference} — ${entry.authenticityGrade}';

}
