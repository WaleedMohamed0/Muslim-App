import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/daily_ayah/domain/entities/daily_ayah.dart';
import 'package:muslim/features/daily_ayah/presentation/widgets/daily_ayah_share_card.dart';
import 'package:path_provider/path_provider.dart';

class DailyAyahScreen extends StatefulWidget {
  const DailyAyahScreen({super.key, required this.ayah});

  final DailyAyah ayah;

  @override
  State<DailyAyahScreen> createState() => _DailyAyahScreenState();
}

class _DailyAyahScreenState extends State<DailyAyahScreen> {
  final GlobalKey _captureKey = GlobalKey();
  static const MethodChannel _shareChannel = MethodChannel('com.muslim/quran_share');
  bool _sharing = false;

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    OverlayEntry? entry;
    try {
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: DailyAyahShareCard(ayah: widget.ayah, captureKey: _captureKey),
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/daily-ayah.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await _shareChannel.invokeMethod<void>('shareImage', {
        'path': file.path,
        'title': 'مشاركة آية اليوم',
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّرت مشاركة الصورة')),
        );
      }
    } finally {
      entry?.remove();
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('آية اليوم'),
        actions: [
          IconButton(
            tooltip: 'مشاركة الآية كصورة',
            onPressed: _sharing ? null : _shareImage,
            icon: _sharing ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 30, color: colors.primary),
                    const SizedBox(height: 20),
                    Text(
                      widget.ayah.text,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: 'UthmanicHafs',
                        height: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Divider(color: colors.primary.withValues(alpha: .25)),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.ayah.surahName} • ${toArabicIndicDigits(widget.ayah.ayahNumber)}',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
