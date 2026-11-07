/// Local illustration assets used by the worship lessons.
abstract final class WorshipIllustrationAssets {
  static const _wudu = <String>[
    'assets/features/worship/illustrations/wudu_step_1.png',
    'assets/features/worship/illustrations/wudu_step_2.png',
    'assets/features/worship/illustrations/wudu_step_3.png',
    'assets/features/worship/illustrations/wudu_step_4.png',
    'assets/features/worship/illustrations/wudu_step_5.png',
    'assets/features/worship/illustrations/wudu_step_6.png',
    'assets/features/worship/illustrations/wudu_step_7.png',
    'assets/features/worship/illustrations/wudu_step_8.png',
    'assets/features/worship/illustrations/wudu_step_9.png',
  ];

  static const _prayerIllustrationNames = <String>[
    'opening_takbir.png',
    'standing_recitation.png',
    'bowing.png',
    'rise_from_bowing.png',
    'prostration.png',
    'sitting_between_prostrations.png',
    'second_prostration.png',
    'tashahhud.png',
    'taslim.png',
  ];

  static String wuduStep(int index) => _wudu[index];

  static String prayerStep(int index) =>
      'assets/features/worship/illustrations/salah_${_prayerIllustrationNames[index]}';
}
