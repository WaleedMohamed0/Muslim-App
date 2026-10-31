import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_state.dart';
import 'package:untitled8/features/quran/presentation/widgets/surah_list.dart';
import 'package:untitled8/features/quran/presentation/pages/surah_screen.dart';

import '../../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QuranCubit>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<QuranCubit>();
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (context, state) {
        if (cubit.bookmark != null && !cubit.bookmarkPromptShown) {
          cubit.markBookmarkPromptShown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            AwesomeDialog(
                  barrierColor: Colors.black.withOpacity(0.5),
                  context: context,
                  dialogType: DialogType.noHeader,
                  animType: AnimType.scale,
                  title: 'هل تود الانتقال الي العلامة؟',
                  btnOkOnPress: () {
                    navigateTo(
                        context,
                        SurahScreen(
                          surahNumber: cubit.bookmark!.surahNumber,
                        ));
                  },
                  btnOkText: 'نعم',
                  customHeader: Icon(
                    Icons.bookmark,
                    color: AppColors.primary,
                    size: 50,
                  ),
                  btnOkColor: AppColors.primary,
                  btnCancelOnPress: () {},
                  btnCancelText: 'لا',
                  btnCancelColor: Colors.red,
            )..show();
          });
        }
        return Scaffold(
          appBar: defaultAppBar(
            text: "القراّن الكريم",
            leading: IconButton(
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,

              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (cubit.isPlaying) {
                  cubit.togglePlay();
                }
                Navigator.pop(context);
              },
            ),
          ),
          body: myPanel(
              screen: WillPopScope(
                onWillPop: () async {
                  if (cubit.isPlaying) {
                    cubit.togglePlay();
                  }
                  return true;
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: .78)],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 34),
                            const SizedBox(width: 14),
                            Expanded(child: Text('اقرأ بتدبّر وطمأنينة', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
                            const Icon(Icons.spa_outlined, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(children: [Text('السور', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), const Spacer(), Text('١١٤ سورة', style: Theme.of(context).textTheme.labelMedium)]),
                    ),
                    Expanded(child: SurahList(cubit: cubit, online: cubit.isOnline)),
                  ],
                ),
              ),
              context: context,
              cubit: cubit),
        );
      },
    );
  }
}
