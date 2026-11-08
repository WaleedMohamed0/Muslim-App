/// Local illustration assets used by the worship lessons.
abstract final class WorshipIllustrationAssets {
  static const _wudu = <String>[
    'assets/features/worship/illustrations/wudu_step_1.webp',
    'assets/features/worship/illustrations/wudu_step_2.webp',
    'assets/features/worship/illustrations/wudu_step_3.webp',
    'assets/features/worship/illustrations/wudu_step_4.webp',
    'assets/features/worship/illustrations/wudu_step_5.webp',
    'assets/features/worship/illustrations/wudu_step_6.webp',
    'assets/features/worship/illustrations/wudu_step_7.webp',
    'assets/features/worship/illustrations/wudu_step_8.webp',
    'assets/features/worship/illustrations/wudu_step_9.webp',
  ];

  static const _prayerIllustrationNames = <String>[
    'opening_takbir.webp',
    'standing_recitation.webp',
    'bowing.webp',
    'rise_from_bowing.webp',
    'prostration.webp',
    'sitting_between_prostrations.webp',
    'second_prostration.webp',
    'tashahhud.webp',
    'taslim.webp',
  ];

  static String wuduStep(int index) => _wudu[index];

  static String prayerStep(int index) =>
      'assets/features/worship/illustrations/salah_${_prayerIllustrationNames[index]}';
}
