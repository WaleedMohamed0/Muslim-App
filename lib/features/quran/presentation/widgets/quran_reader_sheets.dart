import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

class AyahActionSheet extends StatelessWidget {
  const AyahActionSheet({
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.palette,
    required this.isBookmarked,
    required this.onTafsir,
    required this.onCopy,
    required this.onBookmark,
    required this.onShare,
    required this.onPlayAyahOnly,
    required this.onPlayFromAyah,
  });

  final String surahName;
  final int verseNumber;
  final String verseText;
  final QuranReaderPalette palette;
  final bool isBookmarked;
  final VoidCallback onTafsir;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onPlayAyahOnly;
  final VoidCallback onPlayFromAyah;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$surahName • الآية ${toArabicIndicDigits(verseNumber)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            verseText,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              color: palette.text,
              fontSize: 22,
              height: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AyahActionTile(
          icon: Icons.play_arrow_rounded,
          label: 'تشغيل الآية فقط',
          color: palette.text,
          onTap: onPlayAyahOnly,
        ),
        if (isBookmarked)
          _AyahActionTile(
            icon: Icons.play_circle_outline_rounded,
            label: 'تشغيل من هذه الآية',
            color: palette.text,
            onTap: onPlayFromAyah,
          ),
        _AyahActionTile(
          icon: Icons.menu_book_rounded,
          label: 'التفسير',
          color: palette.text,
          onTap: onTafsir,
        ),
        _AyahActionTile(
          icon: Icons.copy_rounded,
          label: 'نسخ الآية',
          color: palette.text,
          onTap: onCopy,
        ),
        _AyahActionTile(
          icon:
              isBookmarked
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
          label: isBookmarked ? 'إزالة العلامة' : 'حفظ كعلامة',
          color: palette.text,
          onTap: onBookmark,
        ),
        _AyahActionTile(
          icon: Icons.share_outlined,
          label: 'مشاركة',
          color: palette.text,
          onTap: onShare,
        ),
      ],
    ),
  );
}

class _AyahActionTile extends StatelessWidget {
  const _AyahActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: color),
    title: Text(
      label,
      textAlign: TextAlign.start,
      style: TextStyle(color: color),
    ),
    onTap: onTap,
  );
}

class QuranTafsirSheet extends StatefulWidget {
  const QuranTafsirSheet({
    super.key,
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.palette,
    required this.loadTafsir,
  });

  final String surahName;
  final int verseNumber;
  final String verseText;
  final QuranReaderPalette palette;
  final Future<String> Function() loadTafsir;

  @override
  State<QuranTafsirSheet> createState() => _QuranTafsirSheetState();
}

class _QuranTafsirSheetState extends State<QuranTafsirSheet> {
  late Future<String> _tafsir;

  @override
  void initState() {
    super.initState();
    _tafsir = widget.loadTafsir();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .46,
      maxChildSize: .96,
          builder:
              (context, scrollController) => SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 22, 24),
                    children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تفسير الآية',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: palette.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.surahName} • الآية ${toArabicIndicDigits(widget.verseNumber)}',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.verseText,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 23,
                      height: 1.9,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'التفسير الميسر',
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _tafsir,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: palette.accent,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تعذر تحميل التفسير. تحقق من الاتصال وحاول مجددًا.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.text),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed:
                                  () => setState(
                                    () => _tafsir = widget.loadTafsir(),
                                  ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                              style: TextButton.styleFrom(
                                foregroundColor: palette.accent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Text(
                      snapshot.data!,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        height: 1.9,
                      ),
                    );
                  },
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}


