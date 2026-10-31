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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: colors.primaryContainer, child: Icon(Icons.mosque_outlined, color: colors.primary)),
            const SizedBox(width: 14),
            Expanded(child: Text(name, textDirection: TextDirection.rtl, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            Text('$time $period', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
