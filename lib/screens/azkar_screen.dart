import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/models/azkar&Tsabeeh.dart';

import '../components/components.dart';

class AzkarScreen extends StatelessWidget {
  int index = 0;
  List<String> azkar = [];
  String title = "";

  AzkarScreen({required this.index});

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
    }
    return Scaffold(
      appBar: AppBar(
        title: defaultText(text: title, fontsize: 25),
        centerTitle: true,
      ),
      body: ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return Container(
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
              child: defaultText(
                  text: azkar[index],
                  textColor: Colors.black,
                  fontsize: 22,
                  fontWeight: FontWeight.bold,
                  txtDirection: TextDirection.rtl),
            );
          },
          separatorBuilder: (context, index) => SizedBox(
                height: Adaptive.h(1),
              ),
          itemCount: azkar.length),
    );
  }
}
