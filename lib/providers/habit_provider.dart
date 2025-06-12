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

  // Check if two DateTime objects represent the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Increment the streak of a habit
  void incrementStreak(int index) {
    if (index >= 0 && index < _habits.length) {
      final now = DateTime.now();
      final lastCompleted = _habits[index]['lastCompleted'];
      
      print('Debug - Current habit state:');
      print('Name: ${_habits[index]['name']}');
      print('Current streak: ${_habits[index]['streak']}');
      print('Last completed: $lastCompleted');
      print('Current time: $now');

      // First completion case
      if (lastCompleted == null) {
        print('Debug - First completion');
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
        print('Debug - Same day, no streak change');
        return;
      }

      // Check if it's yesterday
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final isYesterday = _isSameDay(lastCompletedDate, yesterday);

      print('Debug - Is yesterday: $isYesterday');

      if (isYesterday) {
        // Completed on consecutive days, increment streak
        print('Debug - Consecutive day, incrementing streak');
        _habits[index]['streak'] = (_habits[index]['streak'] as int) + 1;
        _habits[index]['lastCompleted'] = now;
        _saveHabits();
        notifyListeners();
      } else if (lastCompletedDate.isBefore(yesterday)) {
        // More than one day has passed, reset streak
        print('Debug - More than one day passed, resetting streak');
        _habits[index]['streak'] = 1;
        _habits[index]['lastCompleted'] = now;
        _saveHabits();
        notifyListeners();
      }
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
