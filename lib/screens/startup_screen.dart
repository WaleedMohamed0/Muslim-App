import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/components/components.dart';
import 'package:untitled8/cubit/cubit.dart';
import 'package:untitled8/cubit/states.dart';
import 'package:untitled8/screens/asmaa_allah_screen.dart';
import 'package:untitled8/screens/azkar_screen.dart';
import 'package:untitled8/screens/home_screen.dart';
import 'package:untitled8/screens/prayer_times_screen.dart';
import '../models/azkar_start_up.dart';

class StartUpScreen extends StatelessWidget {
  const StartUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<AzkarModel> azkarList = [
      AzkarModel(text: 'أذكار الصباح', img: 'assets/images/azkarElsabah.jpg'),
      AzkarModel(text: 'أذكار المساء', img: 'assets/images/azkarElmasa2.jpg'),
      AzkarModel(text: 'أذكار النوم', img: 'assets/images/azkarElnoom.jpg'),
      AzkarModel(text: 'تسابيح', img: 'assets/images/tsabeh.jpg'),
      AzkarModel(text: 'أدعية', img: 'assets/images/praying.png'),
    ];

    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal, Colors.black]),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Center(
                      child: Image(
                        image: const AssetImage('assets/images/quran_logo.png'),
                        width: Adaptive.w(74),
                      )),
                  Container(
                    height: Adaptive.h(18),
                    padding: EdgeInsets.symmetric(horizontal: Adaptive.w(3.2)),
                    child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) =>
                            buildAzkarItem(azkarList[index], index, context),
                        separatorBuilder: (context, index) => SizedBox(
                          width: Adaptive.w(4),
                        ),
                        itemCount: azkarList.length),
                  ),
                  homeItem(context, 'السُّورُ', HomeScreen()),
                  homeItem(context, 'مواقيتُ الصَّلاَةُ', PrayerTimes()),
                  homeItem(context, 'أسماء الله الحسنى', AsmaaAllahScreen()),
                ],
              ),
            ));
      },
    );
  }

  Widget buildAzkarItem(azkarList, index, context) => InkWell(
        onTap: () {
          navigateTo(context, AzkarScreen(index: index));
        },
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Image(
              image: AssetImage(azkarList.img),
              fit: BoxFit.cover,
              width: Adaptive.w(27),
              height: Adaptive.h(13),
            ),
            Container(
                width: Adaptive.w(27),
                color: Colors.black.withOpacity(.7),
                child: defaultText(
                    text: azkarList.text,
                    textColor: Colors.white,
                    fontsize: 17,
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
