import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/features/asmaa_allah/presentation/cubit/allah_names_cubit.dart';
import '../../../../core/widgets/app_widgets.dart';

class AsmaaAllahScreen extends StatelessWidget {
  const AsmaaAllahScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final names = context.read<AllahNamesCubit>().state.names;
    return Scaffold(
      appBar: defaultAppBar(text: "أسماء الله الحسنى"),
      body: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(builder: (context, constraints) => GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: constraints.maxWidth < 430 ? 210 : 250,
              crossAxisSpacing: 14, mainAxisSpacing: 14,
              childAspectRatio: 1.2,
            ),
            itemCount: names.length,
            itemBuilder: (context, index) {
              final name = names[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => awesomeDialog(context, name.name, name.meaning),
                  child: Stack(
                    children: [
                      PositionedDirectional(top: 12, start: 14, child: Icon(Icons.auto_awesome_outlined, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: .7))),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(name.name, textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )),
      ),
    );
  }
}
