import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:untitled8/core/network/connectivity_service.dart';
import 'package:untitled8/core/widgets/app_snackbar.dart';
import 'package:untitled8/features/app/presentation/cubit/app_cubit.dart';
import 'package:untitled8/features/asmaa_allah/data/data_sources/local_allah_names_data_source.dart';
import 'package:untitled8/features/asmaa_allah/presentation/cubit/allah_names_cubit.dart';
import 'package:untitled8/features/asmaa_allah/presentation/pages/asmaa_allah_screen.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:untitled8/features/quran/domain/entities/quran_bookmark.dart';
import 'package:untitled8/features/quran/domain/repositories/quran_bookmark_repository.dart';
import 'package:untitled8/features/quran/presentation/pages/surah_screen.dart';
import 'package:untitled8/features/quran/presentation/pages/home_screen.dart';
import 'package:untitled8/features/quran/presentation/widgets/surah_list.dart';
import 'package:untitled8/features/azkar/data/data_sources/local_azkar_data_source.dart';
import 'package:untitled8/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:untitled8/features/azkar/presentation/pages/azkar_hadeeth_screen.dart';
import 'package:untitled8/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:untitled8/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Allah names data parses into all entries', () async {
    final json = jsonDecode(
      await rootBundle.loadString(
        'assets/features/asmaa_allah/asmaa_allah.json',
      ),
    );
    final names = LocalAllahNamesDataSource(json).read();

    expect(names, hasLength(98));
    expect(names.first.name, isNotEmpty);
    expect(names.first.meaning, isNotEmpty);
  });

  test(
    'Tasbeeh data loads before counters and supports increment/reset',
    () async {
      final cubit = AzkarCubit(
        dataSource: LocalAzkarDataSource({
          'تسابيح': [
            {'content': 'سبحان الله'},
            {'content': 'الحمد لله'},
          ],
        }),
      );
      addTearDown(cubit.close);

      await cubit.loadContent();
      expect(cubit.itemsFor(3), ['سبحان الله', 'الحمد لله']);
      cubit.initializeCounters(cubit.itemsFor(3).length);
      cubit.incrementAzkarTimes(0);
      expect(cubit.state.counters, [1, 0]);
      cubit.clearTimes(0);
      expect(cubit.state.counters, [0, 0]);
    },
  );

  testWidgets(
    'Allah names screen rebuilds when asynchronous loading completes',
    (tester) async {
      final cubit = AllahNamesCubit(
        dataSource: const LocalAllahNamesDataSource({
          'data': [
            {'name': 'الرَّحْمَنُ', 'text': 'واسع الرحمة'},
            {'name': 'الرَّحِيمُ', 'text': 'كثير الرحمة'},
          ],
        }),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: AsmaaAllahScreen()),
        ),
      );
      final loading = cubit.load();
      await tester.pumpAndSettle();
      await loading;

      expect(find.text('الرَّحْمَنُ'), findsOneWidget);
      expect(find.text('الرَّحِيمُ'), findsOneWidget);
    },
  );

  testWidgets('Surah list keeps balanced side padding in Arabic direction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = QuranCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: Scaffold(body: SurahList(cubit: cubit, online: false)),
      ),
    );
    await tester.pump();

    final list = tester.widget<ListView>(find.byType(ListView).first);
    expect(list.padding, const EdgeInsetsDirectional.fromSTEB(22, 4, 22, 14));
  });

  testWidgets('Surah entry asks to resume bookmark once and resumes verse', (
    tester,
  ) async {
    final cubit = QuranCubit(bookmarkRepository: _BookmarkRepository());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(locale: Locale('ar'), home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.text('البدء من جديد'), findsOneWidget);
    await tester.tap(find.text('متابعة القراءة'));
    await tester.pumpAndSettle();
    expect(find.byType(SurahScreen), findsOneWidget);
    expect(cubit.currentPageNumber, 17);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Surah entry without bookmark shows no resume dialog', (
    tester,
  ) async {
    final cubit = QuranCubit(bookmarkRepository: _EmptyBookmarkRepository());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('متابعة القراءة؟'), findsNothing);
    expect(find.text('البدء من جديد'), findsNothing);
  });

  for (final size in [const Size(320, 568), const Size(800, 1200)]) {
    testWidgets(
      'Quran Tafsir sheet scrolls long Arabic content at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final longTafsir = List.filled(
          120,
          'هذا تفسير مطول للآية الكريمة',
        ).join(' ');

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(
              body: QuranTafsirSheet(
                surahName: 'الفاتحة',
                verseNumber: 1,
                verseText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                palette: const QuranReaderPalette(
                  background: Color(0xFFFFFEFA),
                  surface: Color(0xFFF7F4EA),
                  text: Color(0xFF202B25),
                  muted: Color(0xFF6F7A72),
                  accent: Color(0xFF176B5B),
                  highlight: Color(0x22176B5B),
                  frame: Color(0xFFD8C8A4),
                  ornament: Color(0xFF80633A),
                  metadata: Color(0xFF8B7958),
                ),
                loadTafsir: () async => longTafsir,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('تفسير الآية'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('هذا تفسير مطول').hitTestable(),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'connectivity service checks current internet status immediately',
    () async {
      final service = ConnectivityService(_ConnectedChecker());

      expect(await service.hasConnection, isTrue);
      expect(await service.changes.first, isTrue);
    },
  );

  test('saved app theme preference restores and can be updated', () async {
    SharedPreferences.setMockInitialValues({'isDarkMode': true});
    final quran = QuranCubit();
    final azkar = AzkarCubit();
    final hadeeth = HadeethCubit();
    final prayerTimes = PrayerTimesCubit();
    final cubit = AppCubit(
      connectivity: ConnectivityService(_ConnectedChecker()),
      hadeeth: hadeeth,
      prayerTimes: prayerTimes,
      quran: quran,
      azkar: azkar,
    );
    addTearDown(cubit.close);
    addTearDown(quran.close);
    addTearDown(azkar.close);
    addTearDown(hadeeth.close);
    addTearDown(prayerTimes.close);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state.themeMode, ThemeMode.dark);
    await cubit.setThemeMode(ThemeMode.light);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('isDarkMode'), isFalse);
  });

  testWidgets('shared snackbar replaces rapid messages and renders RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: AppSnackBar.messengerKey,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    AppSnackBar.show(message: 'الرسالة الأولى');
                    AppSnackBar.show(message: 'الرسالة الأخيرة');
                  },
                  child: const Text('Show'),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('الرسالة الأخيرة'), findsOneWidget);
    expect(find.text('الرسالة الأولى'), findsNothing);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.shape, isA<RoundedRectangleBorder>());
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Directionality &&
              widget.textDirection == TextDirection.rtl,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tasbeeh route loads bundled content and counter controls work', (
    tester,
  ) async {
    final cubit = AzkarCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          locale: Locale('ar'),
          home: AzkarAndHadeethScreen(index: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('التسابيحُ'), findsOneWidget);
    expect(cubit.itemsFor(3), isNotEmpty);
    expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pump();
    expect(cubit.state.counters.first, 1);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh).first);
    await tester.pump();
    expect(cubit.state.counters.first, 0);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ConnectedChecker extends InternetConnectionChecker {
  _ConnectedChecker() : super.createInstance();

  @override
  Future<bool> get hasConnection async => true;

  @override
  Stream<InternetConnectionStatus> get onStatusChange =>
      Stream.value(InternetConnectionStatus.connected);
}

class _BookmarkRepository implements QuranBookmarkRepository {
  @override
  Future<QuranBookmark?> read() async =>
      const QuranBookmark(surahNumber: 1, surahName: 'الفاتحة', pageNumber: 17);

  @override
  Future<void> save(QuranBookmark bookmark) async {}

  @override
  Future<void> clear() async {}
}

class _EmptyBookmarkRepository implements QuranBookmarkRepository {
  @override
  Future<QuranBookmark?> read() async => null;

  @override
  Future<void> save(QuranBookmark bookmark) async {}

  @override
  Future<void> clear() async {}
}
