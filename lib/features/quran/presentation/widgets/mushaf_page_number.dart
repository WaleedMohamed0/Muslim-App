part of 'mushaf_text_page.dart';

class _MushafPageNumber extends StatelessWidget {
  const _MushafPageNumber({required this.pageNumber, required this.palette});

  final int pageNumber;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.spa_outlined, size: 13, color: palette.ornament),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: palette.ornament),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: palette.ornament.withValues(alpha: .55)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            child: Text(
              toArabicIndicDigits(pageNumber),
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: palette.metadata,
              fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      Icon(Icons.spa_outlined, size: 13, color: palette.ornament),
    ],
  );
}



