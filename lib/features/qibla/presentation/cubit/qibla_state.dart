enum QiblaStatus {
  initial,
  loading,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  locationServicesDisabled,
  failure,
}

class QiblaState {
  const QiblaState({
    this.status = QiblaStatus.initial,
    this.qiblaBearing,
    this.heading,
    this.accuracy,
    this.compassAvailable,
    this.error,
  });

  final QiblaStatus status;
  final double? qiblaBearing;
  final double? heading;
  final double? accuracy;
  final bool? compassAvailable;
  final String? error;

  QiblaState copyWith({
    QiblaStatus? status,
    double? qiblaBearing,
    double? heading,
    double? accuracy,
    bool? compassAvailable,
    String? error,
  }) => QiblaState(
    status: status ?? this.status,
    qiblaBearing: qiblaBearing ?? this.qiblaBearing,
    heading: heading ?? this.heading,
    accuracy: accuracy,
    compassAvailable: compassAvailable ?? this.compassAvailable,
    error: error,
  );
}
