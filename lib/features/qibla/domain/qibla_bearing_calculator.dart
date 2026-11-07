import 'dart:math' as math;

/// Calculates the initial great-circle bearing from a location to the Kaaba.
class QiblaBearingCalculator {
  static const kaabaLatitude = 21.422487;
  static const kaabaLongitude = 39.826206;

  static double bearingFrom(double latitude, double longitude) {
    final latitudeRadians = _radians(latitude);
    final kaabaLatitudeRadians = _radians(kaabaLatitude);
    final longitudeDifference = _radians(kaabaLongitude - longitude);

    final y = math.sin(longitudeDifference) * math.cos(kaabaLatitudeRadians);
    final x =
        math.cos(latitudeRadians) * math.sin(kaabaLatitudeRadians) -
        math.sin(latitudeRadians) *
            math.cos(kaabaLatitudeRadians) *
            math.cos(longitudeDifference);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
