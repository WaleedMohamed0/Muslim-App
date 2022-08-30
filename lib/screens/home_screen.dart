import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:quran/quran.dart' as quran;
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/components/components.dart';
import 'package:untitled8/cubit/states.dart';
import 'package:untitled8/screens/surah_screen.dart';

import '../cubit/cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cubit = AppCubit.get(context);

    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "القراّن الكريم",
              style: TextStyle(fontSize: 30),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.separated(
                separatorBuilder: (context, index) => myDivider(),
                itemCount: 114,
                itemBuilder: ((context, index) => InkWell(
                      onTap: () {
                        cubit.setUrlQuranSoundSrc(
                            urlSrc:
                                'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/${index + 1}.mp3');
                        if (!cubit.isPlaying) {
                          cubit.togglePlay();
                        } else {
                          cubit.togglePlay();
                          cubit.togglePlay();
                        }
                        navigateTo(context, SurahScreen(surahIndex: index + 1));
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: Adaptive.w(3)),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: HexColor('22211f'),
                              ),
                              width: Adaptive.w(13),
                              height: Adaptive.h(7.5),
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 17),
                              ),
                            ),
                            SizedBox(
                              width: Adaptive.w(3),
                            ),
                            defaultText(
                              textAlign: TextAlign.right,
                              text:
                                  quran.getSurahNameArabic(index + 1) == 'اللهب'
                                      ? 'المسد'
                                      : quran.getSurahNameArabic(index + 1),
                              fontsize: 28,
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                defaultText(text: "اّياتها", fontsize: 18),
                                SizedBox(
                                  height: Adaptive.h(2.5),
                                ),
                                defaultText(
                                    text: '${quran.getVerseCount(index + 1)}',
                                    fontsize: 18),
                              ],
                            ),
                            SizedBox(
                              width: Adaptive.w(8),
                            ),
                            Column(
                              children: [
                                defaultText(
                                    text:
                                        quran.getPlaceOfRevelation(index + 1) ==
                                                "Makkah"
                                            ? "مكية"
                                            : "مدنية",
                                    fontsize: 18),
                                SizedBox(
                                  height: Adaptive.h(2),
                                ),
                                quran.getPlaceOfRevelation(index + 1) ==
                                        "Makkah"
                                    ? Image(
                                        image: const AssetImage(
                                            'assets/images/kaba.png'),
                                        width: Adaptive.w(9.5),
                                      )
                                    : Image(
                                        image: const AssetImage(
                                            'assets/images/MasjidElnabwy.png'),
                                        width: Adaptive.w(9.5),
                                      ),
                              ],
                            ),
                            SizedBox(
                              width: Adaptive.w(3),
                            ),
                          ],
                        ),
                      ),
                    ))),
          ),
        );
      },
    );
  }
}
