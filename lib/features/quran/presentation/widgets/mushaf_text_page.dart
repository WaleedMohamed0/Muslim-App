import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/features/quran/data/data_sources/uthmani_quran_text.dart';
import 'package:muslim/features/quran/data/data_sources/mushaf_line_layout_data.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/surah_name_header.dart';
part 'mushaf_page_layout.dart';
part 'mushaf_verse_text.dart';
part 'mushaf_verse_marker.dart';
part 'mushaf_page_number.dart';

class MushafTextPage extends StatefulWidget {
  const MushafTextPage({
    required this.pageNumber,
    required this.zoomController,
    required this.zoomScale,
    required this.palette,
    required this.onAyahLongPress,
    required this.onInteractionEnd,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.highlightedSurahNumber,
    this.highlightedAyahNumber,
    this.bookmarkedAyahKeys = const <String>{},
  });

  final int pageNumber;
  final TransformationController zoomController;
  final double zoomScale;
  final QuranReaderPalette palette;
  final void Function(int surahNumber, int verseNumber) onAyahLongPress;
  final VoidCallback onInteractionEnd;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final int? highlightedSurahNumber;
  final int? highlightedAyahNumber;
  final Set<String> bookmarkedAyahKeys;

  @override
  State<MushafTextPage> createState() => MushafTextPageState();
}

class MushafTextPageState extends State<MushafTextPage>
    with SingleTickerProviderStateMixin {
  final Map<int, Offset> _pointerStarts = {};
  late final AnimationController _recenterController;
  Animation<Matrix4>? _recenterAnimation;
  double? _interactionStartScale;
  bool _pointerGestureMoved = false;

  @override
  void initState() {
    super.initState();
    _recenterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final animation = _recenterAnimation;
        if (animation != null) widget.zoomController.value = animation.value;
      });
  }

  @override
  void dispose() {
    _recenterController.dispose();
    super.dispose();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _interactionStartScale =
        widget.zoomController.value.getMaxScaleOnAxis();
    _recenterController.stop();
  }

  void _onInteractionEnd(ScaleEndDetails details, Size viewportSize) {
    final startScale = _interactionStartScale;
    final endScale = widget.zoomController.value.getMaxScaleOnAxis();
    if (startScale != null && startScale > endScale) {
      // InteractiveViewer may finish its pan inertia after this callback.
      // Start recentering after that motion so it cannot overwrite the target.
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        final current = widget.zoomController.value;
        final scale = current.getMaxScaleOnAxis();
        final centered = Matrix4.diagonal3Values(scale, scale, 1)
          ..setTranslationRaw(
            (viewportSize.width - viewportSize.width * scale) / 2,
            (viewportSize.height - viewportSize.height * scale) / 2,
            0,
          );
        _recenterAnimation = Matrix4Tween(
          begin: current.clone(),
          end: centered,
        ).animate(CurvedAnimation(
          parent: _recenterController,
          curve: Curves.easeOut,
        ));
        _recenterController.forward(from: 0);
      });
    }
    _interactionStartScale = null;
    widget.onInteractionEnd();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerStarts.isEmpty) _pointerGestureMoved = false;
    _pointerStarts[event.pointer] = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _pointerStarts[event.pointer];
    if (start != null && (event.position - start).distance > 18) {
      _pointerGestureMoved = true;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final pointerCount = _pointerStarts.length;
    final start = _pointerStarts.remove(event.pointer);
    if (start == null ||
        pointerCount != 1 ||
        !_pointerGestureMoved ||
        widget.zoomScale > 1.01) {
      return;
    }

    final delta = event.position - start;
    if (delta.dx.abs() < 56 || delta.dx.abs() < delta.dy.abs() * 1.25) {
      return;
    }
    if (delta.dx < 0) {
      widget.onSwipeLeft();
    } else {
      widget.onSwipeRight();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerStarts.remove(event.pointer);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, constraints) => Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: InteractiveViewer(
            transformationController: widget.zoomController,
            minScale: 1,
            maxScale: 3,
            panEnabled: widget.zoomScale > 1.01,
            scaleEnabled: true,
            // Keep horizontal zoom panning comfortable while clamping the
            // page vertically to the viewport once its full height is shown.
            boundaryMargin: const EdgeInsets.symmetric(horizontal: 28),
            onInteractionStart: _onInteractionStart,
            onInteractionEnd: (details) =>
                _onInteractionEnd(details, constraints.biggest),
            child: LayoutBuilder(
              builder: (context, pageConstraints) {
                const scrollable = false;
                final page = SizedBox(
                  width: pageConstraints.maxWidth,
                  height: scrollable ? null : pageConstraints.maxHeight,
                  child: _MushafPageContent(
                    pageNumber: widget.pageNumber,
                    palette: widget.palette,
                    fontSize: 23.0,
                    scrollable: scrollable,
                    highlightedSurahNumber: widget.highlightedSurahNumber,
                    highlightedAyahNumber: widget.highlightedAyahNumber,
                    bookmarkedAyahKeys: widget.bookmarkedAyahKeys,
                    onAyahLongPress: widget.onAyahLongPress,
                  ),
                );
                if (!scrollable) return page;
                return SingleChildScrollView(
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  child: page,
                );
              },
            ),
          ),
        ),
  );
}
