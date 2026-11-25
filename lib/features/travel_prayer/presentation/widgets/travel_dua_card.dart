import 'package:material_ui/material_ui.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muslim/features/app/presentation/widgets/notification_logo.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_share_card.dart';
import '../../data/travel_dua.dart';

class TravelDuaCard extends StatefulWidget {
  const TravelDuaCard({super.key});

  @override
  State<TravelDuaCard> createState() => _TravelDuaCardState();
}

class _TravelDuaCardState extends State<TravelDuaCard> {
  static const MethodChannel _shareChannel =
      MethodChannel('com.muslim/quran_share');
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _shareText() => _shareChannel.invokeMethod<void>('shareText', {
    'text': '${TravelDua.fullText}\n\nالمصدر: ${TravelDua.reference}',
    'title': 'دعاء السفر',
  });

  Future<void> _shareImage() async {
    OverlayEntry? entry;
    try {
      await NotificationLogo.preload();
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: AzkarShareCard(
            text: TravelDua.fullText,
            category: 'دعاء السفر',
            captureKey: _captureKey,
          ),
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/azkar-card.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await _shareChannel.invokeMethod<void>('shareImage', {
        'path': file.path,
        'title': 'مشاركة دعاء',
      });
    } catch (_) {
    } finally {
      entry?.remove();
    }
  }

  Future<void> _showShareOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: const Text('مشاركة كنص'),
              onTap: () => Navigator.pop(ctx, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('مشاركة كصورة'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (option == 'image') await _shareImage();
    if (option == 'text') await _shareText();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.flight_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('دعاء السفر', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              IconButton(
                tooltip: 'مشاركة دعاء السفر',
                style: IconButton.styleFrom(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showShareOptions,
                icon: const Icon(Icons.share_rounded),
              ),
            ]),
            const SizedBox(height: 12),
            _DuaSection(
              title: 'عند بدء السفر',
              text: TravelDua.departureSupplication,
              showTravelVerseNumbers: true,
            ),
            const SizedBox(height: 12),
            _DuaSection(title: 'عند الرجوع من السفر', text: TravelDua.returnSupplication),
            const SizedBox(height: 10),
            Text('المصدر: ${TravelDua.reference}', style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

}

class _DuaSection extends StatelessWidget {
  const _DuaSection({
    required this.title,
    required this.text,
    this.showTravelVerseNumbers = false,
  });
  final String title;
  final String text;
  final bool showTravelVerseNumbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: theme.textTheme.labelLarge?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (showTravelVerseNumbers) ...[
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
              children: [
                TextSpan(text: TravelDua.departureVerseOne),
                const TextSpan(
                  text: ' ۝١٣',
                  style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 20),
                ),
                TextSpan(text: ' ${TravelDua.departureVerseTwo}'),
                const TextSpan(
                  text: ' ۝١٤',
                  style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 20),
                ),
                const TextSpan(text: ' {سورة الزُّخْرُف}'),
              ],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.start, style: theme.textTheme.bodyLarge?.copyWith(height: 1.9)),
        ] else
          Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.start, style: theme.textTheme.bodyLarge?.copyWith(height: 1.9)),
      ]),
    );
  }
}
