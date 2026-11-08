import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_switch.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/features/prayer_times/domain/entities/adhan_audio_option.dart';
class AdhanInfoCard extends StatelessWidget {
  const AdhanInfoCard({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 18, 16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        )),
                const SizedBox(height: 6),
                Text(text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          height: 1.5,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdhanAudioTile extends StatelessWidget {
  const AdhanAudioTile({
    required this.option,
    required this.selected,
    required this.previewing,
    required this.onSelect,
    required this.onPreview,
  });

  final AdhanAudioOption option;
  final bool selected;
  final bool previewing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: previewing ? 'إيقاف المعاينة' : 'استمع قبل الاختيار',
                onPressed: onPreview,
                icon: Icon(
                  previewing ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdhanVolumeSlider extends StatelessWidget {
  const AdhanVolumeSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  void _setFromPosition(double dx, double width) {
    const horizontalInset = 14.0;
    final trackWidth = width - horizontalInset * 2;
    if (trackWidth <= 0) return;
    onChanged(((dx - horizontalInset) / trackWidth).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          slider: true,
          value: '${(value * 100).round()}٪',
          increasedValue: '${((value + .05).clamp(0.0, 1.0) * 100).round()}٪',
          decreasedValue: '${((value - .05).clamp(0.0, 1.0) * 100).round()}٪',
          onIncrease: value < 1 ? () {
            onChanged((value + .05).clamp(0.0, 1.0));
            onChangeEnd();
          } : null,
          onDecrease: value > 0 ? () {
            onChanged((value - .05).clamp(0.0, 1.0));
            onChangeEnd();
          } : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              _setFromPosition(details.localPosition.dx, width);
              onChangeEnd();
            },
            onHorizontalDragStart: (details) =>
                _setFromPosition(details.localPosition.dx, width),
            onHorizontalDragUpdate: (details) =>
                _setFromPosition(details.localPosition.dx, width),
            onHorizontalDragEnd: (_) => onChangeEnd(),
            child: SizedBox(
              height: 52,
              width: width,
              child: CustomPaint(
                painter: _AdhanVolumeTrackPainter(
                  value: value,
                  activeColor: colors.primary,
                  inactiveColor: colors.surfaceContainerHighest,
                  thumbColor: colors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdhanVolumeTrackPainter extends CustomPainter {
  const _AdhanVolumeTrackPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalInset = 14.0;
    final centerY = size.height / 2;
    final trackWidth = size.width - horizontalInset * 2;
    final thumbX = horizontalInset + trackWidth * value;
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(horizontalInset, centerY),
      Offset(size.width - horizontalInset, centerY),
      inactivePaint,
    );
    if (value > 0) {
      canvas.drawLine(
        Offset(horizontalInset, centerY),
        Offset(thumbX, centerY),
        activePaint,
      );
    }
    canvas.drawCircle(
      Offset(thumbX, centerY),
      11,
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(covariant _AdhanVolumeTrackPainter oldDelegate) =>
      value != oldDelegate.value ||
      activeColor != oldDelegate.activeColor ||
      inactiveColor != oldDelegate.inactiveColor ||
      thumbColor != oldDelegate.thumbColor;
}

class PermissionStatusTile extends StatelessWidget {
  const PermissionStatusTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppSwitchListTile(
      value: value,
      onChanged: onChanged,
      leading: Icon(
        icon ??
            (value ? Icons.check_circle_rounded : Icons.info_outline_rounded),
        color: value ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(
        '$description ${value ? 'مفعّلة' : 'غير مفعّلة'}',
        textDirection: TextDirection.rtl,
      ),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

