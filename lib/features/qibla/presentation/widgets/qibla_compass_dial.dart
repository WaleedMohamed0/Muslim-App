import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

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
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 330.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : availableWidth;
        final size = math.min(math.min(availableWidth, availableHeight), 330.0);
        final markerAngle = (qiblaBearing - heading - 90) * math.pi / 180;
        const markerSize = 48.0;
        final radius = math.max(0.0, size / 2 - markerSize / 2 - 18);
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
                left: markerCenterX - markerSize / 2,
                top: markerCenterY - markerSize / 2,
                child: const QiblaKaabaIcon(),
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

class QiblaKaabaIcon extends StatelessWidget {
  const QiblaKaabaIcon({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/features/qibla/images/kaaba_isometric.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
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
    // Stop the arrow before the Kaaba marker so its arrowhead stays visible.
    const markerSize = 48.0;
    final kaabaRadius = math.max(
      0.0,
      math.min(size.width, size.height) / 2 - markerSize / 2 - 18,
    );
    final arrowTipRadius = math.max(0.0, kaabaRadius - markerSize / 2.5);
    final tip = Offset(
      center.dx + math.cos(qiblaAngle) * arrowTipRadius,
      center.dy + math.sin(qiblaAngle) * arrowTipRadius,
    );
    final directionColor =
        scheme.brightness == Brightness.dark
            ? const Color(0xFF55D68B)
            : const Color(0xFF167A45);
    final arrowOutline = Paint()
      ..color = scheme.surface
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, arrowOutline);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = directionColor
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
    canvas.drawPath(
      arrow,
      Paint()
        ..color = directionColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.qiblaBearing != qiblaBearing ||
      oldDelegate.scheme != scheme;
}
