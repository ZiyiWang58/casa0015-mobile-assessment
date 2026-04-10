import 'package:hive_flutter/hive_flutter.dart';
import '../models/dog.dart';
import '../models/walk_record.dart';

class StorageService {
  static const String dogsBoxName = 'dogs_box';
  static const String walksBoxName = 'walks_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(dogsBoxName);
    await Hive.openBox(walksBoxName);
  }

  static Future<void> saveDogs(List<Dog> dogs) async {
    final box = Hive.box(dogsBoxName);
    final data = dogs.map((dog) => dog.toMap()).toList();
    await box.put('dogs', data);
  }

  static List<Dog> loadDogs() {
    final box = Hive.box(dogsBoxName);
    final rawList = box.get('dogs', defaultValue: []);

    if (rawList is List) {
      return rawList
          .map((item) => Dog.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  static Future<void> saveWalkRecords(List<WalkRecord> records) async {
    final box = Hive.box(walksBoxName);
    final data = records.map((record) => record.toMap()).toList();
    await box.put('records', data);
  }

  static List<WalkRecord> loadWalkRecords() {
    final box = Hive.box(walksBoxName);
    final rawList = box.get('records', defaultValue: []);

    if (rawList is List) {
      return rawList
          .map((item) => WalkRecord.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList();
    }

    return [];
  }
}