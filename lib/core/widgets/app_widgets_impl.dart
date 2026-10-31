import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/pages/surah_screen.dart';
import 'package:we_slide/we_slide.dart';
import 'package:untitled8/core/theme/app_colors.dart';

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
        double fontSize = 20,
        List<Widget>? actions,
        Widget? leading}) =>
    AppBar(
      title: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
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
      dialogBackgroundColor: Theme.of(context).colorScheme.surface,
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      width: 90.w,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
                child: defaultText(
                    text: title,
                    fontsize: 36,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              height: 1.h,
            ),
            defaultText(text: 'التفسير', fontsize: 18, textColor: Theme.of(context).colorScheme.primary),
            myDivider(),
            defaultText(
                text: text,
                fontsize: 20,
                txtDirection: TextDirection.rtl,
                textColor: Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ),
    ).show();

Widget myPanel({
  required Widget screen,
  required BuildContext context,
  required QuranCubit cubit,
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Image.asset('assets/features/quran/images/alafasy.jpg',
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
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onSurface,
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
    body: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor, child: screen),
  );
}

Widget playIconButton({required QuranCubit cubit, context, surahNumber}) =>
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
              if (!cubit.isOnline) {
                defaultFlutterToast(msg: 'لا يوجد اتصال بالانترنت');
              } else if (!cubit.isPlaying && cubit.isOnline) {
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
                  btnOkColor: AppColors.primary,
                  btnCancelOnPress: () {
                    cubit.playCurrentSurahOnline(surahNumber);
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

