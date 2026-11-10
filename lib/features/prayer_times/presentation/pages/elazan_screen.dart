import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/assets/app_assets.dart';
import 'package:muslim/features/app/presentation/pages/startup_screen.dart';
import 'package:muslim/features/app/data/repositories/prayer_wird_progress_repository.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';

class ElAzanScreen extends StatefulWidget {
  const ElAzanScreen({super.key, required this.prayer});

  final String prayer;

  @override
  State<ElAzanScreen> createState() => _ElAzanScreenState();
}

class _ElAzanScreenState extends State<ElAzanScreen> with WidgetsBindingObserver {
  Timer? _playbackPoller;
  bool _isPlaying = false;
  bool _stopping = false;
  bool _heardAzanPlaying = false;
  final _prayerWirdProgress = PrayerWirdProgressRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPlaybackState());
    _playbackPoller = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_refreshPlaybackState()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackPoller?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshPlaybackState());
  }

  Future<void> _refreshPlaybackState() async {
    try {
      final state = await PrayerAdhanService.instance.getPlaybackState();
      if (!mounted) return;
      final playing = state['playing'] == true;
      if (playing) _heardAzanPlaying = true;
      if (_heardAzanPlaying && !playing && !_stopping) {
        _heardAzanPlaying = false;
        await _prayerWirdProgress.markFirstAzanFinished();
      }
      if (_isPlaying != playing) {
        setState(() => _isPlaying = playing);
      }
    } catch (_) {}
  }

  Future<void> _stopAzan() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await _stopPlayback();
      if (mounted) setState(() => _isPlaying = false);
      _returnHome();
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await context.read<QuranCubit>().stopAzan();
    } catch (_) {}
    try {
      await PrayerAdhanService.instance.stopAudio();
    } catch (_) {}
  }

  void _returnHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const StartUpScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _close() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    try {
      await _stopPlayback();
      _returnHome();
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The Isha photo is a night scene; keep its overlay dark in light mode too
    // so the image does not get washed out by the light surface gradient.
    final isDark =
        theme.brightness == Brightness.dark ||
        widget.prayer.trim() == 'الْعِشَاء';
    const azanNight = Color(0xFF10231F);
    const foreground = Colors.white;
    final mutedForeground = Colors.white.withValues(alpha: .88);
    final subtitleForeground = Colors.white.withValues(alpha: .82);
    final surfaceOverlay = Colors.black.withValues(alpha: .38);
    final borderOverlay = Colors.white.withValues(alpha: .28);
    final badgeBorder = Colors.white.withValues(alpha: .22);
    return Scaffold(
      backgroundColor: isDark ? azanNight : theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.adhanBackgroundForPrayer(widget.prayer),
            fit: BoxFit.cover,
          ),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55000000), Color(0x99000000)]))),
          PositionedDirectional(
            top: -86,
            end: -72,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .16),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'إغلاق وإيقاف الأذان',
                              onPressed: _close,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    surfaceOverlay,
                                foregroundColor: foreground,
                              ),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                12,
                                8,
                                12,
                                8,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceOverlay,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: badgeBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mosque_rounded,
                                    color: foreground,
                                    size: 18,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'تنبيه الصَّلَاة',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      color: foreground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: surfaceOverlay,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderOverlay,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: foreground,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'حان الآن وقت صَلَاة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.prayer,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'حيّ على الصَّلَاة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: subtitleForeground,
                            letterSpacing: .2,
                          ),
                        ),
                        const Spacer(),
                        if (_isPlaying) ...[
                          FilledButton.icon(
                            onPressed: _stopping ? null : _stopAzan,
                            icon: _stopping
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.stop_rounded),
                            label: const Text('إيقاف الأذان'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
