import 'package:flutter/foundation.dart';
import 'dart:async';

class TimerProvider with ChangeNotifier {
  final Map<int, Timer> _timers = {};
  final Map<int, int> _currentSeconds = {};
  final Map<int, bool> _isActive = {};
  final Map<int, int> _totalSeconds = {};
  final Map<int, Function?> _onComplete = {};

  // Getters
  bool isActive(int habitIndex) => _isActive[habitIndex] ?? false;
  int getCurrentSeconds(int habitIndex) => _currentSeconds[habitIndex] ?? 0;
  int? getTotalSeconds(int habitIndex) => _totalSeconds[habitIndex];

  // Start timer
  void startTimer(int habitIndex, int minutes, {Function? onComplete}) {
    _totalSeconds[habitIndex] = minutes * 60;
    _currentSeconds[habitIndex] = _totalSeconds[habitIndex]!;
    _isActive[habitIndex] = true;
    _onComplete[habitIndex] = onComplete;
    
    _timers[habitIndex]?.cancel();
    _timers[habitIndex] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds[habitIndex]! > 0) {
        _currentSeconds[habitIndex] = _currentSeconds[habitIndex]! - 1;
        notifyListeners();
      } else {
        // Timer completed naturally
        stopTimer(habitIndex, completed: true);
      }
    });
    notifyListeners();
  }

  // Stop timer
  void stopTimer(int habitIndex, {bool completed = false}) {
    _timers[habitIndex]?.cancel();
    _isActive[habitIndex] = false;
    _currentSeconds[habitIndex] = 0;
    _totalSeconds.remove(habitIndex);
    
    if (completed && _onComplete[habitIndex] != null) {
      _onComplete[habitIndex]!();
    }
    
    _onComplete.remove(habitIndex);
    notifyListeners();
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
