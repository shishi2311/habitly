import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Habitly/firebase_options.dart';
import 'package:Habitly/providers/habit_provider.dart';
import 'package:Habitly/providers/timer_provider.dart';
import 'package:Habitly/providers/auth_provider.dart';
import 'package:Habitly/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize HabitProvider
  final habitProvider = HabitProvider();
  await habitProvider.init();

  runApp(MyApp(habitProvider: habitProvider));
}

class MyApp extends StatelessWidget {
  final HabitProvider habitProvider;

  const MyApp({super.key, required this.habitProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: habitProvider),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Habitly',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const AuthScreen();
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEditMode = false;
  final Set<int> _selectedItems = {};

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectedItems.clear();
    });
  }

  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedItems.contains(index)) {
        _selectedItems.remove(index);
      } else {
        _selectedItems.add(index);
      }
    });
  }

  void _deleteSelectedItems() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final sortedIndices = _selectedItems.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      habitProvider.deleteHabit(index);
    }

    setState(() {
      _selectedItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context);

    void handleHabitCompletion(int index) {
      habitProvider.incrementStreak(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Great job completing ${habitProvider.habits[index]['name']}!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Timer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (habitProvider.habits.isNotEmpty)
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditMode ? 'Done' : 'Edit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (habitProvider.habits.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No habits yet!!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first habit',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: habitProvider.habits.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final habit = habitProvider.habits[index];
                    final isActive = timerProvider.isActive(index);
                    final isSelected = _selectedItems.contains(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Dismissible(
                        key: Key('habit_$index'),
                        direction: _isEditMode
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        confirmDismiss: (_) async {
                          if (_isEditMode) {
                            _toggleItemSelection(index);
                            return false;
                          }
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          elevation: 2,
                          child: Row(
                            children: [
                              if (_isEditMode)
                                IconButton(
                                  icon: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleItemSelection(index),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  trailing: !_isEditMode
                                      ? isActive
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.stop,
                                                    ),
                                                    tooltip: 'Stop Timer',
                                                    onPressed: () =>
                                                        timerProvider.stopTimer(
                                                          index,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                    ),
                                                    tooltip: 'Complete Early',
                                                    onPressed: () {
                                                      timerProvider.stopTimer(
                                                        index,
                                                        completed: true,
                                                      );
                                                      handleHabitCompletion(
                                                        index,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              )
                                            : IconButton(
                                                icon: const Icon(
                                                  Icons.play_arrow,
                                                ),
                                                tooltip: 'Start Timer',
                                                onPressed: () {
                                                  timerProvider.startTimer(
                                                    index,
                                                    habit['durationMinutes'],
                                                    onComplete: () =>
                                                        handleHabitCompletion(
                                                          index,
                                                        ),
                                                  );
                                                },
                                              )
                                      : IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  EditHabitDialog(
                                                    initialName: habit['name'],
                                                    initialDuration:
                                                        habit['durationMinutes'],
                                                    index: index,
                                                  ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isEditMode
            ? _selectedItems.isNotEmpty
                  ? _deleteSelectedItems
                  : null
            : () => showDialog(
                context: context,
                builder: (context) => const AddHabitDialog(),
              ),
        backgroundColor: _isEditMode
            ? (_selectedItems.isNotEmpty ? Colors.red : Colors.grey)
            : Theme.of(context).colorScheme.primary,
        child: Icon(
          _isEditMode ? Icons.delete : Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Habit Name',
              hintText: 'e.g., Study, Read, Exercise',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'e.g., 25',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _durationController.text.isNotEmpty) {
              final duration = int.tryParse(_durationController.text);
              if (duration != null && duration > 0) {
                context.read<HabitProvider>().addHabit(
                  _nameController.text,
                  duration,
                );
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class EditHabitDialog extends StatefulWidget {
  final String initialName;
  final int initialDuration;
  final int index;

  const EditHabitDialog({
    super.key,
    required this.initialName,
    required this.initialDuration,
    required this.index,
  });

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _durationController = TextEditingController(
      text: widget.initialDuration.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Habit Name',
              hintText: 'e.g., Study, Read, Exercise',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'e.g., 25',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _durationController.text.isNotEmpty) {
              final duration = int.tryParse(_durationController.text);
              if (duration != null && duration > 0) {
                context.read<HabitProvider>().editHabit(
                  widget.index,
                  _nameController.text,
                  duration,
                );
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
