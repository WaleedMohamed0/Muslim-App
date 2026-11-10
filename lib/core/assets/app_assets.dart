class AppAssets {
  static const appLogo = 'assets/features/app/images/logo.png';
  static const quranLogo = 'assets/features/app/images/quran_logo.webp';
  static const quranFont =
      'assets/features/quran/fonts/UthmanicHafs-v-3.0.ttf';
  static const azan = 'assets/features/prayer_times/audio/المدينة المنورة.mp3';
  static const adhanFajrBackground =
      'assets/features/prayer_times/images/adhan_fajr.webp';
  static const adhanDhuhrBackground =
      'assets/features/prayer_times/images/adhan_dhuhr.webp';
  static const adhanAsrBackground =
      'assets/features/prayer_times/images/adhan_asr.webp';
  static const adhanMaghribBackground =
      'assets/features/prayer_times/images/adhan_maghrib.webp';
  static const adhanIshaBackground =
      'assets/features/prayer_times/images/adhan_nabawi_night.webp';

  static String adhanBackgroundForPrayer(String prayer) =>
      switch (prayer.trim()) {
        'fajr' || 'الفجر' || 'الْفَجْر' => adhanFajrBackground,
        'dhuhr' || 'الظهر' || 'الظُّهْر' => adhanDhuhrBackground,
        'asr' || 'العصر' || 'الْعَصْر' => adhanAsrBackground,
        'maghrib' || 'المغرب' || 'الْمَغْرِب' => adhanMaghribBackground,
        'isha' || 'العشاء' || 'الْعِشَاء' => adhanIshaBackground,
        _ => adhanIshaBackground,
      };
  static const azkarData = 'assets/features/azkar/data/azkar.json';
  static const allahNamesData = 'assets/features/asmaa_allah/asmaa_allah.json';
}
