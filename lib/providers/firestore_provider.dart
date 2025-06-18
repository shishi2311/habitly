import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get habits collection reference for current user
  CollectionReference _habitsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  // Get all habits for current user
  Stream<QuerySnapshot> getHabits() {
    final user = _auth.currentUser;
    if (user != null) {
      return _habitsCollection(user.uid).snapshots();
    }
    throw Exception('User not authenticated');
  }

  // Add a new habit
  Future<void> addHabit(Map<String, dynamic> habit) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _habitsCollection(user.uid).add({
        ...habit,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Update a habit
  Future<void> updateHabit(String habitId, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _habitsCollection(user.uid).doc(habitId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String habitId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _habitsCollection(user.uid).doc(habitId).delete();
    }
  }

  // Update streak
  Future<void> updateStreak(
    String habitId,
    int streak,
    DateTime lastCompleted,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _habitsCollection(user.uid).doc(habitId).update({
        'streak': streak,
        'lastCompleted': lastCompleted.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Migrate local habits to Firestore
  Future<void> migrateLocalHabits(
    List<Map<String, dynamic>> localHabits,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      final batch = _firestore.batch();
      final collection = _habitsCollection(user.uid);

      for (final habit in localHabits) {
        final docRef = collection.doc();
        batch.set(docRef, {
          ...habit,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }
}
