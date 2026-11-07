import 'package:flutter/material.dart';

import '../../data/worship_ui_strings.dart';
import '../widgets/prayer_quiz_card.dart';

class WuduQuizScreen extends StatelessWidget {
  const WuduQuizScreen({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text(WorshipUiStrings.wuduQuizTitle)),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 32),
                  children: const [PrayerQuizCard(lessonId: 'wudu')],
                ),
              ),
            ),
          ),
        ),
      );
}
