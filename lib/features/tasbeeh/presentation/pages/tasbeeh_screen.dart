import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:muslim/features/tasbeeh/domain/entities/tasbeeh_state.dart';
import 'package:muslim/features/tasbeeh/presentation/cubit/tasbeeh_cubit.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});
  static const _azkar = ['سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ ، وَاللَّهُ أَكْبَرُ.'];

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TasbeehCubit(TasbeehRepository())..load(),
    child: const _TasbeehView(),
  );
}

class _TasbeehView extends StatelessWidget {
  const _TasbeehView();

  Future<void> _chooseTarget(BuildContext context, TasbeehState state) async {
    final cubit = context.read<TasbeehCubit>();
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _TasbeehTargetDialog(currentTarget: state.target),
    );
    if (!context.mounted) return;
    if (value != null && value > 0) await cubit.setTarget(value);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('المسبحة الإلكترونية', style: TextStyle(fontWeight: FontWeight.w800))),
      body: BlocBuilder<TasbeehCubit, TasbeehState>(builder: (context, state) {
        final colors = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        return SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          final diameter = (constraints.maxWidth - 72).clamp(220.0, compact ? 280.0 : 316.0);
          return ListView(padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 20), children: [
            const SizedBox(height: 8),
            Text('وِردُكَ الآن', textAlign: TextAlign.center, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant, letterSpacing: .5)),
            const SizedBox(height: 8),
            AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: Text(state.dhikr, key: ValueKey(state.dhikr), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 24) + 2, fontWeight: FontWeight.w800, height: 1.7, color: colors.primary))),
            const SizedBox(height: 8),
            SizedBox(height: diameter + 16, child: Center(child: Semantics(button: true, label: 'التسبيح، العدد ${state.count} من ${state.target}', child: SizedBox(
              width: diameter, height: diameter, child: Stack(alignment: Alignment.center, children: [
                TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: state.progress), duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic, builder: (context, progress, _) => SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 5, strokeCap: StrokeCap.round, backgroundColor: colors.primary.withValues(alpha: .10), color: state.isComplete ? colors.tertiary : colors.primary))),
                Padding(padding: const EdgeInsets.all(15), child: Material(color: colors.primaryContainer, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: state.isLoading ? null : () { HapticFeedback.selectionClick(); context.read<TasbeehCubit>().increment(); }, child: SizedBox.expand(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(toArabicIndicDigits(state.count), style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.onPrimaryContainer, fontFeatures: const [FontFeature.tabularFigures()]), textScaler: const TextScaler.linear(1)),
                  const SizedBox(height: 2),
                  Text('من ${toArabicIndicDigits(state.target)}', style: theme.textTheme.titleSmall?.copyWith(color: colors.onPrimaryContainer.withValues(alpha: .72))),
                  const SizedBox(height: 13),
                  Icon(state.isComplete ? Icons.check_circle_rounded : Icons.touch_app_rounded, size: 25, color: colors.primary),
                  const SizedBox(height: 3),
                  Text(state.isComplete ? 'اكتمل الورد' : 'اضغط للتسبيح', style: theme.textTheme.labelLarge?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
                ]))))),
              ]),
            )))),
            if (state.isComplete) Padding(padding: const EdgeInsets.only(top: 2), child: Text('تقبّل الله منك', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: colors.tertiary, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            Row(children: [
              const Spacer(),
              TextButton(
                onPressed: () => _chooseTarget(context, state),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الهدف ${toArabicIndicDigits(state.target)}'),
                    const SizedBox(width: 8),
                    const Icon(Icons.flag_outlined, size: 19),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: Text('الذكر', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))), Text('اسحب للاختيار', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant))]),
            const SizedBox(height: 10),
            SizedBox(height: 46, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: TasbeehScreen._azkar.length, separatorBuilder: (_, _) => const SizedBox(width: 8), itemBuilder: (context, index) {
              final dhikr = TasbeehScreen._azkar[index];
              final selected = state.dhikr == dhikr;
              return ChoiceChip(label: Text(dhikr, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)), selected: selected, onSelected: (_) => context.read<TasbeehCubit>().selectDhikr(dhikr), showCheckmark: false, padding: const EdgeInsets.symmetric(horizontal: 9), side: BorderSide.none);
            })),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: Text('هدف الورد', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
              ...[33, 100].map((target) => Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: _TargetPill(value: target, selected: state.target == target, onTap: () => context.read<TasbeehCubit>().setTarget(target)))),
              Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: _TargetPill(label: 'مخصص', selected: state.target != 33 && state.target != 100, onTap: () => _chooseTarget(context, state))),
            ]),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), decoration: BoxDecoration(color: colors.surfaceContainerHigh.withValues(alpha: .72), borderRadius: BorderRadius.circular(18)), child: Row(children: [Icon(Icons.auto_awesome_outlined, size: 19, color: colors.primary), const SizedBox(width: 10), Expanded(child: Text('تسبيحات اليوم', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant))), Text(toArabicIndicDigits(state.dailyTotal), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.primary))])),
          ]);
        }));
      }),
    ),
  );
}

class _TasbeehTargetDialog extends StatefulWidget {
  const _TasbeehTargetDialog({required this.currentTarget});

  final int currentTarget;

  @override
  State<_TasbeehTargetDialog> createState() => _TasbeehTargetDialogState();
}

class _TasbeehTargetDialogState extends State<_TasbeehTargetDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentTarget.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      title: const Text('العدد المستهدف'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: [
              33,
              100,
            ].map((value) => ActionChip(
              label: Text(toArabicIndicDigits(value)),
              onPressed: () => Navigator.pop(context, value),
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد مخصص'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, int.tryParse(_controller.text)),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}

class _TargetPill extends StatelessWidget {
  const _TargetPill({this.value, this.label, required this.selected, required this.onTap});
  final int? value; final String? label; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final colors = Theme.of(context).colorScheme; return Material(color: selected ? colors.primaryContainer : colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), child: Text(label ?? toArabicIndicDigits(value!), style: TextStyle(color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant, fontWeight: FontWeight.w700))))); }
}
