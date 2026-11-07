import 'dart:math' as math;

import 'package:flutter/material.dart';

class QiblaCompassDial extends StatelessWidget {
  const QiblaCompassDial({
    super.key,
    required this.heading,
    required this.qiblaBearing,
  });

  final double heading;
  final double qiblaBearing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final markerAngle = (qiblaBearing - heading - 90) * math.pi / 180;
        final radius = size / 2 - 35;
        final center = size / 2;
        final markerCenterX = center + math.cos(markerAngle) * radius;
        final markerCenterY = center + math.sin(markerAngle) * radius;
        return SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CompassPainter(
                    heading: heading,
                    qiblaBearing: qiblaBearing,
                    scheme: colors,
                  ),
                ),
              ),
              Positioned(
                left: markerCenterX - 17,
                top: markerCenterY - 17,
                child: const _KaabaMarker(),
              ),
              Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ornament = isDark ? const Color(0xFFD8B46A) : colors.secondary;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF202923),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: ornament, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 9),
          height: 4,
          decoration: BoxDecoration(
            color: ornament,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    required this.heading,
    required this.qiblaBearing,
    required this.scheme,
  });

  final double heading;
  final double qiblaBearing;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = scheme.surfaceContainerHigh
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = scheme.outlineVariant.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      center,
      radius - 13,
      Paint()
        ..color = scheme.primary.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (var tick = 0; tick < 72; tick++) {
      final degrees = tick * 5.0 - heading;
      final angle = (degrees - 90) * math.pi / 180;
      final isMajor = tick % 6 == 0;
      final innerRadius = radius - (isMajor ? 27 : 21);
      final outerRadius = radius - 15;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * innerRadius,
          center.dy + math.sin(angle) * innerRadius,
        ),
        Offset(
          center.dx + math.cos(angle) * outerRadius,
          center.dy + math.sin(angle) * outerRadius,
        ),
        Paint()
          ..color = scheme.onSurfaceVariant.withValues(
            alpha: isMajor ? .8 : .35,
          )
          ..strokeWidth = isMajor ? 1.8 : 1,
      );
    }

    const directions = ['شمال', 'شرق', 'جنوب', 'غرب'];
    for (var index = 0; index < directions.length; index++) {
      final angle = (index * 90.0 - heading - 90) * math.pi / 180;
      final labelPosition = Offset(
        center.dx + math.cos(angle) * (radius - 49),
        center.dy + math.sin(angle) * (radius - 49),
      );
      final label = TextPainter(
        text: TextSpan(
          text: directions[index],
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout();
      label.paint(
        canvas,
        Offset(
          labelPosition.dx - label.width / 2,
          labelPosition.dy - label.height / 2,
        ),
      );
    }

    final qiblaAngle = (qiblaBearing - heading - 90) * math.pi / 180;
    final tip = Offset(
      center.dx + math.cos(qiblaAngle) * (radius - 36),
      center.dy + math.sin(qiblaAngle) * (radius - 36),
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = scheme.primary
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    final arrow =
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            tip.dx - math.cos(qiblaAngle - .42) * 13,
            tip.dy - math.sin(qiblaAngle - .42) * 13,
          )
          ..lineTo(
            tip.dx - math.cos(qiblaAngle + .42) * 13,
            tip.dy - math.sin(qiblaAngle + .42) * 13,
          )
          ..close();
    canvas.drawPath(arrow, Paint()..color = scheme.primary);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.qiblaBearing != qiblaBearing ||
      oldDelegate.scheme != scheme;
}
