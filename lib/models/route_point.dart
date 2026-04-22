// Data model representing one GPS point in a walking route.
class RoutePoint {
  double latitude;
  double longitude;
  DateTime timestamp;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Convert a route point into a map for local storage.
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Rebuild a route point from locally stored map data.
  factory RoutePoint.fromMap(Map<dynamic, dynamic> map) {
    return RoutePoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}