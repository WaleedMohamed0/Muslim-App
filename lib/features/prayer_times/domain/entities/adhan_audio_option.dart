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
      id: 'adhan_madinah',
      name: 'أذان المدينة المنورة',
      assetPath: 'assets/features/prayer_times/audio/المدينة المنورة.mp3',
    ),
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
  ];

  static AdhanAudioOption byId(String? id) => options.firstWhere(
    (option) => option.id == id,
    orElse: () => options.first,
  );
}
