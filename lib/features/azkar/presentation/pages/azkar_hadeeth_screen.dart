import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/theme/app_theme.dart';
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
    3 => 'التسابيح',
    4 => 'أدعية',
    _ => 'الأحاديث النبوية',
  };

  @override
  void initState() {
    super.initState();
    if (widget.index != 5) {
      context.read<AzkarCubit>().loadContent();
    }
    if (widget.index == 5) context.read<HadeethCubit>().getHadeeth();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.index;
    if (category == 5) {
      return BlocBuilder<HadeethCubit, HadeethState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: defaultAppBar(context: context, text: title),
            body:
                state.entries.isEmpty
                    ? Center(child: Text(state.error ?? 'لا توجد بيانات للعرض'))
                    : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      itemCount: state.entries.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildGuidance(context, category);
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
        final azkar = cubit.itemsFor(category);
        return Scaffold(
          appBar: defaultAppBar(context: context, text: title),
          body:
              azkar.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount: azkar.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildGuidance(context, category);
                      }
                      final itemIndex = index - 1;
                      final text = azkar[itemIndex];
                      return _TextCard(
                        text: text,
                        counter:
                            category == 3
                                ? state.counters.elementAtOrNull(itemIndex) ?? 0
                                : null,
                        onCopy:
                            () => Clipboard.setData(ClipboardData(text: text)),
                        onIncrement:
                            category == 3
                                ? () => cubit.incrementAzkarTimes(itemIndex)
                                : null,
                        onReset:
                            category == 3
                                ? () => cubit.clearTimes(itemIndex)
                                : null,
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildGuidance(BuildContext context, int category) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 14),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Icon(
            category == 5 ? Icons.menu_book_rounded : Icons.spa_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category == 5 ? 'من هدي النبي ﷺ' : 'اذكر الله بقلبٍ حاضر',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    this.counter,
    this.onTap,
    this.onIncrement,
    this.onReset,
  });
  final String text;
  final int? counter;
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
                                  '$counter',
                                  textAlign: TextAlign.center,
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
                ] else
                  _TasbeehActionButton(
                    onPressed: onCopy,
                    tooltip: 'نسخ الذكر',
                    icon: Icons.content_copy_rounded,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              ],
            ),
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
