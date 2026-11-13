import 'package:flutter/material.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

class MushafZoomHint extends StatelessWidget {
  const MushafZoomHint({
    super.key,
    required this.palette,
    required this.onDismiss,
  });

  final QuranReaderPalette palette;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 5, 9),
      decoration: BoxDecoration(
        color: Color.alphaBlend(palette.accent.withValues(alpha: .07), palette.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.ornament.withValues(alpha: .26)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pinch_rounded, color: palette.accent, size: 22),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'يمكنك تكبير وتصغير المصحف باستخدام إصبعين',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(color: palette.text, fontSize: 12, height: 1.4),
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.close_rounded, size: 16, color: palette.muted),
          ),
        ],
      ),
    ),
  );
}
