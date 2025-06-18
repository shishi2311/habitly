import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class HabitProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _habits = [];
  StreamSubscription<QuerySnapshot>? _habitsSubscription;
  bool _isInitialized = false;

  // Getter for habits
  List<Map<String, dynamic>> get habits => [..._habits];

  // Initialize and listen to Firestore
  Future<void> init() async {
    if (_isInitialized) return;

    final user = _auth.currentUser;

    if (user != null) {
      // Subscribe to habits collection changes
      _habitsSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('habits')
          .snapshots()
          .listen((snapshot) {
            print(
              'Received Firestore snapshot with ${snapshot.docs.length} habits',
            ); // Debug log
            _habits = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'],
                'durationMinutes': data['durationMinutes'],
                'streak': data['streak'] ?? 0,
                'lastCompleted': data['lastCompleted'] != null
                    ? DateTime.parse(data['lastCompleted'])
                    : null,
              };
            }).toList();
            notifyListeners();
          });
    }

    _isInitialized = true;
  }

  // Get reference to user's habits collection
  CollectionReference _userHabits() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(user.uid).collection('habits');
  }

  // Add a new habit
  Future<void> addHabit(String name, int durationMinutes) async {
    try {
      final habit = {
        'name': name,
        'durationMinutes': durationMinutes,
        'streak': 0,
        'lastCompleted': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Adding habit: $habit'); // Debug log
      final docRef = await _userHabits().add(habit);
      print('Successfully added habit with ID: ${docRef.id}'); // Debug log
    } catch (e) {
      print('Error adding habit: $e'); // Debug log
      rethrow;
    }
  }

  // Get the start of the day for a given DateTime
  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Check if two DateTime objects represent the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    final day1 = _startOfDay(date1);
    final day2 = _startOfDay(date2);
    return day1.isAtSameMomentAs(day2);
  }

  // Increment the streak of a habit
  Future<void> incrementStreak(int index) async {
    if (index >= 0 && index < _habits.length) {
      final habit = _habits[index];
      final now = DateTime.now();
      final lastCompleted = habit['lastCompleted'];

      // Prepare the update data
      Map<String, dynamic> updateData = {
        'lastCompleted': now.toIso8601String(),
      };

      // First completion case
      if (lastCompleted == null) {
        updateData['streak'] = 1;
      } else {
        final lastCompletedDate = lastCompleted is DateTime
            ? lastCompleted
            : DateTime.parse(lastCompleted.toString());

        // If it's the same day, don't change the streak
        if (_isSameDay(now, lastCompletedDate)) {
          return;
        }

        final todayStart = _startOfDay(now);
        final lastCompletedStart = _startOfDay(lastCompletedDate);
        final nextDayStart = lastCompletedStart.add(const Duration(days: 1));

        // Check if completion is within the next day
        if (_startOfDay(now).isAtSameMomentAs(_startOfDay(nextDayStart))) {
          // Completed during the next day, increment streak
          updateData['streak'] = (habit['streak'] as int) + 1;
        } else if (todayStart.isAfter(nextDayStart)) {
          // More than one day has passed, reset streak to 0
          updateData['streak'] = 0;
        }
      }

      await _userHabits().doc(habit['id']).update(updateData);
    }
  }

  // Reset the streak of a habit
  Future<void> resetStreak(int index) async {
    if (index >= 0 && index < _habits.length) {
      final habit = _habits[index];
      await _userHabits().doc(habit['id']).update({
        'streak': 0,
        'lastCompleted': null,
      });
    }
  }

  // Edit an existing habit
  Future<void> editHabit(int index, String name, int durationMinutes) async {
    if (index >= 0 && index < _habits.length) {
      final habit = _habits[index];
      await _userHabits().doc(habit['id']).update({
        'name': name,
        'durationMinutes': durationMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete a habit
  Future<void> deleteHabit(int index) async {
    if (index >= 0 && index < _habits.length) {
      final habit = _habits[index];
      await _userHabits().doc(habit['id']).delete();
    }
  }

  // Clean up on dispose
  @override
  void dispose() {
    _habitsSubscription?.cancel();
    super.dispose();
  }
}
