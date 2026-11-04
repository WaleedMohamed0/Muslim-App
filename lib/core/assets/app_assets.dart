class AppAssets {
  static const appLogo = 'assets/features/app/images/logo.png';
  static const quranLogo = 'assets/features/app/images/quran_logo.png';
  static const quranFont = 'assets/features/quran/fonts/quran.ttf';
  static const azan = 'assets/features/prayer_times/audio/المدينة المنورة.mp3';
  static const adhanFajrBackground =
      'assets/features/prayer_times/images/adhan_fajr.jpg';
  static const adhanDhuhrBackground =
      'assets/features/prayer_times/images/adhan_dhuhr.jpg';
  static const adhanAsrBackground =
      'assets/features/prayer_times/images/adhan_asr.jpg';
  static const adhanMaghribBackground =
      'assets/features/prayer_times/images/adhan_maghrib.jpg';
  static const adhanIshaBackground =
      'assets/features/prayer_times/images/adhan_nabawi_night.jpg';

  static String adhanBackgroundForPrayer(String prayer) =>
      switch (prayer.trim()) {
        'الفجر' => adhanFajrBackground,
        'الظهر' => adhanDhuhrBackground,
        'العصر' => adhanAsrBackground,
        'المغرب' => adhanMaghribBackground,
        'العشاء' => adhanIshaBackground,
        _ => adhanIshaBackground,
      };
  static const azkarData = 'assets/features/azkar/data/azkar.json';
  static const storiesData = 'assets/features/stories/stories.json';
  static const prophetsCardBackground =
      'assets/features/prayer_times/images/Masjid.jpg';
  static const seerahCardBackground =
      'assets/features/prayer_times/images/MasjidElnabwy.png';
  static const allahNamesData = 'assets/features/asmaa_allah/asmaa_allah.json';
}
