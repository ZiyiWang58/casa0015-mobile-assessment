import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog.dart';
import '../models/walk_record.dart';

/// Handles syncing app data to Firebase Cloud Firestore.
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload the full dog list to Firestore.
  static Future<void> syncDogs(List<Dog> dogs) async {
    final collection = _firestore.collection('dogs');

    // Clear old cloud data before re-uploading the latest list.
    final existingDocs = await collection.get();
    for (final doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    for (final dog in dogs) {
      await collection.doc(dog.id).set(dog.toMap());
    }
  }

  /// Upload the full walk history list to Firestore.
  static Future<void> syncWalkRecords(List<WalkRecord> records) async {
    final collection = _firestore.collection('walk_records');

    // Clear old cloud data before re-uploading the latest history.
    final existingDocs = await collection.get();
    for (final doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    for (final record in records) {
      final docId =
          '${record.dogId}_${record.startTime.millisecondsSinceEpoch}';
      await collection.doc(docId).set(record.toMap());
    }
  }
}