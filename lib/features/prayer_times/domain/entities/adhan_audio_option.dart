class AdhanAudioOption {
  const AdhanAudioOption({
    required this.id,
    required this.name,
    required this.assetPath,
  });

  final String id;
  final String name;
  final String assetPath;

  static const options = <AdhanAudioOption>[
    AdhanAudioOption(
      id: 'adhan_abdulbasit',
      name: 'الشيخ عبد الباسط عبد الصمد',
      assetPath: 'assets/features/prayer_times/audio/عبدالباسط.mp3',
    ),
    AdhanAudioOption(
      id: 'adhan_makkah',
      name: 'أذان مكة المكرمة',
      assetPath: 'assets/features/prayer_times/audio/مكة.mp3',
    ),
    AdhanAudioOption(
      id: 'adhan_madinah_new',
      name: 'أذان المدينة المنورة',
      assetPath: 'assets/features/prayer_times/audio/اذان المدينة المنورة.mp3',
    ),
    AdhanAudioOption(
      id: 'adhan_mohamed_refaat',
      name: 'الشيخ محمد رفعت',
      assetPath: 'assets/features/prayer_times/audio/اذان محمد رفعت.mp3',
    ),
    AdhanAudioOption(
      id: 'adhan_mahmoud_albanna',
      name: 'الشيخ محمود علي البنا',
      assetPath: 'assets/features/prayer_times/audio/اذان محمود البنا.mp3',
    ),
    AdhanAudioOption(
      id: 'adhan_nasser_alqatami',
      name: 'الشيخ ناصر القطامي',
      assetPath: 'assets/features/prayer_times/audio/اذان ناصر القطامي.mp3',
    ),
    AdhanAudioOption(
      id: 'adhan_nasr_eldin',
      name: 'الشيخ نصر الدين',
      assetPath: 'assets/features/prayer_times/audio/اذان نصر الدين.mp3',
    ),
  ];

  static AdhanAudioOption byId(String? id) => options.firstWhere(
    (option) => option.id == (id == 'adhan_madinah' ? 'adhan_madinah_new' : id),
    orElse: () => options.first,
  );
}
