import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/core/utils/arabic_digits.dart';
import 'package:untitled8/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:untitled8/features/azkar/presentation/cubit/azkar_state.dart';
import 'package:untitled8/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:untitled8/features/hadeeth/presentation/cubit/hadeeth_state.dart';

import '../../../../core/widgets/app_widgets.dart';

class AzkarAndHadeethScreen extends StatefulWidget {
  const AzkarAndHadeethScreen({super.key, required this.index});
  final int index;

  @override
  State<AzkarAndHadeethScreen> createState() => _AzkarAndHadeethScreenState();
}

class _AzkarAndHadeethScreenState extends State<AzkarAndHadeethScreen> {
  late final String title = switch (widget.index) {
    0 => 'أَذْكَارُ الصَّبَاحِ',
    1 => 'أَذْكَارُ المساءِ',
    2 => 'أَذْكَارُ النَوْم',
    3 => 'أذكار الاستيقاظ',
    4 => 'أذكار ما بعد الصلاة',
    5 => 'التسابيح',
    6 => 'أدعية قرآنية',
    7 => 'أدعية الأنبياء',
    8 => 'أدعية من السنة النبوية',
    9 => 'أدعية للمواقف اليومية',
    _ => 'الأحاديث النبوية',
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
                          return _buildGuidance(
                            context,
                            category,
                            state.entries.length,
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
                        return _TextCard(
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
        final entries = state.entriesFor(category);
        return Scaffold(
          appBar: defaultAppBar(context: context, text: title),
          body:
              entries.isEmpty
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
                        return _buildGuidance(
                          context,
                          category,
                          entries.length,
                        );
                      }
                      final itemIndex = index - 1;
                      final entry = entries[itemIndex];
                      final text = entry.content;
                      return _TextCard(
                        text: text,
                        repetitionCount: entry.repetitionCount,
                        counter: cubit.progressFor(entry),
                        reference: entry.verified ? entry.reference : null,
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

  Widget _buildGuidance(
    BuildContext context,
    int category,
    int totalCount,
  ) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 14),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              category == 10 ? Icons.menu_book_rounded : Icons.spa_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == 10
                      ? 'من هدي النبي'
                      : 'اذكر الله بقلبٍ حاضر',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                ),
                if (category == 10) ...[
                  const SizedBox(height: 3),
                  Text(
                    'اضغط على أي حديث لعرض المزيد من التفاصيل والمصدر.',
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  category == 10
                      ? 'عدد الأحاديث المتاحة: ${toArabicIndicDigits(totalCount)}'
                      : 'المتاح في هذا القسم: ${toArabicIndicDigits(totalCount)}',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TextCard extends StatelessWidget {
  const _TextCard({
    required this.text,
    required this.onCopy,
    this.repetitionCount,
    this.reference,
    this.instructions,
    this.counter,
    this.onTap,
    this.onIncrement,
    this.onReset,
  });
  final String text;
  final int? counter;
  final int? repetitionCount;
  final String? reference;
  final String? instructions;
  final VoidCallback? onTap;
  final VoidCallback onCopy;
  final VoidCallback? onIncrement;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(height: 1.9),
            ),
            if (instructions != null && instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                instructions!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
            ],
            if (reference != null && reference!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'المصدر: $reference',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (repetitionCount != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Text(
                    'عدد التكرار: ${toArabicIndicDigits(repetitionCount!)}',
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (counter != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: _TasbeehActionButton(
                                onPressed: onIncrement,
                                tooltip: 'زيادة العداد',
                                icon: Icons.add_rounded,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${toArabicIndicDigits(counter!)}${repetitionCount == null ? '' : ' / ${toArabicIndicDigits(repetitionCount!)}'}',
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: _TasbeehActionButton(
                                onPressed: onReset,
                                tooltip: 'تصفير العداد',
                                icon: Icons.restart_alt_rounded,
                                backgroundColor:
                                    Theme.of(context).colorScheme.errorContainer,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TasbeehActionButton(
                    onPressed: onCopy,
                    tooltip: 'نسخ الذكر',
                    icon: Icons.content_copy_rounded,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ] else ...[
                  if (repetitionCount != null) ...[
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Text(
                        'التكرار: ${toArabicIndicDigits(repetitionCount!)}',
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  _TasbeehActionButton(
                    onPressed: onCopy,
                    tooltip: 'نسخ الذكر',
                    icon: Icons.content_copy_rounded,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ],
            ),
            if (counter != null && repetitionCount != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  counter! >= repetitionCount!
                      ? 'اكتمل الذكر'
                      : 'المتبقي: ${toArabicIndicDigits(repetitionCount! - counter!)}',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TasbeehActionButton extends StatelessWidget {
  const _TasbeehActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor.withValues(alpha: .45),
      disabledForegroundColor: foregroundColor.withValues(alpha: .55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
    ),
    icon: Icon(icon, size: 20),
  );
}
