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
        AppSnackBar.show(
          message: 'تعذر تحديث صلاحية الجهاز. تحقق من إعدادات النظام.',
        );
      }
    }
    await _refreshPermissions();
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
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
