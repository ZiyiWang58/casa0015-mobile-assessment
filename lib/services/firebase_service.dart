import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog.dart';
import '../models/walk_record.dart';
import 'auth_service.dart';

/// Handles syncing app data to Firebase Cloud Firestore with per-user isolation.
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Return the current Firebase user id, or throw if no user is signed in.
  static String _requireUid() {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      throw Exception('No signed-in Firebase user found.');
    }
    return user.uid;
  }

  /// Reference to the current user's dog collection.
  static CollectionReference<Map<String, dynamic>> _dogsCollection() {
    final uid = _requireUid();
    return _firestore.collection('users').doc(uid).collection('dogs');
  }

  /// Reference to the current user's walk history collection.
  static CollectionReference<Map<String, dynamic>> _walksCollection() {
    final uid = _requireUid();
    return _firestore.collection('users').doc(uid).collection('walk_records');
  }

  /// Upload the full dog list to the current user's Firestore collection.
  static Future<void> syncDogs(List<Dog> dogs) async {
    final collection = _dogsCollection();

    // Clear old cloud data before re-uploading the latest list.
    final existingDocs = await collection.get();
    for (final doc in existingDocs.docs) {
      await doc.reference.delete();
    }

    for (final dog in dogs) {
      await collection.doc(dog.id).set(dog.toMap());
    }
  }

  /// Upload the full walk history list to the current user's Firestore collection.
  static Future<void> syncWalkRecords(List<WalkRecord> records) async {
    final collection = _walksCollection();

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

  /// Load all dog profiles for the current signed-in user.
  static Future<List<Dog>> loadDogs() async {
    final collection = _dogsCollection();
    final snapshot = await collection.get();

    return snapshot.docs
        .map((doc) => Dog.fromMap(doc.data()))
        .toList();
  }

  /// Load all walk records for the current signed-in user.
  static Future<List<WalkRecord>> loadWalkRecords() async {
    final collection = _walksCollection();
    final snapshot = await collection.get();

    return snapshot.docs
        .map((doc) => WalkRecord.fromMap(doc.data()))
        .toList();
  }
}