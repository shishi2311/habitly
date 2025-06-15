import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/timer_provider.dart';
import 'edit_habit_dialog.dart';

class HabitListItem extends StatelessWidget {
  final Map<String, dynamic> habit;
  final int index;
  final bool isEditMode;
  final bool isSelected;
  final Function(int) onToggleSelection;
  final Function(int) onCompletionHandler;

  const HabitListItem({
    super.key,
    required this.habit,
    required this.index,
    required this.isEditMode,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onCompletionHandler,
  });

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final isActive = timerProvider.isActive(index);

    return Card(
      elevation: 2,
      child: Row(
        children: [
          if (isEditMode)
            IconButton(
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.red : Colors.grey,
              ),
              onPressed: () => onToggleSelection(index),
            ),
          Expanded(
            child: ListTile(
              title: Text(
                habit['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isActive)
                    Text(
                      '${timerProvider.getCurrentSeconds(index) ~/ 60}:${(timerProvider.getCurrentSeconds(index) % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      '${habit['durationMinutes']} minutes',
                    ),
                  Text('Streak: ${habit['streak']} days'),
                ],
              ),
              trailing: _buildTrailingWidget(context, isActive, timerProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    bool isActive,
    TimerProvider timerProvider,
  ) {
    if (!isEditMode) {
      if (isActive) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Stop Timer',
              onPressed: () => timerProvider.stopTimer(index),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Complete Early',
              onPressed: () {
                timerProvider.stopTimer(index, completed: true);
                onCompletionHandler(index);
              },
            ),
          ],
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          tooltip: 'Start Timer',
          onPressed: () {
            timerProvider.startTimer(
              index,
              habit['durationMinutes'],
              onComplete: () => onCompletionHandler(index),
            );
          },
        );
      }
    } else {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => EditHabitDialog(
              initialName: habit['name'],
              initialDuration: habit['durationMinutes'],
              index: index,
            ),
          );
        },
      );
    }
  }
}
