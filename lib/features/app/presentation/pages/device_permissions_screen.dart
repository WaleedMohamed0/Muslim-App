import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muslim/core/widgets/app_snackbar.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/prayer_times/presentation/widgets/adhan_settings_widgets.dart';

class DevicePermissionsScreen extends StatefulWidget {
  const DevicePermissionsScreen({super.key});

  @override
  State<DevicePermissionsScreen> createState() =>
      _DevicePermissionsScreenState();
}

class _DevicePermissionsScreenState extends State<DevicePermissionsScreen>
    with WidgetsBindingObserver {
  final PrayerAdhanService _service = PrayerAdhanService.instance;
  Map<String, bool> _permissions = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissions());
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      final permissions = await _service.permissionStatus();
      if (!mounted) return;
      setState(() {
        _permissions = permissions;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePermission(String key, bool enabled) async {
    try {
      if (!enabled) {
        if (!(_permissions[key] ?? false)) return;
        final shouldContinue = await _confirmPermissionDisable(key);
        if (!shouldContinue || !mounted) return;

        if (key == 'notifications') {
          await _service.openNotificationSettings();
        } else if (key == 'exactAlarms') {
          // Android does not let apps revoke exact-alarm access themselves.
          // Send the user to App info, where they can turn it off.
          await _service.openAppSettings();
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
          case 'exactAlarms':
            await _service.requestExactAlarmPermission();
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          message: 'تعذر تحديث صلاحية الجهاز. تحقق من إعدادات النظام.',
        );
      }
    }
    await _refreshPermissions();
  }

  Future<bool> _confirmPermissionDisable(String key) async {
    final (title, message) = switch (key) {
      'notifications' => (
          'إيقاف الإشعارات؟',
          'لن يتمكن التطبيق من عرض تنبيهات الصلاة والأذان والتذكيرات. يمكنك إيقافها من إعدادات الإشعارات في الجهاز.',
        ),
      'location' => (
          'إيقاف إذن الموقع؟',
          'لن يستطيع التطبيق تحديد موقعك تلقائيًا لحساب مواقيت الصلاة. ستحتاج إلى اختيار المدينة يدويًا أو تفعيل الإذن مجددًا.',
        ),
      'exactAlarms' => (
          'إيقاف المنبهات والتذكيرات؟',
          'لن يتمكن التطبيق من جدولة تنبيهات الصلاة والأذان والتذكيرات في مواعيدها الدقيقة.',
        ),
      _ => ('إيقاف الصلاحية؟', 'قد تتوقف بعض ميزات التطبيق عن العمل.'),
    };

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title, textDirection: TextDirection.rtl),
            content: Text(message, textDirection: TextDirection.rtl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('متابعة إلى الإعدادات'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: defaultAppBar(context: context, text: 'صلاحيات الجهاز'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
                children: [
                  Card(
                    child: Column(
                      children: [
                        PermissionStatusTile(
                          title: 'الإشعارات',
                          description: 'لعرض تنبيهات الصلاة والأذان.',
                          value: _permissions['notifications'] ?? false,
                          onChanged: (value) =>
                              _changePermission('notifications', value),
                        ),
                        const Divider(height: 1),
                        PermissionStatusTile(
                          title: 'الموقع',
                          description: 'لحساب مواقيت الصلاة بحسب موقعك.',
                          value: _permissions['location'] ?? false,
                          onChanged: (value) =>
                              _changePermission('location', value),
                        ),
                        const Divider(height: 1),
                        PermissionStatusTile(
                          title: 'المنبهات والتذكيرات',
                          description:
                              'لجدولة إشعارات الصلاة والأذان والتذكيرات بدقة.',
                          value: _permissions['exactAlarms'] ?? false,
                          icon: Icons.alarm_rounded,
                          onChanged: (value) =>
                              _changePermission('exactAlarms', value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
