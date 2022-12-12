import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/models/azkar&Tsabeeh.dart';
import 'package:untitled8/models/hadeeth.dart';

import '../components/components.dart';
import '../components/constants.dart';

class AzkarAndHadeethScreen extends StatelessWidget {
  int index = 0;
  List<String> azkar = [];
  String title = "";

  AzkarAndHadeethScreen({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      azkar = AzkarAndTsabeeh.azkarElSabah;
      title = "أَذْكَارُ الصَّبَاحِ";
    } else if (index == 1) {
      azkar = AzkarAndTsabeeh.azkarElMasa2;
      title = "أَذْكَارُ المساءِ";
    } else if (index == 2) {
      azkar = AzkarAndTsabeeh.azkarElNoom;
      title = "أَذْكَارُ النَوْم";
    } else if (index == 3) {
      azkar = AzkarAndTsabeeh.tsabee7;
      title = "التسابيحُ";
    } else if (index == 4) {
      azkar = AzkarAndTsabeeh.ad3ya;
      title = "أدعية";
    } else if (index == 5) {
      title = "الأحاديث النبوية";
      if (!joinedHadeethsScreenBefore) {
        Future.delayed(
            const Duration(milliseconds: 150),
            () => {
                  onScreenOpen(context),
                });
        joinedHadeethsScreenBefore = true;
      }
    }
    return Scaffold(
      appBar: defaultAppBar(text: title),
      body: ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return InkWell(
              // to remove the effect of the inkwell
              hoverColor: this.index == 5 ? null : Colors.transparent,
              highlightColor: this.index == 5 ? null : Colors.transparent,
              focusColor: this.index == 5 ? null : Colors.transparent,
              splashFactory: this.index == 5 ? null : NoSplash.splashFactory,
              onTap: () {
                this.index == 5
                    ? awesomeDialog(context, title, Hadeeth.explanation[index])
                    : null;
              },
              child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal: Adaptive.w(5), vertical: Adaptive.h(3)),
                padding: EdgeInsets.symmetric(
                    horizontal: Adaptive.w(3), vertical: Adaptive.h(2)),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.only(bottomRight: Radius.circular(50)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.teal, offset: Offset(3, 3), blurRadius: 7)
                  ],
                ),
                child: Column(
                  children: [
                    defaultText(
                        text: this.index == 5
                            ? Hadeeth.hadeeths[index]
                            : azkar[index],
                        textColor: Colors.black,
                        fontsize: 22,
                        fontWeight: FontWeight.bold,
                        txtDirection: TextDirection.rtl),
                    Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                    text: this.index == 5
                                        ? Hadeeth.hadeeths[index]
                                        : azkar[index]))
                                .then((value) {
                              Fluttertoast.showToast(msg: "تم النسخ", fontSize: 20.sp);
                            });
                          },
                          icon: const Icon(Icons.copy),
                          color: Colors.black.withOpacity(0.5),
                        )),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => SizedBox(
                height: Adaptive.h(1),
              ),
          itemCount: index == 5 ? Hadeeth.hadeeths.length : azkar.length),
    );
  }
}