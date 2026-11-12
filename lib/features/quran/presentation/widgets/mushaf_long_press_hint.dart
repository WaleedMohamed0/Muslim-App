import 'package:flutter/material.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

class MushafLongPressHint extends StatelessWidget {
  const MushafLongPressHint({
    super.key,
    required this.palette,
    required this.onDismiss,
  });

  final QuranReaderPalette palette;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 7, 11),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            palette.accent.withValues(alpha: .055),
            palette.surface,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.ornament.withValues(alpha: .26)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.touch_app_rounded,
                color: palette.accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اضغط مطولًا على أي آية',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'لعرض التفسير واكتشاف المزيد من الخيارات.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'إغلاق',
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.close_rounded, size: 17, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
