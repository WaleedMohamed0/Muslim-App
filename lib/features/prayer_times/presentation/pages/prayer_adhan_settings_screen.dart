import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:untitled8/core/widgets/app_widgets.dart';
import 'package:untitled8/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:untitled8/features/prayer_times/domain/entities/adhan_audio_option.dart';
import 'package:untitled8/features/prayer_times/presentation/widgets/adhan_settings_widgets.dart';

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
  late final StreamSubscription<PlayerState> _previewStateSubscription;
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
    _previewStateSubscription = _previewPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _previewingId != null && mounted) {
        setState(() => _previewingId = null);
      }
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_previewStateSubscription.cancel());
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

  Future<void> _changePermission(String key, bool enabled) async {
    try {
      if (!enabled) {
        if (key == 'notifications') {
          await _service.openNotificationSettings();
        } else {
          await _service.openAppSettings();
        }
      } else {
        switch (key) {
          case 'notifications':
            await _service.requestNotificationPermission();
          case 'location':
            var permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.deniedForever) {
              await Geolocator.openAppSettings();
            } else {
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.deniedForever) {
                await Geolocator.openAppSettings();
              }
            }
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(message: 'تعذر تحديث صلاحية الجهاز. تحقق من إعدادات النظام.');
      }
    }
    await _refreshPermissions();
  }

  Future<bool> _explainPermission(String title, String description) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title, textDirection: TextDirection.rtl),
          content: Text(
            description,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.start,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ليس الآن'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('متابعة'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _setAdhanEnabled(bool enabled) async {
    if (enabled && _permissions['exactAlarms'] != true) {
      final accepted = await _explainPermission(
        'السماح بالمنبهات الدقيقة',
        'يساعد هذا الإذن على تشغيل الأذان عند دخول وقت الصلاة. إذا لم تسمح به، قد يتأخر التنبيه بسبب قيود النظام.',
      );
      if (accepted) await _service.requestExactAlarmPermission();
    }
    await _save(_settings.copyWith(enabled: enabled));
    await _refreshPermissions();
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
                AdhanInfoCard(
                  icon: Icons.alarm_rounded,
                  title: 'كيف يعمل الأذان؟',
                  text: 'اختر صوت الأذان المفضل لديك، وتحكم في تنبيهات الصلوات بسهولة.',
                ),
                const SizedBox(height: 14),
                Card(
                  child: SwitchListTile.adaptive(
                    value: _settings.enabled,
                    onChanged: _setAdhanEnabled,
                    title: const Text('تفعيل الأذان تلقائيًا'),
                    subtitle: const Text('تشغيل الأذان عند حلول المواقيت المحددة'),
                    secondary: Icon(Icons.notifications_active_outlined,
                        color: colors.primary),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (Theme.of(context).brightness == Brightness.dark) {
                        return null;
                      }
                      return states.contains(WidgetState.selected)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.surface;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (Theme.of(context).brightness == Brightness.dark) {
                        return null;
                      }
                      return states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.onSurfaceVariant;
                    }),
                    trackOutlineColor:
                        WidgetStateProperty.resolveWith((states) {
                      if (Theme.of(context).brightness == Brightness.dark) {
                        return null;
                      }
                      return states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.onSurfaceVariant;
                    }),
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
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (Theme.of(context).brightness ==
                                Brightness.dark) {
                              return null;
                            }
                            return states.contains(WidgetState.selected)
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.surface;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (Theme.of(context).brightness ==
                                Brightness.dark) {
                              return null;
                            }
                            return states.contains(WidgetState.selected)
                                ? colors.primary
                                : colors.onSurfaceVariant;
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (Theme.of(context).brightness ==
                                Brightness.dark) {
                              return null;
                            }
                            return states.contains(WidgetState.selected)
                                ? colors.primary
                                : colors.onSurfaceVariant;
                          }),
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
                          AdhanAudioTile(
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
                        AdhanVolumeSlider(
                          value: _settings.volume,
                          onChanged: _changeVolume,
                          onChangeEnd: _saveVolume,
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
                      PermissionStatusTile(
                        title: 'الإشعارات',
                        description: 'لعرض تنبيهات الصلاة والأذان.',
                        value: _permissions['notifications'] ?? false,
                        onChanged: (value) => _changePermission('notifications', value),
                      ),
                      const Divider(height: 1),
                      PermissionStatusTile(
                        title: 'الموقع',
                        description: 'لحساب مواقيت الصلاة بحسب موقعك.',
                        value: _permissions['location'] ?? false,
                        onChanged: (value) => _changePermission('location', value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'عند اكتشاف أن الجهاز في وضع مكالمة، لا يُشغّل الأذان ويصل تنبيه الصلاة بصمت. قد تؤثر قيود النظام أو الشركة المصنّعة في توقيت التنبيهات، كما يلتزم الصوت بإعدادات عدم الإزعاج في الجهاز.',
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
