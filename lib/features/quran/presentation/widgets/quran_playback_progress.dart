import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

/// Shared Ayah-aware scrubber used by the reader and the Mini Player.
class QuranPlaybackProgress extends StatelessWidget {
  const QuranPlaybackProgress({
    super.key,
    required this.cubit,
    required this.palette,
    this.showTimeLabels = false,
  });

  final QuranCubit cubit;
  final QuranReaderPalette palette;
  final bool showTimeLabels;

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration?>(
    stream: cubit.audioDurationStream,
    initialData: cubit.audioDuration,
    builder: (context, durationState) {
      final duration = durationState.data;
      if (duration != null &&
          duration.inMilliseconds > 0) {
        return StreamBuilder<Duration>(
          stream: cubit.audioPositionStream,
          initialData: cubit.audioPosition,
          builder: (context, positionState) {
            final position = positionState.data ?? Duration.zero;
            final progress = (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble();
            return _ProgressRow(
              value: progress,
              sliderLabel: 'موضع التلاوة',
              semanticValue:
                  '${toArabicIndicDigits((progress * 100).round())}٪',
              leadingLabel: showTimeLabels ? _formatDuration(position) : null,
              trailingLabel: showTimeLabels ? _formatDuration(duration) : null,
              palette: palette,
              onSeek: cubit.seekToAyahProgress,
            );
          },
        );
      }

      final verseCount = cubit.currentSurahVerseCount;
      if (verseCount < 1) return const SizedBox.shrink();
      final ayah = cubit.currentAyahNumber.clamp(1, verseCount);
      final progress = verseCount == 1
          ? 0.0
          : ((ayah - 1) / (verseCount - 1)).clamp(0.0, 1.0).toDouble();
      return _ProgressRow(
        value: progress,
        sliderLabel: 'اختيار الآية',
        semanticValue:
            'الآية ${toArabicIndicDigits(ayah)} من ${toArabicIndicDigits(verseCount)}',
        leadingLabel: showTimeLabels ? 'آية ${toArabicIndicDigits(ayah)}' : null,
        trailingLabel:
            showTimeLabels ? '${toArabicIndicDigits(verseCount)} آية' : null,
        palette: palette,
        onSeek: cubit.selectAyahByProgress,
      );
    },
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.value,
    required this.sliderLabel,
    required this.semanticValue,
    required this.palette,
    required this.onSeek,
    this.leadingLabel,
    this.trailingLabel,
  });

  final double value;
  final String sliderLabel;
  final String semanticValue;
  final String? leadingLabel;
  final String? trailingLabel;
  final QuranReaderPalette palette;
  final Future<void> Function(double value) onSeek;

  @override
  Widget build(BuildContext context) {
    final slider = _DraggableProgress(
      value: value,
      label: sliderLabel,
      semanticValue: semanticValue,
      accent: palette.accent,
      track: palette.frame.withValues(alpha: .35),
      onSeek: onSeek,
    );
    if (leadingLabel == null || trailingLabel == null) return slider;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          _TimeLabel(text: leadingLabel!, palette: palette),
          const SizedBox(width: 7),
          Expanded(child: slider),
          const SizedBox(width: 7),
          _TimeLabel(text: trailingLabel!, palette: palette),
        ],
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.text, required this.palette});

  final String text;
  final QuranReaderPalette palette;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(
        color: palette.muted,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final value = hours > 0
      ? '$hours:$minutes:$seconds'
      : '${duration.inMinutes.toString().padLeft(2, '0')}:$seconds';
  return toArabicIndicDigits(value);
}

class _DraggableProgress extends StatefulWidget {
  const _DraggableProgress({
    required this.value,
    required this.label,
    required this.semanticValue,
    required this.accent,
    required this.track,
    required this.onSeek,
  });

  final double value;
  final String label;
  final String semanticValue;
  final Color accent;
  final Color track;
  final Future<void> Function(double value) onSeek;

  @override
  State<_DraggableProgress> createState() => _DraggableProgressState();
}

class _DraggableProgressState extends State<_DraggableProgress> {
  double? _dragValue;

  double _valueAt(double dx, double width) {
    if (width <= 0) return widget.value;
    final physicalProgress = (dx / width).clamp(0.0, 1.0).toDouble();
    return Directionality.of(context) == TextDirection.rtl
        ? 1 - physicalProgress
        : physicalProgress;
  }

  void _updateDrag(double dx, double width) {
    setState(() => _dragValue = _valueAt(dx, width));
  }

  Future<void> _commitSeek(double value) async {
    try {
      await widget.onSeek(value);
    } finally {
      if (mounted) setState(() => _dragValue = null);
    }
  }

  void _finishDrag() {
    final value = _dragValue;
    if (value != null) unawaited(_commitSeek(value));
  }

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.value;
    return Semantics(
      slider: true,
      label: widget.label,
      value: widget.semanticValue,
      onIncrease: () => unawaited(
        _commitSeek((widget.value + .01).clamp(0.0, 1.0).toDouble()),
      ),
      onDecrease: () => unawaited(
        _commitSeek((widget.value - .01).clamp(0.0, 1.0).toDouble()),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => unawaited(
            _commitSeek(
              _valueAt(details.localPosition.dx, constraints.maxWidth),
            ),
          ),
          onHorizontalDragStart: (details) =>
              _updateDrag(details.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _updateDrag(details.localPosition.dx, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _finishDrag(),
          onHorizontalDragCancel: _finishDrag,
          child: SizedBox(
            height: 22,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: widget.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(value * 2 - 1, 0),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: .22),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
