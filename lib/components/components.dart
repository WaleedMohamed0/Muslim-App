import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void navigateTo(context, nextPage) => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage,),
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
Widget homeItem(context,text,screen){
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
                topRight: Radius.circular(60),
                bottomLeft: Radius.circular(60)),
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
// 'السُّورُ'