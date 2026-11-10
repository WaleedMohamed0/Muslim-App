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
      listenWhen: (_, __) => category == 4,
      listener: (context, _) {
        final cubit = context.read<AzkarCubit>();
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
                        instructions: entry.verified ? entry.instructions : null,
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

  String _entryReference(AzkarEntry entry) {
    final grade = entry.authenticityGrade.trim();
    final reference = entry.reference.trim();
    if (grade.isEmpty || reference.endsWith(grade)) return reference;
    return '$reference — $grade';
  }

  Future<void> _showPostPrayerCompletion() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 38),
        title: const Text('أحسنت!'),
        content: const Text(
          'أتممت أذكار ما بعد الصلاة بنجاح، تقبّل الله منك.',
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
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

}
