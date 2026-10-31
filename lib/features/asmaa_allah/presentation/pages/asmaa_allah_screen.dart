import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/features/asmaa_allah/presentation/cubit/allah_names_cubit.dart';
import 'package:untitled8/features/asmaa_allah/presentation/cubit/allah_names_state.dart';
import '../../../../core/widgets/app_widgets.dart';

class AsmaaAllahScreen extends StatelessWidget {
  const AsmaaAllahScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AllahNamesCubit, AllahNamesState>(
        builder: (context, state) {
          return Scaffold(
            appBar: defaultAppBar(context: context, text: 'أسماء الله الحسنى'),
            body:
                state.isLoading && state.names.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && state.names.isEmpty
                    ? _LoadError(
                      message: state.error!,
                      onRetry: context.read<AllahNamesCubit>().load,
                    )
                    : state.names.isEmpty
                    ? const Center(child: Text('لا توجد أسماء متاحة للعرض'))
                    : LayoutBuilder(
                      builder:
                          (context, constraints) => GridView.builder(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      constraints.maxWidth < 430 ? 210 : 250,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 1.2,
                                ),
                            itemCount: state.names.length,
                            itemBuilder: (context, index) {
                              final name = state.names[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap:
                                      () => awesomeDialog(
                                        context,
                                        name.name,
                                        name.meaning,
                                      ),
                                  child: Stack(
                                    children: [
                                      PositionedDirectional(
                                        top: 12,
                                        end: 14,
                                        child: Icon(
                                          Icons.auto_awesome_outlined,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: .7),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            name.name,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall?.copyWith(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
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
                          ),
                    ),
          );
        },
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text('تعذر تحميل الأسماء'),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}
