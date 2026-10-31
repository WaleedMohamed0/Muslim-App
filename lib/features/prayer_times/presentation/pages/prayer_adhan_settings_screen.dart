import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:untitled8/core/theme/app_theme.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:untitled8/features/prayer_times/domain/entities/adhan_audio_option.dart';

class PrayerAdhanSettingsScreen extends StatefulWidget {
  const PrayerAdhanSettingsScreen({super.key});

  @override
  State<PrayerAdhanSettingsScreen> createState() =>
      _PrayerAdhanSettingsScreenState();
}

class _PrayerAdhanSettingsScreenState extends State<PrayerAdhanSettingsScreen>
    with WidgetsBindingObserver {
  final _service = PrayerAdhanService.instance;
  final _previewPlayer = AudioPlayer();
  PrayerAdhanSettings _settings = const PrayerAdhanSettings();
  Map<String, bool> _permissions = const {};
  bool _loading = true;
  String? _previewingId;

  static const _prayerNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_previewPlayer.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshPermissions());
  }

  Future<void> _load() async {
    try {
      final settings = await _service.loadSettings();
      final permissions = await _service.permissionStatus();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _permissions = permissions;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      final status = await _service.permissionStatus();
      if (mounted) setState(() => _permissions = status);
    } catch (_) {}
  }

  Future<void> _save(PrayerAdhanSettings settings) async {
    setState(() => _settings = settings);
    try {
      await _service.saveSettings(settings);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(message: 'تعذر حفظ إعدادات الأذان على هذا الجهاز');
      }
    }
  }

  void _changeVolume(double value) {
    final volume = value.clamp(0.0, 1.0);
    setState(() => _settings = _settings.copyWith(volume: volume));
    if (_previewingId != null) unawaited(_previewPlayer.setVolume(volume));
  }

  void _saveVolume() => unawaited(
    _save(_settings.copyWith(volume: _settings.volume)),
  );

  Future<void> _previewAudio(AdhanAudioOption option) async {
    if (_previewingId == option.id) {
      await _stopTest();
      return;
    }
    try {
      await _previewPlayer.setAsset(option.assetPath);
      await _previewPlayer.setVolume(_settings.volume);
      unawaited(
        _previewPlayer.play().catchError((Object _) {
          if (mounted) {
            setState(() => _previewingId = null);
            AppSnackBar.show(message: 'تعذر تشغيل معاينة الأذان');
          }
        }),
      );
      if (mounted) setState(() => _previewingId = option.id);
    } catch (_) {
      if (mounted) AppSnackBar.show(message: 'تعذر تشغيل معاينة الأذان');
    }
  }

  Future<void> _stopTest() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (mounted) setState(() => _previewingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: defaultAppBar(context: context, text: 'إعدادات الأذان'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
              children: [
                _InfoCard(
                  icon: Icons.alarm_rounded,
                  title: 'الأذان يعمل من الجهاز',
                  text:
                      'بعد تحميل مواقيت الشهر ومنح صلاحية المنبهات، تُشغّل التنبيهات المحلية الملف المحفوظ حتى دون اتصال بالإنترنت.',
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile.adaptive(
                    value: _settings.enabled,
                    onChanged: (value) => _save(_settings.copyWith(enabled: value)),
                    title: const Text('تفعيل الأذان تلقائيًا'),
                    subtitle: const Text('تشغيل الأذان عند حلول المواقيت المحددة'),
                    secondary: Icon(Icons.notifications_active_outlined,
                        color: colors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الأذان لكل صلاة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final prayer in _prayerNames.entries)
                        SwitchListTile.adaptive(
                          value: _settings.prayers[prayer.key] ?? true,
                          title: Text(prayer.value),
                          secondary: Icon(_prayerIcon(prayer.key),
                              color: colors.primary),
                          onChanged: (value) {
                            final prayers = Map<String, bool>.from(_settings.prayers)
                              ..[prayer.key] = value;
                            _save(_settings.copyWith(prayers: prayers));
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الصوت',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note_rounded, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'اختر من تسجيلات مرفقة تعمل دون اتصال',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final option in AdhanAudioOption.options)
                          _AdhanAudioTile(
                            option: option,
                            selected: _settings.audioId == option.id,
                            previewing: _previewingId == option.id,
                            onSelect: () => _save(
                              _settings.copyWith(audioId: option.id),
                            ),
                            onPreview: () => _previewAudio(option),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('مستوى الصوت'),
                            const Spacer(),
                            Text('${(_settings.volume * 100).round()}٪'),
                          ],
                        ),
                        _AdhanVolumeSlider(
                          value: _settings.volume,
                          onChanged: _changeVolume,
                          onChangeEnd: _saveVolume,
                        ),
                        if (_previewingId != null)
                          TextButton.icon(
                            onPressed: _stopTest,
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('إيقاف المعاينة'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'صلاحيات الجهاز',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _PermissionTile(
                        title: 'المنبهات الدقيقة',
                        granted: _permissions['exactAlarms'] ?? false,
                        actionLabel: 'فتح الإعدادات',
                        onPressed: () async {
                          await _service.requestExactAlarmPermission();
                          await _refreshPermissions();
                        },
                      ),
                      const Divider(height: 1),
                      _PermissionTile(
                        title: 'الإشعارات',
                        granted: _permissions['notifications'] ?? false,
                        actionLabel: 'السماح',
                        onPressed: () async {
                          await _service.requestNotificationPermission();
                          await _refreshPermissions();
                        },
                      ),
                      const Divider(height: 1),
                      _PermissionTile(
                        title: 'تحسين البطارية',
                        granted: !(_permissions['batteryOptimized'] ?? true),
                        actionLabel: 'عرض الإعدادات',
                        onPressed: _service.openBatterySettings,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'قد يؤخر وضع توفير البطارية أو قيود الشركة المصنّعة بعض التنبيهات. يلتزم الصوت بمستوى صوت المنبه وإعدادات عدم الإزعاج في الجهاز، وقد يمنعهما الوضع الصامت أو عدم الإزعاج.',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                ),
              ],
            ),
    );
  }

  IconData _prayerIcon(String id) => switch (id) {
        'fajr' => Icons.wb_twilight_rounded,
        'dhuhr' => Icons.wb_sunny_rounded,
        'asr' => Icons.access_time_filled_rounded,
        'maghrib' => Icons.wb_twilight_outlined,
        _ => Icons.nights_stay_rounded,
      };
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 5),
                Text(text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.55,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdhanAudioTile extends StatelessWidget {
  const _AdhanAudioTile({
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

class _AdhanVolumeSlider extends StatelessWidget {
  const _AdhanVolumeSlider({
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

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.granted,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final bool granted;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        color: granted ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(granted ? 'مفعّلة' : 'غير مفعّلة'),
      trailing: TextButton(onPressed: onPressed, child: Text(actionLabel)),
    );
  }
}
