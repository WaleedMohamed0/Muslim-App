import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:quran/quran.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/components/components.dart';
import 'package:untitled8/cubit/cubit.dart';
import 'package:untitled8/cubit/states.dart';

class SurahScreen extends StatelessWidget {
  int? surahIndex;

  SurahScreen({required this.surahIndex});

  @override
  Widget build(BuildContext context) {
    var cubit = AppCubit.get(context);
    String surah = "";
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: defaultText(
              text: getSurahNameArabic(surahIndex!),
              fontsize: 30,
            ),
            centerTitle: true,
          ),
          body: Container(
            padding: EdgeInsets.symmetric(
                horizontal: Adaptive.w(3), vertical: Adaptive.h(3)),
            decoration: const BoxDecoration(
              image: DecorationImage(
                  opacity: .65,
                  image: AssetImage(
                    'assets/images/background.jpg',
                  ),
                  fit: BoxFit.cover),
            ),
            child: ListView.separated(
                itemBuilder: (context, index) {
                  surah = "";
                  surah +=
                      getVerse(surahIndex!, index + 1, verseEndSymbol: true);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (index == 0)
                        Column(
                          children: [
                            Center(
                                child: defaultText(
                              text: basmala,
                              fontsize: 30,
                            )),
                            SizedBox(
                              height: Adaptive.h(2.5),
                            ),
                          ],
                        ),
                      defaultText(
                        text: surah,
                        fontsize: 25,
                        fontWeight: FontWeight.bold,
                        textHeight: 2,
                        txtDirection: TextDirection.rtl,
                      ),
                    ],
                  );
                },
                separatorBuilder: (context, index) => SizedBox(
                      height: Adaptive.h(.2),
                    ),
                itemCount: getVerseCount(surahIndex!)),
          ),
          floatingActionButton: Container(
            alignment: AlignmentDirectional.bottomStart,
            margin: EdgeInsets.only(left: Adaptive.w(10)),
            child: FloatingActionButton(
              backgroundColor: HexColor('22211f').withOpacity(.9),
              onPressed: () {
                cubit.togglePlay();

                //  For Getting Surah Sound Ayah By Ayah
                //  but i found that i can get the link of Surah sound directly and easier..

                // if (!cubit.stopAudio) {
                //   cubit.stopAudio = true;
                //   cubit.nextAyah = 1;
                //   cubit.getSound(surahNum: surahIndex!).then((value) {
                //     cubit.setUrlSrc(
                //         // first Ayah
                //         urlSrc: cubit.quranSound!.audio[0],
                //         numOfAyahs: getVerseCount(surahIndex!));
                //
                //   });
                // } else {
                //   cubit.stop();
                //   cubit.stopAudio = false;
                // }
              },
              child: Icon(cubit.soundIcon),
            ),
          ),
        );
      },
    );
  }
}
