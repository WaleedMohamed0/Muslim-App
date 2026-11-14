import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_switch.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/prayer_times/domain/entities/adhan_audio_option.dart';
import 'package:muslim/features/prayer_times/presentation/widgets/adhan_settings_widgets.dart';

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
  bool _enablingAdhan = false;
  String? _previewingId;

  static const _prayerNames = {
    'fajr': 'الْفَجْر',
    'dhuhr': 'الظُّهْر',
    'asr': 'الْعَصْر',
    'maghrib': 'الْمَغْرِب',
    'isha': 'الْعِشَاء',
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
    if (_previewingId != null &&
        AdhanAudioOption.byId(_previewingId).assetPath == null) {
      unawaited(_service.stopAudio());
    }
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
          actionsAlignment: MainAxisAlignment.spaceBetween,
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
    if (!enabled) {
      await _save(_settings.copyWith(enabled: false));
      return;
    }
    if (_enablingAdhan) return;
    final previousSettings = _settings;
    var enabledSuccessfully = false;
    // Reflect the tap immediately; permission checks and system dialogs can
    // take noticeably longer than the switch animation.
    setState(() {
      _settings = _settings.copyWith(enabled: true);
      _enablingAdhan = true;
    });
    try {
      final currentPermissions = await _service.permissionStatus();
      if (mounted) setState(() => _permissions = currentPermissions);
      if (!currentPermissions.containsKey('notifications')) return;
      if (currentPermissions['notifications'] != true) {
        final accepted = await _explainPermission(
          'السماح بالإشعارات',
          'يلزم السماح بالإشعارات لتلقي تنبيهات الأذان عند دخول وقت الصَّلَاة.',
        );
        if (!accepted) return;
        await _service.requestNotificationPermission();
        final status = await _service.permissionStatus();
        if (mounted) setState(() => _permissions = status);
        if (status['notifications'] != true) {
          if (mounted) {
            AppSnackBar.show(
              message: 'إذن الإشعارات مطلوب لتفعيل الأذان. فعّله من إعدادات التطبيق ثم حاول مرة أخرى.',
            );
          }
          return;
        }
      }

      if (currentPermissions['exactAlarms'] != true) {
        final accepted = await _explainPermission(
          'السماح بالمنبهات الدقيقة',
          'هذا الإذن مطلوب لتشغيل صوت الأذان تلقائيًا في الخلفية عند دخول وقت الصَّلَاة. إذا لم تسمح به، سيصلك إشعار الصَّلَاة من دون تشغيل الصوت.',
        );
        if (!accepted) return;
        await _service.requestExactAlarmPermission();
        // Android opens a settings screen here; its result completes before
        // the user makes a choice. The lifecycle observer refreshes the
        // permission state on return. Keep Azan disabled until the user retries
        // and exact-alarm access is confirmed.
        return;
      }
      await _save(_settings.copyWith(enabled: true));
      enabledSuccessfully = true;
      await _refreshPermissions();
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          message: 'الوصول إلى الموقع مطلوب لحساب مواقيت صَلَاة دقيقة. يمكنك المحاولة مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (!enabledSuccessfully) _settings = previousSettings;
          _enablingAdhan = false;
        });
      }
    }
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

  Future<void> _saveVolume() async {
    await _save(_settings.copyWith(volume: _settings.volume));
    if (_previewingId != null &&
        AdhanAudioOption.byId(_previewingId).assetPath == null) {
      await _service.previewAudio(_previewingId!);
    }
  }

  Future<void> _previewAudio(AdhanAudioOption option) async {
    if (_previewingId == option.id) {
      await _stopTest();
      return;
    }
    try {
      if (option.assetPath == null) {
        await _previewPlayer.stop();
        await _service.previewAudio(option.id);
      } else {
        if (_previewingId != null &&
            AdhanAudioOption.byId(_previewingId).assetPath == null) {
          await _service.stopAudio();
        }
        await _previewPlayer.setAsset(option.assetPath!);
        await _previewPlayer.setVolume(_settings.volume);
        unawaited(
          _previewPlayer.play().catchError((Object _) {
            if (mounted) {
              setState(() => _previewingId = null);
              AppSnackBar.show(message: 'تعذر تشغيل معاينة الأذان');
            }
          }),
        );
      }
      if (mounted) setState(() => _previewingId = option.id);
    } catch (_) {
      if (mounted) AppSnackBar.show(message: 'تعذر تشغيل معاينة الأذان');
    }
  }

  Future<void> _stopTest() async {
    try {
      if (_previewingId != null &&
          AdhanAudioOption.byId(_previewingId).assetPath == null) {
        await _service.stopAudio();
      } else {
        await _previewPlayer.stop();
      }
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
                  text: 'اختر صوت الأذان المفضل لديك، وتحكم في تنبيهات الصَّلَوَات بسهولة.',
                ),
                const SizedBox(height: 14),
                Card(
                  child: AppSwitchListTile(
                    value: _settings.enabled,
                    onChanged: _enablingAdhan ? null : _setAdhanEnabled,
                    title: const Text('تفعيل الأذان تلقائيًا'),
                    subtitle: Text(
                      _settings.enabled && _permissions['exactAlarms'] != true
                          ? 'يلزم السماح بالمنبهات الدقيقة لتشغيل الصوت تلقائيًا'
                          : 'تشغيل الأذان عند حلول المواقيت المحددة',
                    ),
                    leading: Icon(Icons.notifications_active_outlined,
                        color: colors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الأذان لكل صَلَاة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final prayer in _prayerNames.entries)
                        AppSwitchListTile(
                          value: _settings.prayers[prayer.key] ?? true,
                          title: Text(prayer.value),
                          leading: Icon(_prayerIcon(prayer.key),
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 19,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إيقاف الأذان أثناء تشغيله',
                                  textDirection: TextDirection.rtl,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'يمكنك إيقافه بالضغط على زر رفع أو خفض الصوت في هاتفك.',
                                  textDirection: TextDirection.rtl,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 48,
                          top: 14,
                          bottom: 14,
                        ),
                        child: Divider(
                          height: 1,
                          color: colors.outlineVariant,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 19,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ملاحظات التشغيل',
                                  textDirection: TextDirection.rtl,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'عند اكتشاف أن الجهاز في وضع مكالمة، لا يُشغّل الأذان ويصل تنبيه الصَّلَاة بصمت. قد تؤثر قيود النظام أو الشركة المصنّعة في توقيت التنبيهات، كما يلتزم الصوت بإعدادات عدم الإزعاج في الجهاز.',
                                  textDirection: TextDirection.rtl,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
