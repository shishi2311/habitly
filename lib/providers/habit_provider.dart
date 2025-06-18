import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HabitProvider with ChangeNotifier {
  // List to store all habits
  final List<Map<String, dynamic>> _habits = [];
  static const String _storageKey = 'habits';
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Getter for habits
  List<Map<String, dynamic>> get habits => [..._habits];

  // Initialize SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadHabits();
    _isInitialized = true;
  }

  // Load habits from storage
  void _loadHabits() {
    final habitsJson = _prefs.getString(_storageKey);
    if (habitsJson != null) {
      final habitsList = jsonDecode(habitsJson) as List;
      _habits.clear();
      _habits.addAll(habitsList.map((item) {
        final habit = Map<String, dynamic>.from(item);
        // Convert lastCompleted string back to DateTime if it exists
        if (habit['lastCompleted'] != null) {
          habit['lastCompleted'] = DateTime.parse(habit['lastCompleted']);
        }
        return habit;
      }));
      notifyListeners();
    }
  }

  // Save habits to storage
  Future<void> _saveHabits() async {
    final habitsList = _habits.map((habit) {
      final habitCopy = Map<String, dynamic>.from(habit);
      // Convert DateTime to string for storage
      if (habitCopy['lastCompleted'] != null) {
        habitCopy['lastCompleted'] = (habitCopy['lastCompleted'] as DateTime).toIso8601String();
      }
      return habitCopy;
    }).toList();
    
    await _prefs.setString(_storageKey, jsonEncode(habitsList));
  }

  // Add a new habit
  void addHabit(String name, int durationMinutes) {
    _habits.add({
      'name': name,
      'durationMinutes': durationMinutes,
      'streak': 0,
      'lastCompleted': null,
    });
    _saveHabits();
    notifyListeners();
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
  void incrementStreak(int index) {
    if (index >= 0 && index < _habits.length) {
      final now = DateTime.now();
      final lastCompleted = _habits[index]['lastCompleted'];
      
      // First completion case
      if (lastCompleted == null) {
        _habits[index]['streak'] = 1;
        _habits[index]['lastCompleted'] = now;
        _saveHabits();
        notifyListeners();
        return;
      }

      // Convert lastCompleted to DateTime if needed
      final lastCompletedDate = lastCompleted is DateTime 
          ? lastCompleted 
          : DateTime.parse(lastCompleted.toString());
      
      // If it's the same day, don't change the streak
      if (_isSameDay(now, lastCompletedDate)) {
        return;
      }

      final todayStart = _startOfDay(now);
      final lastCompletedStart = _startOfDay(lastCompletedDate);
      final daysDifference = todayStart.difference(lastCompletedStart).inDays;

      // If completed on consecutive day (1 day difference), increment streak
      if (daysDifference == 1) {
        _habits[index]['streak'] = (_habits[index]['streak'] as int) + 1;
      } else {
        // More than one day has passed, reset streak to 0
        _habits[index]['streak'] = 0;
      }
      
      _habits[index]['lastCompleted'] = now;
      _saveHabits();
      notifyListeners();
    }
  }

  // Reset the streak of a habit
  void resetStreak(int index) {
    if (index >= 0 && index < _habits.length) {
      _habits[index]['streak'] = 0;
      _habits[index]['lastCompleted'] = null;
      _saveHabits();
      notifyListeners();
    }
  }

  // Edit an existing habit
  void editHabit(int index, String name, int durationMinutes) {
    if (index >= 0 && index < _habits.length) {
      _habits[index]['name'] = name;
      _habits[index]['durationMinutes'] = durationMinutes;
      _saveHabits();
      notifyListeners();
    }
  }

  // Delete a habit
  void deleteHabit(int index) {
    if (index >= 0 && index < _habits.length) {
      _habits.removeAt(index);
      _saveHabits();
      notifyListeners();
    }
  }
}
