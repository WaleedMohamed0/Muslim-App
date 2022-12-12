import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:untitled8/models/asmaa_allah_elhosna.dart';
import '../components/components.dart';
import '../components/constants.dart';

class AsmaaAllahScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!joinedAsmaaAllahScreenBefore) {
      Future.delayed(
        Duration(milliseconds: 150),
        () =>
            {
              onScreenOpen(context),
            });
      joinedAsmaaAllahScreenBefore = true;
    }

    return Scaffold(
      appBar: defaultAppBar(text: "أسماء الله الحسنى"),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          children: List.generate(
              AsmaaAllahElHosna.name.length,
              (index) => InkWell(
                    onTap: () {
                      awesomeDialog(context, AsmaaAllahElHosna.name[index],
                          AsmaaAllahElHosna.meaning[index]);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              tileMode: TileMode.mirror,
                              end: Alignment.center,
                              colors: [Colors.teal, Colors.lightGreen]),
                          border: Border.all(
                            color: Colors.black,
                            width: .3,
                          ),
                          boxShadow: const [
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
                        ],
                      ),
                    ),
                  )),
        ),
      ),
    );
  }
}
