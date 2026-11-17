part of 'muslim_app.dart';

/// Cold-start fallback for a widget Play tap when Android has recreated the
/// media service without its prepared audio source. It uses the app's existing
/// QuranCubit and its single shared player.
class _QuranWidgetPlaybackScreen extends StatefulWidget {
  const _QuranWidgetPlaybackScreen({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  State<_QuranWidgetPlaybackScreen> createState() =>
      _QuranWidgetPlaybackScreenState();
}

class _QuranWidgetPlaybackScreenState
    extends State<_QuranWidgetPlaybackScreen> {
  bool _playRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_playRequested) return;
    _playRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<QuranCubit>().playFromAyahBookmark(
          widget.surahNumber,
          widget.ayahNumber,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => SurahScreen(
    surahNumber: widget.surahNumber,
    initialAyah: widget.ayahNumber,
  );
}
