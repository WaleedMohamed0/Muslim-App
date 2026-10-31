import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/features/azkar/presentation/cubit/azkar_cubit.dart';
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
  late final List<String> azkar = widget.index == 5
      ? const []
      : context.read<AzkarCubit>().itemsFor(widget.index);
  late final String title = switch (widget.index) {
    0 => 'أَذْكَارُ الصَّبَاحِ',
    1 => 'أَذْكَارُ المساءِ',
    2 => 'أَذْكَارُ النَوْم',
    3 => 'التسابيحُ',
    4 => 'أدعية',
    _ => 'الأحاديث النبوية',
  };

  @override
  void initState() {
    super.initState();
    context.read<AzkarCubit>().loadContent();
    if (widget.index == 5) context.read<HadeethCubit>().getHadeeth();
    if (widget.index == 3) {
      final count = context.read<AzkarCubit>().itemsFor(3).length;
      context.read<AzkarCubit>().initializeCounters(count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.index;
    return BlocBuilder<HadeethCubit, HadeethState>(
      builder: (context, hadeethState) {
        final entries = hadeethState.entries;
        final itemCount = category == 5 ? entries.length : azkar.length;
        if (category == 5 && hadeethState.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: defaultAppBar(text: title),
          body: itemCount == 0
              ? Center(child: Text(hadeethState.error ?? 'لا توجد بيانات للعرض'))
              : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: itemCount + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
                  child: Row(children: [Icon(category == 5 ? Icons.menu_book_rounded : Icons.spa_rounded, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Text(category == 5 ? 'من هدي النبي ﷺ' : 'اذكر الله بقلبٍ حاضر', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)))]),
                ),
              );
            }
            index -= 1;
            final text = category == 5 ? entries[index].text : azkar[index];
            final explanation = category == 5 ? entries[index].explanation : '';
            return _TextCard(
              text: text,
              counter: category == 3
                  ? context.select<AzkarCubit, int>((cubit) => cubit.state.counters.elementAtOrNull(index) ?? 0)
                  : null,
              onTap: category == 5 ? () => awesomeDialog(context, title, explanation) : null,
              onCopy: () => Clipboard.setData(ClipboardData(text: text)),
              onIncrement: category == 3 ? () => context.read<AzkarCubit>().incrementAzkarTimes(index) : null,
              onReset: category == 3 ? () => context.read<AzkarCubit>().clearTimes(index) : null,
            );
          },
        ),
        );
      },
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.text, required this.onCopy, this.counter, this.onTap, this.onIncrement, this.onReset});
  final String text;
  final int? counter;
  final VoidCallback? onTap;
  final VoidCallback onCopy;
  final VoidCallback? onIncrement;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.9)),
              const SizedBox(height: 10),
              Row(children: [
                IconButton.filledTonal(onPressed: onCopy, tooltip: 'نسخ الذكر', icon: const Icon(Icons.copy_rounded, size: 18)),
                if (counter != null) ...[
                  IconButton(onPressed: onReset, icon: const Icon(Icons.refresh)),
                  Text('$counter', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline)),
                ],
              ]),
            ]),
          ),
        ),
      );
}
