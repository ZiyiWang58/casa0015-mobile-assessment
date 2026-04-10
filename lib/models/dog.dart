class Dog {
  String id;
  String name;
  String breed;
  int? age;
  double? weightKg;
  double targetDistanceKm;
  String? imagePath;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    this.age,
    this.weightKg,
    required this.targetDistanceKm,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
      'weightKg': weightKg,
      'targetDistanceKm': targetDistanceKm,
      'imagePath': imagePath,
    };
  }

  factory Dog.fromMap(Map<dynamic, dynamic> map) {
    return Dog(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'],
      weightKg: map['weightKg'] != null
          ? (map['weightKg'] as num).toDouble()
          : null,
      targetDistanceKm: map['targetDistanceKm'] != null
          ? (map['targetDistanceKm'] as num).toDouble()
          : 0.0,
      imagePath: map['imagePath'],
    );
  }
}