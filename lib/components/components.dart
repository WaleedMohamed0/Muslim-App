import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
