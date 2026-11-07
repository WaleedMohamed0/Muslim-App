import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lottie/lottie.dart';

import '../../data/worship_ui_strings.dart';

/// On-demand player for a single worship lesson illustration.
class StepAnimation extends StatefulWidget {
  const StepAnimation({
    super.key,
    required this.assetPath,
    required this.autoplay,
    this.scrollController,
    this.loop = false,
    this.height = 230,
  });

  final String assetPath;
  final bool autoplay;
  final bool loop;
  final ScrollController? scrollController;
  final double height;

  @override
  State<StepAnimation> createState() => _StepAnimationState();
}

class _StepAnimationState extends State<StepAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  final GlobalKey _paintKey = GlobalKey();
  bool _failed = false;
  bool _visible = false;
  bool _resumeAfterScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this);
    widget.scrollController?.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didUpdateWidget(covariant StepAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _failed = false;
      _controller.stop();
      _controller.reset();
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
    if (widget.autoplay && (!oldWidget.autoplay || oldWidget.assetPath != widget.assetPath)) {
      _play();
    } else if (!widget.autoplay) {
      _controller.stop();
    }
  }

  void _onScroll() => WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());

  void _play() {
    if (!mounted || _failed) return;
    if (!_visible) return;
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _updateVisibility() {
    if (!mounted) return;
    final render = _paintKey.currentContext?.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final top = render.localToGlobal(Offset.zero).dy;
    final bottom = top + render.size.height;
    final viewport = context.findAncestorRenderObjectOfType<RenderViewport>();
    final viewportTop = viewport?.localToGlobal(Offset.zero).dy ?? 0;
    final viewportBottom = viewportTop + (viewport?.size.height ?? MediaQuery.sizeOf(context).height);
    final nowVisible = bottom > viewportTop && top < viewportBottom;
    if (nowVisible == _visible) return;
    _visible = nowVisible;
    if (!_visible) {
      _resumeAfterScroll = _controller.isAnimating;
      _controller.stop(canceled: false);
    } else if (_controller.value == 0) {
      _play();
    } else if (_resumeAfterScroll) {
      _resumeAfterScroll = false;
      if (widget.loop) {
        _controller.repeat(period: _controller.duration);
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.stop(canceled: false);
    } else if (_visible && widget.autoplay) {
      _play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController?.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: _paintKey,
      height: widget.height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _failed
            ? _AnimationFallback(color: colors.primary)
            : Lottie.asset(
                widget.assetPath,
                controller: _controller,
                fit: BoxFit.contain,
                repeat: false,
                animate: false,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  if (widget.autoplay) _play();
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _failed = true);
                  });
                  return const Center(child: CircularProgressIndicator());
                },
                frameBuilder: (context, child, composition) => composition == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(children: [
                        Expanded(child: child),
                        if (!widget.loop)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8, bottom: 4),
                              child: TextButton.icon(
                                onPressed: _play,
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text(WorshipUiStrings.replayAnimation),
                              ),
                            ),
                          ),
                      ]),
              ),
      ),
    );
  }
}

/// Small neutral human figure used only when an asset cannot be decoded.
class _AnimationFallback extends StatelessWidget {
  const _AnimationFallback({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 130,
          height: 170,
          child: Stack(alignment: Alignment.topCenter, children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color.withValues(alpha: .22), shape: BoxShape.circle),
            ),
            Container(
              margin: const EdgeInsets.only(top: 62),
              width: 72,
              height: 100,
              decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(28)),
              child: Icon(Icons.accessibility_new_rounded, size: 58, color: color),
            ),
          ]),
        ),
      );
}
