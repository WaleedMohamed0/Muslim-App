import 'dart:convert';
import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:untitled8/cubit/cubit.dart';
import 'package:untitled8/models/asmaa_allah_elhosna.dart';
import 'package:untitled8/models/azkar&Tsabeeh.dart';
import 'package:untitled8/shared/cache_helper.dart';
import 'package:untitled8/shared/network/dio.dart';
import 'package:untitled8/screens/startup_screen.dart';
import 'components/components.dart';
import 'components/constants.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioHelper.init();
  await DioHelper.initHadeeth();
  Map<String, dynamic> json1 = jsonDecode(azkar);
  AzkarAndTsabeeh.fromJson(json1);
  Map<String, dynamic> json2 = jsonDecode(asmaaAllahElHosna);
  AsmaaAllahElHosna.fromJson(json2);
  await CacheHelper.init();

  surahNameFromSharedPref = CacheHelper.getData(key: "surahName");
  surahNumFromSharedPref = CacheHelper.getData(key: "surahNumber");
  pageNumberFromSharedPref = CacheHelper.getData(key: "pageNumber");
  await checkLocationPermission();

  print(surahNameFromSharedPref);
  print(surahNumFromSharedPref);
  print(pageNumberFromSharedPref);

  runApp(BlocProvider(
      create: (context) => AppCubit()
        ..getPrayerTime()
        ..getHadeeth(),
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    checkInternetConnection(context);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ResponsiveSizer(
      builder: (p0, p1, p2) {
        return MaterialApp(
          theme: ThemeData(
            appBarTheme: AppBarTheme(backgroundColor: HexColor('22211f')),
            scaffoldBackgroundColor: HexColor('fefbec'),
            fontFamily: 'QuranFont',
          ),
          debugShowCheckedModeBanner: false,
          // home: StartUpScreen(),
          home: (AnimatedSplashScreen(
              splash: splash(),
              centered: true,
              splashIconSize: 900,
              nextScreen: StartUpScreen())),
        );
      },
    );
  }
}

Widget splash() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.teal, Colors.black]),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image(
          image: AssetImage('assets/images/logo.png'),
          width: 360,
        ),
        defaultText(
            text: 'Muslim',
            fontsize: 53,
            textColor: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.7)
      ],
    ),
  );
  //Image.asset();
}
