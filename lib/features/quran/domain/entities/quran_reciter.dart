enum QuranReciterCountry { egypt, saudiArabia, kuwait, other }

/// A remotely streamed complete-Surah recitation.
///
/// The stream directories below are the Hafs Murattal entries published by
/// MP3Quran's public reciter catalog. Keep this list as the single source of
/// truth for the picker and URL construction.
class QuranReciter {
  const QuranReciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.serverUrl,
    required this.timingReadId,
    required this.avatarLabel,
    required this.avatarColorValue,
    required this.country,
    this.avatarAsset,
    this.ayahAudioDirectory,
  });

  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String serverUrl;
  final int timingReadId;

  /// Optional bundled portrait. Other reciters use a distinct name-derived avatar.
  final String? avatarAsset;
  final String? ayahAudioDirectory;
  final String avatarLabel;
  final int avatarColorValue;
  final QuranReciterCountry country;

  String displayName({required bool arabic}) =>
      arabic ? nameArabic : nameEnglish;

  String surahUrl(int surahNumber) =>
      '$serverUrl${surahNumber.toString().padLeft(3, '0')}.mp3';

  String? ayahUrl(int surahNumber, int ayahNumber) =>
      ayahAudioDirectory == null
          ? null
          : 'https://everyayah.com/data/$ayahAudioDirectory/' +
              '${surahNumber.toString().padLeft(3, '0')}' +
              '${ayahNumber.toString().padLeft(3, '0')}.mp3';

  static const List<QuranReciter> all = [
    QuranReciter(
      id: 'mp3quran_123',
      nameArabic: 'مشاري العفاسي',
      nameEnglish: 'Mishary Rashid Alafasy',
      serverUrl: 'https://cdn.mp3quran.net/audio/mishary-alafasy/r1/',
      timingReadId: 123,
      ayahAudioDirectory: 'Alafasy_128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_123.jpg',
      avatarLabel: 'مش',
      avatarColorValue: 0xFF315C4C,
      country: QuranReciterCountry.kuwait,
    ),
    QuranReciter(
      id: 'mp3quran_54',
      nameArabic: 'عبدالرحمن السديس',
      nameEnglish: 'Abdul Rahman Al-Sudais',
      serverUrl: 'https://cdn.mp3quran.net/audio/abdulrahman-sudais/r1/',
      timingReadId: 54,
      ayahAudioDirectory: 'Abdurrahmaan_As-Sudais_192kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_54.png',
      avatarLabel: 'عس',
      avatarColorValue: 0xFF426C5A,
      country: QuranReciterCountry.saudiArabia,
    ),
    QuranReciter(
      id: 'mp3quran_30',
      nameArabic: 'سعد الغامدي',
      nameEnglish: 'Saad Al-Ghamdi',
      serverUrl: 'https://cdn.mp3quran.net/audio/saad-ghamdi/r1/',
      timingReadId: 30,
      ayahAudioDirectory: 'Ghamadi_40kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_30.jpg',
      avatarLabel: 'سغ',
      avatarColorValue: 0xFF597A68,
      country: QuranReciterCountry.saudiArabia,
    ),
    QuranReciter(
      id: 'mp3quran_133',
      nameArabic: 'ماهر المعيقلي',
      nameEnglish: 'Maher Al-Muaiqly',
      serverUrl: 'https://cdn.mp3quran.net/audio/maher-muaiqly/r3/',
      timingReadId: 133,
      ayahAudioDirectory: 'MaherAlMuaiqly128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_133.jpg',
      avatarLabel: 'ما',
      avatarColorValue: 0xFF3D6855,
      country: QuranReciterCountry.saudiArabia,
    ),
    QuranReciter(
      id: 'mp3quran_53',
      nameArabic: 'عبدالباسط عبدالصمد',
      nameEnglish: 'Abdul Basit Abdus Samad',
      serverUrl: 'https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r3/',
      timingReadId: 53,
      ayahAudioDirectory: 'Abdul_Basit_Murattal_192kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_53.jpg',
      avatarLabel: 'عب',
      avatarColorValue: 0xFF526F5F,
      country: QuranReciterCountry.egypt,
    ),
    QuranReciter(
      id: 'mp3quran_92',
      nameArabic: 'ياسر الدوسري',
      nameEnglish: 'Yasser Al-Dosari',
      serverUrl: 'https://cdn.mp3quran.net/audio/yasser-dosari/r1/',
      timingReadId: 92,
      ayahAudioDirectory: 'Yasser_Ad-Dussary_128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_92.jpg',
      avatarLabel: 'يد',
      avatarColorValue: 0xFF6B8674,
      country: QuranReciterCountry.saudiArabia,
    ),
    QuranReciter(
      id: 'mp3quran_86',
      nameArabic: 'ناصر القطامي',
      nameEnglish: 'Nasser Al-Qatami',
      serverUrl: 'https://cdn.mp3quran.net/audio/nasser-qatami/r1/',
      timingReadId: 86,
      ayahAudioDirectory: 'Nasser_Alqatami_128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_86.jpg',
      avatarLabel: 'نق',
      avatarColorValue: 0xFF426350,
      country: QuranReciterCountry.saudiArabia,
    ),
    QuranReciter(
      id: 'mp3quran_118',
      nameArabic: 'محمود خليل الحصري',
      nameEnglish: 'Mahmoud Khalil Al-Hussary',
      serverUrl: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r1/',
      timingReadId: 118,
      ayahAudioDirectory: 'Husary_128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_118.jpg',
      avatarLabel: 'مح',
      avatarColorValue: 0xFF647D6C,
      country: QuranReciterCountry.egypt,
    ),
    QuranReciter(
      id: 'mp3quran_112',
      nameArabic: 'محمد صديق المنشاوي',
      nameEnglish: 'Mohamed Siddiq El-Minshawi',
      serverUrl: 'https://cdn.mp3quran.net/audio/muhammad-minshawi/r1/',
      timingReadId: 112,
      ayahAudioDirectory: 'Minshawy_Murattal_128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_112.jpg',
      avatarLabel: 'من',
      avatarColorValue: 0xFF557360,
      country: QuranReciterCountry.egypt,
    ),
    QuranReciter(
      id: 'mp3quran_122',
      nameArabic: 'محمود علي البنا',
      nameEnglish: 'Mahmoud Ali Al-Banna',
      serverUrl: 'https://cdn.mp3quran.net/audio/mahmoud-banna/r2/',
      timingReadId: 122,
      ayahAudioDirectory: 'mahmoud_ali_al_banna_32kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_122.jpg',
      avatarLabel: 'مب',
      avatarColorValue: 0xFF765D4D,
      country: QuranReciterCountry.egypt,
    ),
    QuranReciter(
      id: 'mp3quran_31',
      nameArabic: 'سعود الشريم',
      nameEnglish: 'Saud Al-Shuraim',
      serverUrl: 'https://cdn.mp3quran.net/audio/saud-shuraim/r1/',
      timingReadId: 31,
      ayahAudioDirectory: 'Saood_ash-Shuraym_128kbps',
      avatarAsset: 'assets/images/reciters/mp3quran_31.png',
      avatarLabel: 'سش',
      avatarColorValue: 0xFF526B75,
      country: QuranReciterCountry.saudiArabia,
    ),
  ];

  /// Reciters grouped in the picker priority order, while preserving catalog
  /// order within each nationality.
  static List<QuranReciter> get orderedByCountry => [
    for (final country in QuranReciterCountry.values)
      ...all.where((reciter) => reciter.country == country),
  ];

  static QuranReciter byId(String? id) => all.firstWhere(
    (reciter) => reciter.id == (id == 'mp3quran_102' ? 'mp3quran_133' : id),
    orElse: () => all.first,
  );
}
