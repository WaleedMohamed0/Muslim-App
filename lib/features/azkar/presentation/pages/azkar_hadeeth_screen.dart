import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:muslim/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_state.dart';
import 'package:muslim/features/azkar/domain/entities/azkar_entry.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_state.dart';

import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/external_link_button.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_text_card.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_section_header.dart';

class AzkarAndHadeethScreen extends StatefulWidget {
  const AzkarAndHadeethScreen({super.key, required this.index});
  final int index;

  @override
  State<AzkarAndHadeethScreen> createState() => _AzkarAndHadeethScreenState();
}

class _AzkarAndHadeethScreenState extends State<AzkarAndHadeethScreen> {
  bool _completionDialogShown = false;
  bool _completionBaselineEstablished = false;
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
                          reference: entry.citation,
                          onCopy:
                              () => Clipboard.setData(
                                ClipboardData(text: entry.text),
                              ),
                          onTap:
                              () => awesomeDialog(
                                context,
                                title,
                                '${entry.explanation}\n\nالراوي: ${entry.narrator}\nالتخريج: ${entry.citation}\nالمرجع للتحقق: ${entry.referenceUrl}',
                              ),
                        );
                      },
                    ),
          );
        },
      );
    }

    return BlocConsumer<AzkarCubit, AzkarState>(
      listenWhen: (previous, current) =>
          category == 4 ||
          (category >= 0 && category <= 3 && previous.revision != current.revision),
      listener: (context, current) {
        final cubit = context.read<AzkarCubit>();
        if (category >= 0 && category <= 3) {
          if (current.isLoading) return;
          final complete = _isSectionComplete(cubit, current, category);
          if (!_completionBaselineEstablished) {
            _completionBaselineEstablished = true;
            return;
          }
          if (!complete) {
            _completionDialogShown = false;
            return;
          }
          if (_completionDialogShown) return;
          _completionDialogShown = true;
          unawaited(_showAzkarCompletion());
          return;
        }
        if (_completionDialogShown || !cubit.isPostPrayerSessionComplete()) {
          return;
        }
        _completionDialogShown = true;
        unawaited(_showPostPrayerCompletion());
      },
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
        final entries = state.entriesFor(category);
        const sleepSourceUrl = 'https://www.islambook.com/app/ar/azkr/11';
        const wakingSourceUrl = 'https://www.islambook.com/app/ar/azkr/12';
        const tasbeehSourceUrl = 'https://www.islambook.com/app/ar/azkr/3';
        const morningSourceUrl = 'https://www.islambook.com/app/ar/azkr/1';
        const eveningSourceUrl = 'https://www.islambook.com/app/ar/azkr/2';
        const postPrayerSourceUrl = 'https://www.islambook.com/app/ar/azkr/9';
        const quranDuaSourceUrl = 'https://www.islambook.com/app/ar/azkr/15';
        const prophetsDuaSourceUrl = 'https://www.islambook.com/app/ar/azkr/21';
        return Scaffold(
          appBar: defaultAppBar(context: context, text: title),
          body: entries.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount:
                        entries.length +
                        1 +
                        (category == 2 ? 1 : 0) +
                        (category == 0 || category == 1 ? 1 : 0) +
                        (category == 3 || category == 4 || category == 5 || category == 6 || category == 7 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return AzkarSectionHeader(
                          isHadith: false,
                          totalCount: entries.length,
                          showTasbeehHint: category == 5,
                        );
                      }
                      if ((category == 0 || category == 1) &&
                          index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            8,
                            12,
                            20,
                          ),
                          child: ExternalLinkButton(
                            url: category == 0
                                ? morningSourceUrl
                                : eveningSourceUrl,
                            label:
                                'المصدر: ${category == 0 ? morningSourceUrl : eveningSourceUrl}',
                          ),
                        );
                      }
                      if (category == 3 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: wakingSourceUrl,
                            label: 'المصدر: $wakingSourceUrl',
                          ),
                        );
                      }
                      if (category == 4 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: postPrayerSourceUrl,
                            label: 'المصدر: $postPrayerSourceUrl',
                          ),
                        );
                      }
                      if (category == 5 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: tasbeehSourceUrl,
                            label: 'المصدر: $tasbeehSourceUrl',
                          ),
                        );
                      }
                      if (category == 6 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: quranDuaSourceUrl,
                            label: 'المصدر: $quranDuaSourceUrl',
                          ),
                        );
                      }
                      if (category == 7 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: prophetsDuaSourceUrl,
                            label: 'المصدر: $prophetsDuaSourceUrl',
                          ),
                        );
                      }
                      if (category == 2 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: sleepSourceUrl,
                            label: 'المصدر: $sleepSourceUrl',
                          ),
                        );
                      }
                      final itemIndex = index - 1;
                      final entry = entries[itemIndex];
                      final text = entry.content;
                      return AzkarTextCard(
                        text: text,
                        sectionLabel: category == 9 ? entry.subCategory : null,
                        repetitionCount: entry.repetitionCount,
                        counter: cubit.progressFor(entry),
                        reference: category != 2 && entry.verified
                            ? _entryReference(entry)
                            : null,
                        instructions: entry.verified && category != 5
                            ? entry.instructions
                            : null,
                        showVirtueInfo: category == 5,
                        onVirtueTap: category == 5
                            ? () => _showTasbeehVirtue(context, entry)
                            : null,
                        onCopy:
                            () => Clipboard.setData(ClipboardData(text: text)),
                        onIncrement: () => cubit.incrementEntry(entry),
                      );
                    },
                  ),
        );
      },
    );
  }

  bool _isSectionComplete(AzkarCubit cubit, AzkarState state, int category) {
    final entries = state.entriesFor(category);
    return entries.isNotEmpty && entries.every((entry) {
      final required = entry.repetitionCount ?? 1;
      return cubit.progressFor(entry) >= required;
    });
  }

  Future<void> _showAzkarCompletion() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.primary.withValues(alpha: 0.22)),
          ),
          icon: Icon(Icons.spa_rounded, color: colors.primary, size: 34),
          title: const Text('أحسنت! 🌿', textAlign: TextAlign.center),
          content: const Text(
            'أتممت أذكارك، تقبّل الله منك',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  String _entryReference(AzkarEntry entry) {
    final grade = entry.authenticityGrade.trim();
    final reference = entry.reference.trim();
    if (grade.isEmpty || reference.endsWith(grade)) return reference;
    return '$reference — $grade';
  }

  Future<void> _showTasbeehVirtue(
    BuildContext context,
    AzkarEntry entry,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;
      final virtue = entry.instructions.trim();
      final reference = entry.verified ? _entryReference(entry).trim() : '';
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              24,
              4,
              24,
              24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'فضل التسبيحة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  virtue.isEmpty ? 'لا يتوفر نص للفضل.' : virtue,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                ),
                if (reference.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'المصدر: $reference',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> _showPostPrayerCompletion() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.primary.withValues(alpha: 0.22)),
          ),
          icon: Icon(Icons.spa_rounded, color: colors.primary, size: 34),
          title: const Text('أحسنت! 🌿', textAlign: TextAlign.center),
          content: const Text(
            'أتممت أذكارك، تقبّل الله منك',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
    if (mounted) Navigator.of(context).pop(true);
  }

}
