import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/pages/surah_screen.dart';
import 'package:we_slide/we_slide.dart';
import 'package:untitled8/core/widgets/app_snackbar.dart';

void navigateTo(context, nextPage) =>
    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));

Widget defaultText({
  required String text,
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
  TextAlign? textAlign,
}) => Text(
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
    letterSpacing: letterSpacing,
  ),
);

Widget myDivider(BuildContext context) => Container(
  width: double.infinity,
  color: Theme.of(context).dividerColor,
  height: 1,
);

Widget homeItem(context, text, screen) {
  final scheme = Theme.of(context).colorScheme;
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
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(AppRadii.pill),
              bottomEnd: Radius.circular(AppRadii.pill),
            ),
            color: scheme.secondaryContainer,
          ),
        ),
        defaultText(
          text: text,
          fontsize: 33,
          textAlign: TextAlign.center,
          textColor: scheme.onSecondaryContainer,
        ),
      ],
    ),
  );
}

AppBar defaultAppBar({
  required BuildContext context,
  required String text,
  double fontSize = 20,
  List<Widget>? actions,
  VoidCallback? onBack,
}) => AppBar(
  automaticallyImplyLeading: false,
  title: Text(
    text,
    style: Theme.of(
      context,
    ).appBarTheme.titleTextStyle?.copyWith(fontSize: fontSize),
  ),
  leading:
      Navigator.of(context).canPop()
          ? IconButton(
            tooltip: 'رجوع',
            icon: const Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(Icons.arrow_forward_rounded),
            ),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          )
          : null,
  actions: actions,
  centerTitle: true,
);

/// Opens a modal sheet above system navigation and gesture insets.
///
/// Flutter's `useSafeArea` option protects the top and horizontal edges but
/// does not apply a bottom safe area. Keep that handling here so every app
/// sheet gets the same navigation-bar clearance.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
  Color? backgroundColor,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      builder: (sheetContext) => Padding(
        // Use viewPadding because the app-level SafeArea removes `padding`
        // from descendants of the Navigator.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(sheetContext).bottom + AppSpacing.md,
        ),
        child: builder(sheetContext),
      ),
    );

Future awesomeDialog(
  context,
  title,
  text, {
  dialogType = DialogType.question,
}) =>
    AwesomeDialog(
      context: context,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      dialogType: dialogType,
      isDense: true,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 3.w, vertical: 1.h),
      dialogBackgroundColor: Theme.of(context).colorScheme.surface,
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      width: 90.w,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: defaultText(
                text: title,
                fontsize: 36,
                textColor: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            defaultText(
              text: 'التفسير',
              fontsize: 18,
              textColor: Theme.of(context).colorScheme.primary,
            ),
            myDivider(context),
            defaultText(
              text: text,
              fontsize: 20,
              txtDirection: TextDirection.rtl,
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
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
    panel:
        cubit.quranSoundActive
            ? InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    child: SurahScreen(surahNumber: cubit.surahNumber),
                    type: PageTransitionType.bottomToTop,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsetsDirectional.fromSTEB(2.w, .2.h, 0.3.w, 1.w),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/features/quran/images/alafasy.jpg',
                      width: 17.w,
                      height: 17.w,
                    ),
                    SizedBox(width: 3.w),
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
                          textOverflow: TextOverflow.ellipsis,
                        ),
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
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      widthFactor: 1,
                      child: IconButton(
                        icon: CircleAvatar(
                          radius: 13,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
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
                    ),
                  ],
                ),
              ),
            )
            : Container(),
    panelMinSize: 10.h,
    panelMaxSize: 10.h,
    body: ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: screen,
    ),
  );
}

Widget playIconButton({
  required QuranCubit cubit,
  context,
  surahNumber,
  Color? backgroundColor,
  Color? foregroundColor,
}) => Padding(
  padding: EdgeInsetsDirectional.only(end: 2.5.w),
  child: FloatingActionButton(
    mini: true,
    backgroundColor:
        backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
    onPressed: () async {
      if (!cubit.isDownloading) {
        if (cubit.isCached) {
          try {
            await cubit.togglePlay();
          } catch (_) {
            AppSnackBar.show(message: 'تعذر تشغيل التلاوة المحفوظة');
          }
        } else {
          if (!cubit.isPlaying) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.noHeader,
              animType: AnimType.scale,
              title: 'هل تود تحميل السورة ؟',
              desc: "عند تحميل السورة سيمكنك لاحقا الاستماع لها بدون انترنت",
              btnOkOnPress: () {
                cubit.downloadSurahSound();
              },
              btnOkText: 'نعم',
              btnOkColor: Theme.of(context).colorScheme.primary,
              btnCancelOnPress: () async {
                try {
                  await cubit.playCurrentSurahOnline(surahNumber);
                } catch (_) {
                  AppSnackBar.show(
                    message: 'تعذر تشغيل التلاوة، تحقق من الاتصال وحاول مجددًا',
                  );
                }
              },
              btnCancelText: 'لا',
              btnCancelColor: Theme.of(context).colorScheme.error,
            ).show();
          } else {
            try {
              await cubit.togglePlay();
            } catch (_) {
              AppSnackBar.show(message: 'تعذر إيقاف التلاوة');
            }
          }
        }
      }
    },
    child: Icon(
      cubit.soundIcon,
      color:
          foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  ),
);
