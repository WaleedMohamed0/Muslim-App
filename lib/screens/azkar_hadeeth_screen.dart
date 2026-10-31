import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/cubit/states.dart';
import 'package:untitled8/models/azkar&Tsabeeh.dart';
import 'package:untitled8/models/hadeeth.dart';

import '../components/components.dart';
import '../components/constants.dart';
import '../cubit/cubit.dart';

class AzkarAndHadeethScreen extends StatelessWidget {
  int index = 0;
  String title = "";
  List<String> azkar = [];

  AzkarAndHadeethScreen({required this.index});

  @override
  Widget build(BuildContext context) {
    var cubit = AppCubit.get(context);

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
      cubit.azkarTimes = List.filled(azkar.length, 0);
    } else if (index == 4) {
      azkar = AzkarAndTsabeeh.ad3ya;
      title = "أدعية";
    } else if (index == 5) {
      title = "الأحاديث النبوية";
      if (!joinedHadeethsScreenBefore && internetConnection) {
        Future.delayed(
            const Duration(milliseconds: 150),
            () => {
                  onScreenOpen(context),
                });
        joinedHadeethsScreenBefore = true;
      } else if (!internetConnection && Hadeeth.hadeeths.isEmpty) {
        defaultFlutterToast(msg: "يرجي الاتصال بالانترنت لتحميل الأحاديث");
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.only(bottomRight: Radius.circular(50)),
                  boxShadow: [
                    BoxShadow(
                        color: defaultColor,
                        offset: const Offset(3, 3),
                        blurRadius: 7)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                    text: this.index == 5
                                        ? Hadeeth.hadeeths[index]
                                        : azkar[index]))
                                .then((value) {
                              Fluttertoast.showToast(
                                  msg: "تم النسخ", fontSize: 16.sp);
                            });
                          },
                          icon: const Icon(Icons.copy),
                          color: Colors.black.withOpacity(0.5),
                        ),
                        if (this.index == 3)
                          BlocBuilder<AppCubit, AppStates>(
                            builder: (context, state) {
                              return Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      cubit.clearTimes(index);
                                    },
                                    icon: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: defaultColor,
                                        child: const Icon(Icons.recycling)),
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 1.w,
                                  ),
                                  defaultText(
                                    text: "${cubit.azkarTimes[index]}",
                                    fontsize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(
                                    width: 1.w,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      cubit.incrementAzkarTimes(index);
                                    },
                                    icon: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: defaultColor,
                                        child: const Icon(Icons.add)),
                                    color: Colors.white,
                                  ),
                                ],
                              );
                            },
                          ),
                        SizedBox(
                          width: 12.w,
                        ),
                      ],
                    ),
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
