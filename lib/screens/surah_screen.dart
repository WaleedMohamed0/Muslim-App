import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/components/components.dart';
import 'package:untitled8/components/constants.dart';
import 'package:untitled8/cubit/cubit.dart';
import 'package:untitled8/cubit/states.dart';
import 'package:untitled8/shared/cache_helper.dart';

class SurahScreen extends StatelessWidget {
  int? surahNumber;

  SurahScreen({required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    var cubit = AppCubit.get(context);
    List<int> numsOfPages = getSurahPages(surahNumber!);
    String surahName = getSurahNameArabic(surahNumber!);

    return BlocBuilder<AppCubit, AppStates>(
      builder: (context, state) {
        final PageController pageController = PageController(
            initialPage: surahName == surahNameFromSharedPref
                ? pageNumberFromSharedPref - numsOfPages[0]
                : 0);
        return SafeArea(
          child: Scaffold(
              appBar: defaultAppBar(text: surahName, actions: [
                IconButton(
                    onPressed: () {
                      CacheHelper.saveData(key: "surahName", value: surahName);
                      CacheHelper.saveData(
                          key: "surahNumber", value: surahNumber);
                      CacheHelper.saveData(
                          key: "pageNumber", value: cubit.currentPageNumber);
                      surahNameFromSharedPref = surahName;
                      surahNumFromSharedPref = surahNumber!;
                      pageNumberFromSharedPref = cubit.currentPageNumber;
                      Fluttertoast.showToast(
                          msg: "تم حفظ السورة", fontSize: 20.sp);
                    },
                    icon: const Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 30,
                    )),
                playIconButton(cubit: cubit),
              ]),
              body: PageView.builder(
                itemCount: numsOfPages.length,
                reverse: true,
                controller: pageController,
                itemBuilder: (context, index) {
                  cubit.setCurrentPageNumber(numsOfPages[index]);
                  return Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Image.asset(
                          "assets/quranImages/${numsOfPages[index]}.png",
                          fit: BoxFit.fill),
                      if (index == pageController.initialPage)
                        Image.asset('assets/images/savedPageNumIcon.png',
                          height: 25.w,
                            ),


                    ],
                  );
                },
              )),
        );
      },
    );
  }
}
