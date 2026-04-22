import 'route_point.dart';

// Data model representing one completed dog walk.
class WalkRecord {
  String dogId;
  DateTime startTime;
  DateTime endTime;
  double distanceKm;
  double calories;
  bool goalReached;
  List<RoutePoint> routePoints;

  WalkRecord({
    required this.dogId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.calories,
    required this.goalReached,
    required this.routePoints,
  });

  // Convert a WalkRecord into a map so it can be stored locally.
  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'distanceKm': distanceKm,
      'calories': calories,
      'goalReached': goalReached,
      'routePoints': routePoints.map((point) => point.toMap()).toList(),
    };
  }

  // Rebuild a WalkRecord from saved local data.
  factory WalkRecord.fromMap(Map<dynamic, dynamic> map) {
    final rawPoints = map['routePoints'] as List? ?? [];

    return WalkRecord(
      dogId: map['dogId'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      distanceKm: map['distanceKm'] != null
          ? (map['distanceKm'] as num).toDouble()
          : 0.0,
      calories: map['calories'] != null
          ? (map['calories'] as num).toDouble()
          : 0.0,
      goalReached: map['goalReached'] ?? false,
      routePoints: rawPoints
          .map((item) => RoutePoint.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList(),
    );
  }
}