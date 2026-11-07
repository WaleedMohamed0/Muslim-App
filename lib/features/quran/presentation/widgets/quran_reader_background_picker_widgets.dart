import 'package:flutter/material.dart';

import 'quran_reader_background_colors.dart';

class ReaderColorPreview extends StatelessWidget {
  const ReaderColorPreview({
    super.key,
    required this.color,
    required this.textColor,
    required this.accent,
    required this.darkMode,
  });

  final Color color;
  final Color textColor;
  final Color accent;
  final bool darkMode;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: textColor.withValues(alpha: .15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          darkMode ? 'معاينة الوضع الداكن' : 'معاينة الوضع الفاتح',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: textColor.withValues(alpha: .72), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            color: textColor,
            fontSize: 23,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '۞ ١ ۞',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(color: accent, fontSize: 18, height: 1.4),
        ),
      ],
    ),
  );
}

class PresetColorTile extends StatelessWidget {
  const PresetColorTile({
    super.key,
    required this.preset,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final QuranReaderBackgroundPreset preset;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: preset.name,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: preset.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: QuranReaderBackgroundColors.accentFor(
                        preset.color.computeLuminance() < .25,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 7),
            Text(
              preset.name,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class CustomReaderColorPicker extends StatefulWidget {
  const CustomReaderColorPicker({
    super.key,
    required this.initialColor,
    required this.darkMode,
  });

  final Color initialColor;
  final bool darkMode;

  @override
  State<CustomReaderColorPicker> createState() =>
      _CustomReaderColorPickerState();
}

class _CustomReaderColorPickerState extends State<CustomReaderColorPicker> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  double get _minimumLightness => widget.darkMode ? .08 : .82;
  double get _maximumLightness => widget.darkMode ? .24 : .96;
  Color get _color => HSLColor.fromAHSL(
    1,
    _hue,
    _saturation,
    _lightness,
  ).toColor();

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation.clamp(.1, .8).toDouble();
    _lightness = hsl.lightness
        .clamp(_minimumLightness, _maximumLightness)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = QuranReaderBackgroundColors.textFor(widget.darkMode);
    final accent = QuranReaderBackgroundColors.accentFor(widget.darkMode);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          20,
          14,
          20,
          MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لون مخصص',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ReaderColorPreview(
              color: _color,
              textColor: text,
              accent: accent,
              darkMode: widget.darkMode,
            ),
            const SizedBox(height: 16),
            _ColorSlider(
              label: 'درجة اللون',
              value: _hue,
              max: 360,
              onChanged: (value) => setState(() => _hue = value),
            ),
            _ColorSlider(
              label: 'التشبع',
              value: _saturation,
              min: .1,
              max: .8,
              divisions: 70,
              onChanged: (value) => setState(() => _saturation = value),
            ),
            _ColorSlider(
              label: 'درجة الإضاءة',
              value: _lightness,
              min: _minimumLightness,
              max: _maximumLightness,
              divisions: 60,
              onChanged: (value) => setState(() => _lightness = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_color),
                child: const Text('تطبيق اللون'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 78,
        child: Text(label, textDirection: TextDirection.rtl),
      ),
      Expanded(
        child: Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}
