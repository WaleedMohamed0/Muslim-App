import '../domain/entities/travel_lesson.dart';

class TravelPrayerContent {
  static const lessons = <TravelLesson>[
    TravelLesson(id: 'qasar', title: 'قصر الصَّلَاة', icon: 'short'),
    TravelLesson(id: 'jam', title: 'جمع الصَّلَاة', icon: 'combine'),
    TravelLesson(id: 'table', title: 'جدول صَلَاة الْمُسَافِر', icon: 'table'),
    TravelLesson(id: 'rules', title: 'أحكام مهمة للمسافر', icon: 'info'),
    TravelLesson(id: 'scenarios', title: 'مواقف تطبيقية', icon: 'route'),
  ];

  static const sources = <(String, String)>[
    ('الْقُرْآن الكريم: سُورَة النساء، الْآيَة ١٠١', 'https://quran.com/4/101'),
    ('صحيح مسلم: صَلَاة السَّفَر ركعتين', 'https://sunnah.com/muslim:685a'),
    ('سنن أبي داود ١٢٠١: قصر النَّبِيّ ﷺ في السَّفَر', 'https://sunnah.com/abudawud:1201'),
    ('فتوى ابن باز: مسافة السَّفَر وأحكامه', 'https://binbaz.org.sa/fatwas/5023'),
    ('فتوى ابن باز: القصر والجمع', 'https://binbaz.org.sa/fatwas/10965'),
    ('الْإِسْلَام سؤال وجواب: مسافة القصر', 'https://islamqa.info/ar/answers/38079'),
  ];
}
