import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/components/constants.dart';
import 'package:untitled8/models/asmaa_allah_elhosna.dart';
import 'package:untitled8/models/azkar&Tsabeeh.dart';

import '../components/components.dart';

class AsmaaAllahScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: defaultText(text: "أسماء الله الحسنى", fontsize: 25),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        children: List.generate(
            AsmaaAllahElHosna.name.length,
            (index) => InkWell(
                  onTap: () {
                    AwesomeDialog(
                      context: context,
                      animType: AnimType.bottomSlide,
                      dialogType: DialogType.question,
                      dialogBackgroundColor: HexColor('22211f'),
                      borderSide: const BorderSide(color: Colors.black, width: 4),
                      body: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 2.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Center(
                                  child: defaultText(
                                      text: AsmaaAllahElHosna.name[index],
                                      fontsize: 36,
                                      textColor: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(
                                height: 1.h,
                              ),
                              defaultText(
                                  text: 'التفسير',
                                  fontsize: 24,
                                  textColor: Colors.white),
                              myDivider(),
                              defaultText(
                                  text: AsmaaAllahElHosna.meaning[index],
                                  fontsize: 20,
                                  txtDirection: TextDirection.rtl,
                                  textColor: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ).show();
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.teal, Colors.white60]),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black,
                              offset: Offset(3, 3),
                              blurRadius: 7)
                        ]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        defaultText(
                            text: AsmaaAllahElHosna.name[index],
                            fontsize: 30,
                            fontWeight: FontWeight.bold,
                            txtDirection: TextDirection.rtl),
                        defaultText(text: "اضغط للتفسير", fontsize: 20),
                      ],
                    ),
                  ),
                )),
      ),
    );
  }
}
