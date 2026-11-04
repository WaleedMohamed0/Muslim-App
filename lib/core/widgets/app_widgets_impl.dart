import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/presentation/pages/surah_screen.dart';
import 'package:untitled8/features/quran/presentation/widgets/quran_audio_mini_player.dart';

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
  leading: Navigator.of(context).canPop() || onBack != null
      ? AppBarBackButton(onPressed: onBack)
      : null,
  actions: actions,
  centerTitle: true,
);

/// Shared back control for app bars, with the app's established RTL arrow,
/// hit target, inherited AppBar color, and normal Navigator behavior.
class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'رجوع',
      icon: const Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(Icons.arrow_forward_rounded),
      ),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

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
  ShapeBorder? shape,
  Clip? clipBehavior,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  showDragHandle: showDragHandle,
  backgroundColor: backgroundColor,
  shape: shape,
  clipBehavior: clipBehavior,
  builder:
      (sheetContext) => Padding(
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
  required ValueChanged<double> onMiniPlayerHeightChanged,
}) {
  final playerVisible = cubit.quranSoundActive;
  return Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: screen,
      ),
      PositionedDirectional(
        start: 0,
        end: 0,
        bottom: 0,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          reverseDuration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: playerVisible
              ? QuranAudioMiniPlayer(
                  key: const ValueKey('quran-mini-player-visible'),
                  onHeightChanged: onMiniPlayerHeightChanged,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: SurahScreen(
                          surahNumber: cubit.surahNumber,
                          initialAyah: cubit.currentAyahNumber,
                        ),
                        type: PageTransitionType.bottomToTop,
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(
                  key: ValueKey('quran-mini-player-hidden'),
                ),
        ),
      ),
    ],
  );
}

Widget playIconButton({
  required QuranCubit cubit,
  context,
  Color? backgroundColor,
  Color? foregroundColor,
}) => Padding(
  padding: EdgeInsetsDirectional.only(end: 2.5.w),
  child: FloatingActionButton(
    mini: true,
    backgroundColor:
        backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
    onPressed: cubit.isAudioLoading ? null : cubit.togglePlay,
    child:
        cubit.isAudioLoading
            ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color:
                    foregroundColor ??
                    Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            )
            : Icon(
              cubit.soundIcon,
              color:
                  foregroundColor ??
                  Theme.of(context).colorScheme.onPrimaryContainer,
            ),
  ),
);
