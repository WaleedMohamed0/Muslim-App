import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/data_sources/qibla_device_data_source.dart';
import '../../domain/qibla_bearing_calculator.dart';
import 'qibla_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({QiblaDeviceDataSource? dataSource})
    : _dataSource = dataSource ?? QiblaDeviceDataSource(),
      super(const QiblaState());

  final QiblaDeviceDataSource _dataSource;
  StreamSubscription<dynamic>? _compassSubscription;
  Timer? _sensorTimeout;
  bool _loading = false;

  Future<void> initialize() async {
    if (_loading || isClosed) return;
    _loading = true;
    _compassSubscription?.cancel();
    _sensorTimeout?.cancel();
    emit(const QiblaState(status: QiblaStatus.loading));
    try {
      final permission = await _dataSource.checkLocationPermission();
      if (permission == LocationPermission.deniedForever) {
        emit(const QiblaState(status: QiblaStatus.permissionPermanentlyDenied));
        return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        emit(const QiblaState(status: QiblaStatus.permissionDenied));
        return;
      }
      if (!await _dataSource.isLocationServiceEnabled()) {
        emit(const QiblaState(status: QiblaStatus.locationServicesDisabled));
        return;
      }

      final position = await _dataSource.getCurrentPosition();
      final qiblaBearing = QiblaBearingCalculator.bearingFrom(
        position.latitude,
        position.longitude,
      );
      final declination =
          defaultTargetPlatform == TargetPlatform.android
              ? await _dataSource.magneticDeclination(position)
              : 0.0;
      emit(QiblaState(status: QiblaStatus.ready, qiblaBearing: qiblaBearing));
      _listenToCompass(declination ?? 0);
    } catch (_) {
      emit(
        const QiblaState(
          status: QiblaStatus.failure,
          error: 'تعذر تحديد موقعك. تحقق من الإشارة وحاول مرة أخرى.',
        ),
      );
    } finally {
      _loading = false;
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      final permission = await _dataSource.requestLocationPermission();
      if (permission == LocationPermission.deniedForever) {
        emit(const QiblaState(status: QiblaStatus.permissionPermanentlyDenied));
      } else if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        emit(const QiblaState(status: QiblaStatus.permissionDenied));
      } else {
        await initialize();
      }
    } catch (_) {
      emit(
        const QiblaState(
          status: QiblaStatus.failure,
          error: 'تعذر طلب إذن الموقع. حاول مرة أخرى.',
        ),
      );
    }
  }

  void _listenToCompass(double declination) {
    final events = _dataSource.compassEvents;
    if (events == null) {
      emit(state.copyWith(compassAvailable: false));
      return;
    }
    _sensorTimeout = Timer(const Duration(seconds: 4), () {
      if (state.status == QiblaStatus.ready && state.heading == null) {
        emit(state.copyWith(compassAvailable: false));
      }
    });
    _compassSubscription = events.listen(
      (event) {
        final magneticHeading = event.heading;
        if (magneticHeading == null || !magneticHeading.isFinite) {
          emit(state.copyWith(compassAvailable: false));
          return;
        }
        _sensorTimeout?.cancel();
        final trueHeading = (magneticHeading + declination + 360) % 360;
        final previousHeading = state.heading;
        final smoothedHeading =
            previousHeading == null
                ? trueHeading
                : (previousHeading +
                        _shortestDelta(previousHeading, trueHeading) * .24 +
                        360) %
                    360;
        emit(
          state.copyWith(
            heading: smoothedHeading,
            accuracy: event.accuracy,
            compassAvailable: true,
          ),
        );
      },
      onError: (_) {
        _sensorTimeout?.cancel();
        emit(state.copyWith(compassAvailable: false));
      },
    );
  }

  double _shortestDelta(double from, double to) =>
      ((to - from + 540) % 360) - 180;

  static double rotationToQibla(double bearing, double heading) =>
      ((bearing - heading + 540) % 360) - 180;

  @override
  Future<void> close() {
    _sensorTimeout?.cancel();
    _compassSubscription?.cancel();
    return super.close();
  }
}
