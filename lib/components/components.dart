import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/components/constants.dart';
import 'package:untitled8/cubit/cubit.dart';
import 'package:untitled8/models/hadeeth.dart';
import 'package:untitled8/screens/surah_screen.dart';
import 'package:we_slide/we_slide.dart';

void navigateTo(context, nextPage) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => nextPage,
      ),
    );

Widget defaultText(
        {required String text,
        double? fontsize,
        double? letterSpacing,
        var txtDirection,
        FontWeight? fontWeight,
        isUpperCase = false,
        textColor,
        double? textHeight,
        linesMax,
        TextOverflow? textOverflow,
        FontStyle? fontStyle,
        TextStyle? hintStyle,
        TextAlign? textAlign}) =>
    Text(
      isUpperCase ? text.toUpperCase() : text,
      textDirection: txtDirection,
      maxLines: linesMax,
      overflow: textOverflow,
      textAlign: textAlign,
      style: TextStyle(
          fontSize: fontsize,
          color: textColor,
          height: textHeight,
          fontStyle: fontStyle,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing),
    );

Widget myDivider() => Container(
      width: double.infinity,
      color: Colors.grey,
      height: 1,
    );

Widget homeItem(context, text, screen) {
  return InkWell(
    onTap: () {
      navigateTo(context, screen);
    },
    child: Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Container(
          padding: EdgeInsets.zero,
          width: Adaptive.w(76),
          height: Adaptive.h(8),
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(60), bottomLeft: Radius.circular(60)),
            color: HexColor('ffca85'),
          ),
        ),
        defaultText(
            text: text,
            fontsize: 33,
            textAlign: TextAlign.center,
            textColor: Colors.black)
      ],
    ),
  );
}

AppBar defaultAppBar(
        {required String text,
        double fontSize = 30,
        List<Widget>? actions,
        Widget? leading}) =>
    AppBar(
      title: Text(
        text,
        style: TextStyle(fontSize: fontSize),
      ),
      actions: actions,
      centerTitle: true,
      leading: leading,
    );

Future awesomeDialog(context, title, text,
        {dialogType = DialogType.question}) =>
    AwesomeDialog(
      context: context,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      dialogType: dialogType,
      isDense: true,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      dialogBackgroundColor: HexColor('22211f'),
      borderSide: const BorderSide(color: Colors.black, width: 4),
      width: 90.w,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
                child: defaultText(
                    text: title,
                    fontsize: 36,
                    textColor: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              height: 1.h,
            ),
            defaultText(text: 'التفسير', fontsize: 24, textColor: Colors.white),
            myDivider(),
            defaultText(
                text: text,
                fontsize: 20,
                txtDirection: TextDirection.rtl,
                textColor: Colors.white),
          ],
        ),
      ),
    ).show();

AwesomeDialog onScreenOpen(context) => AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dialogBackgroundColor: HexColor('22211f'),
      title: 'اضغط للتفسير',
      titleTextStyle: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal'),
      btnOkText: 'حسنا',
      btnOk: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: defaultText(text: 'حسنا', fontsize: 20, textColor: Colors.white),
      ),
    )..show();

Widget myPanel({
  required Widget screen,
  required BuildContext context,
  required AppCubit cubit,
}) {
  return WeSlide(
    panel: cubit.quranSoundActive
        ? InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                      child: SurahScreen(surahNumber: cubit.surahNumber),
                      type: PageTransitionType.bottomToTop));
            },
            child: Container(
                padding: EdgeInsets.fromLTRB(2.w, .2.h, 0.3.w, 1.w),
                color: HexColor('22211f').withOpacity(0.95),
                child: Row(
                  children: [
                    Image.asset('assets/images/العفاسي.jpg',
                        width: 17.w, height: 17.w),
                    SizedBox(
                      width: 3.w,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        defaultText(
                          textColor: Colors.white,
                          text: "سورة  ${cubit.surahName}",
                          fontsize: 17,
                          txtDirection: TextDirection.rtl,
                          fontWeight: FontWeight.bold,
                        ),
                        defaultText(
                            text: "الشيخ مشاري العفاسي",
                            textColor: Colors.white,
                            fontsize: 13,
                            textOverflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Spacer(),
                    Align(
                        widthFactor: .6,
                        alignment: Alignment.center,
                        child: playIconButton(
                          cubit: cubit,
                          context: context,
                          surahNumber: cubit.surahNumber,
                        )),
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      widthFactor: 1,
                      child: IconButton(
                        icon: CircleAvatar(
                          radius: 13,
                          backgroundColor: HexColor('fefbec'),
                          child: Icon(
                            Icons.close,
                            color: HexColor('22211f'),
                            size: 20,
                          ),
                        ),
                        onPressed: () {
                          cubit.changeQuranSoundActive();
                        },
                      ),
                    )
                  ],
                )),
          )
        : Container(),
    panelMinSize: 10.h,
    panelMaxSize: 10.h,
    body: Container(
      color: HexColor('fefbec'),
      child: screen,
    ),
  );
}

Widget playIconButton({required AppCubit cubit, context, surahNumber}) =>
    Padding(
      padding: EdgeInsets.only(right: 2.5.w),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: HexColor('fefbec'),
        onPressed: () {
          if (!cubit.isDownloading) {
            if (cubit.isCached) {
              cubit.togglePlay();
            } else {
              if (!internetConnection) {
                defaultFlutterToast(msg: 'لا يوجد اتصال بالانترنت');
              } else if (!cubit.isPlaying && internetConnection) {
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.noHeader,
                  animType: AnimType.scale,
                  title: 'هل تود تحميل السورة ؟',
                  desc:
                      "عند تحميل السورة سيمكنك لاحقا الاستماع لها بدون انترنت",
                  btnOkOnPress: () {
                    cubit.downloadSurahSound();
                  },
                  btnOkText: 'نعم',
                  btnOkColor: defaultColor,
                  btnCancelOnPress: () {
                    if (cubit.quranSoundUrl !=
                        "$quranSoundUrl$surahNumber.mp3") {
                      cubit.setUrlQuranSoundSrcOnline(
                          urlSrc: "$quranSoundUrl$surahNumber.mp3");
                    }
                    cubit.togglePlay();
                  },
                  btnCancelText: 'لا',
                  btnCancelColor: Colors.red,
                ).show();
              } else {
                cubit.togglePlay();
              }
            }
          }
        },
        child: Icon(
          cubit.soundIcon,
          color: HexColor('22211f'),
        ),
      ),
    );

Future<bool?> defaultFlutterToast({
  required String msg,
  Color textColor = Colors.white,
  Color backgroundColor = Colors.red,
  Toast toastLength = Toast.LENGTH_LONG,
}) =>
    Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: 16.0);

void checkInternetConnection(AppCubit cubit) {
  InternetConnectionChecker().onStatusChange.listen((status) {
    if (status == InternetConnectionStatus.connected) {
      internetConnection = true;

      if (!cubit.gotHadeeths) {
        cubit.getHadeeth();
        cubit.getPrayerTime();
      }
    } else {
      internetConnection = false;
    }
  });
}

Future<void> checkLocationPermission()async {
  await Geolocator.isLocationServiceEnabled().then((value) {
    if (value) {
      locationPermission = true;
    } else {
      locationPermission = false;
    }
  });

}
