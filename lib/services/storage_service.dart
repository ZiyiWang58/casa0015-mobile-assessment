import 'package:hive_flutter/hive_flutter.dart';
import '../models/dog.dart';
import '../models/walk_record.dart';

// Handles reading and writing dogs and walk records using Hive local storage.
class StorageService {
  static const String dogsBoxName = 'dogs_box';
  static const String walksBoxName = 'walks_box';

  // Initialize Hive and open the local storage boxes used by the app.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(dogsBoxName);
    await Hive.openBox(walksBoxName);
  }

  // Save the full dog list to local storage.
  static Future<void> saveDogs(List<Dog> dogs) async {
    final box = Hive.box(dogsBoxName);
    final data = dogs.map((dog) => dog.toMap()).toList();
    await box.put('dogs', data);
  }

  // Load all saved dogs from local storage.
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

  // Save the full walk history list to local storage.
  static Future<void> saveWalkRecords(List<WalkRecord> records) async {
    final box = Hive.box(walksBoxName);
    final data = records.map((record) => record.toMap()).toList();
    await box.put('records', data);
  }

  // Load all saved walk records from local storage.
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