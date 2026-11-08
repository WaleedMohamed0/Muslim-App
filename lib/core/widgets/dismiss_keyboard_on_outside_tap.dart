import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Unfocuses the active input when a pointer starts outside of it.
///
/// A [Listener] observes pointer events without joining the gesture arena, so
/// scrolling, buttons, and text selection keep their normal behavior.
class DismissKeyboardOnOutsideTap extends StatelessWidget {
  const DismissKeyboardOnOutsideTap({required this.child, super.key});

  final Widget child;

  void _handlePointerDown(PointerDownEvent event) {
    final focusNode = FocusManager.instance.primaryFocus;
    final focusContext = focusNode?.context;
    if (focusNode == null || focusContext == null || !focusNode.hasFocus) {
      return;
    }

    final renderObject = focusContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final localPosition = renderObject.globalToLocal(event.position);
    if (!renderObject.size.contains(localPosition)) focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _handlePointerDown,
    child: child,
  );
}
