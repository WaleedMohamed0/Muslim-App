import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/app/data/data_sources/startup_permissions_data_source.dart';

typedef PermissionExplainer = Future<bool> Function(
  String title,
  String description,
);

class StartupCubit extends Cubit<void> {
  StartupCubit({required StartupPermissionsDataSource permissions})
    : _permissions = permissions,
      super(null);

  final StartupPermissionsDataSource _permissions;

  Future<void> requestFirstLaunchPermissions({
    required PermissionExplainer explainPermission,
    required bool Function() isMounted,
  }) async {
    try {
      if (!await _permissions.notificationDecisionMade()) {
        if (!await _permissions.notificationsGranted()) {
          final accepted = await explainPermission(
            'السماح بالإشعارات',
            'نستخدم الإشعارات لعرض تنبيهات الصلاة والأذان في أوقاتها.',
          );
          await _permissions.markNotificationDecisionMade();
          if (accepted) await _permissions.requestNotifications();
        } else {
          await _permissions.markNotificationDecisionMade();
        }
      }

      if (!isMounted() || await _permissions.locationDecisionMade()) return;
      if (await _permissions.locationPermissionAlreadyGranted()) {
        await _permissions.markLocationDecisionMade();
        return;
      }
      final accepted = await explainPermission(
        'السماح بالوصول إلى الموقع',
        'نحتاج إلى موقعك لحساب مواقيت الصلاة المناسبة لمكانك. يمكنك المتابعة وتفعيل الإذن لاحقًا من صلاحيات الجهاز.',
      );
      await _permissions.markLocationDecisionMade();
      if (accepted && isMounted()) await _permissions.requestLocation();
    } catch (_) {
      // Permission setup is optional; the user can grant access in settings.
    }
  }
}
