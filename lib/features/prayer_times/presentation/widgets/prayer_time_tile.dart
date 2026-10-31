import 'package:flutter/material.dart';

class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({super.key, required this.name, required this.time, required this.period});
  final String name;
  final String time;
  final String period;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(child: Text(name, textAlign: TextAlign.start, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            Directionality(textDirection: TextDirection.ltr, child: Text('$time $period', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800))),
            const SizedBox(width: 14),
            CircleAvatar(backgroundColor: colors.primaryContainer, child: Icon(Icons.mosque_outlined, color: colors.primary)),
          ],
        ),
      ),
    );
  }
}
