import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/features/asmaa_allah/domain/entities/allah_name.dart';
import 'package:muslim/features/asmaa_allah/presentation/cubit/allah_names_cubit.dart';
import 'package:muslim/features/asmaa_allah/presentation/cubit/allah_names_state.dart';
import '../../../../core/widgets/app_widgets.dart';
import 'package:muslim/features/asmaa_allah/presentation/widgets/asmaa_allah_widgets.dart';

class AsmaaAllahScreen extends StatefulWidget {
  const AsmaaAllahScreen({super.key});

  @override
  State<AsmaaAllahScreen> createState() => _AsmaaAllahScreenState();
}

class _AsmaaAllahScreenState extends State<AsmaaAllahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AllahNamesCubit, AllahNamesState>(
    builder: (context, state) {
      return Scaffold(
        appBar: defaultAppBar(context: context, text: 'أسماء الله الحسنى'),
        body: state.isLoading && state.names.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.names.isEmpty
                ? AsmaNamesLoadError(message: state.error!, onRetry: context.read<AllahNamesCubit>().load)
                : state.names.isEmpty
                    ? const Center(child: Text('لا توجد أسماء متاحة للعرض'))
                    : _buildNames(context, state.names),
      );
    },
  );

  Widget _buildNames(BuildContext context, List<AllahName> names) {
    final filtered = names.where((item) =>
      _normalize('${item.name} ${item.meaning}').contains(_normalize(_query))).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final columns = constraints.maxWidth >= 1000 ? 3 : (wide ? 2 : 1);
      final colors = Theme.of(context).colorScheme;
      return CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: colors.primary.withValues(alpha: .12)),
                      ),
                      child: Column(children: [
                        Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 25),
                        const SizedBox(height: 8),
                        Text('وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ', textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.primary, fontWeight: FontWeight.w700, height: 1.6)),
                        const SizedBox(height: 3),
                        Text('تعرّف على الأسماء ومعانيها', textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('اضغط على أي اسم لعرض معلومات أكثر', textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.start,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم أو معنى',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty ? null : IconButton(
                          tooltip: 'مسح البحث', icon: const Icon(Icons.close_rounded),
                          onPressed: () { _searchController.clear(); setState(() => _query = ''); },
                        ),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.tile), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.tile), borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: .6))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.tile), borderSide: BorderSide(color: colors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text(_query.isEmpty ? 'الأسماء الحسنى' : 'نتائج البحث',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${filtered.length} اسم', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('لا توجد نتائج مطابقة')))
          else
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(wide ? 28 : 20, 0, wide ? 28 : 20, 28),
              sliver: SliverLayoutBuilder(builder: (context, sliverConstraints) {
                final maxWidth = sliverConstraints.crossAxisExtent;
                final spacing = 12.0;
                final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
                return SliverGrid.builder(
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns, crossAxisSpacing: spacing, mainAxisSpacing: spacing,
                    mainAxisExtent: cardWidth < 300 ? 190 : 174,
                  ),
                  itemBuilder: (context, index) => AsmaNameCard(
                    name: filtered[index], number: names.indexOf(filtered[index]) + 1,
                    onTap: () => _showDetails(context, filtered[index], names.indexOf(filtered[index]) + 1),
                  ),
                );
              }),
            ),
        ],
      );
    });
  }

  void _showDetails(BuildContext context, AllahName name, int number) {
    showAppModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      builder: (context) => AsmaNameDetails(name: name, number: number),
    );
  }

  String _normalize(String value) => value
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
      .trim().toLowerCase();
}
