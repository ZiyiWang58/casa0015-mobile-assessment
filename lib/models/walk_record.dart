class WalkRecord {
  String dogId;
  DateTime startTime;
  DateTime endTime;
  double distanceKm;
  double calories;
  bool goalReached;

  WalkRecord({
    required this.dogId,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.calories,
    required this.goalReached,
  });

  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'distanceKm': distanceKm,
      'calories': calories,
      'goalReached': goalReached,
    };
  }

  factory WalkRecord.fromMap(Map<dynamic, dynamic> map) {
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
    );
  }
}