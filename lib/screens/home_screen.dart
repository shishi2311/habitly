import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/habit_list_item.dart';
import '../widgets/add_habit_dialog.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEditMode = false;
  final Set<int> _selectedItems = {};

  @override
void initState() {
  super.initState();
  Future.microtask(() {
    Provider.of<HabitProvider>(context, listen: false).init();
  });
}

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
      _isEditMode = false; // ✅ Always exit edit mode
   });
  }

  void _handleHabitCompletion(int index) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
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

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);

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
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(habitProvider),
      floatingActionButton: _buildFloatingActionButton(context, habitProvider),
    );
  }

  Widget _buildBody(HabitProvider habitProvider) {
    if (habitProvider.habits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No habits yet!!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first habit',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: habitProvider.habits.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final habit = habitProvider.habits[index];
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
              child: const Icon(Icons.delete, color: Colors.grey),
            ),
            child: HabitListItem(
              habit: habit,
              index: index,
              isEditMode: _isEditMode,
              isSelected: isSelected,
              onToggleSelection: _toggleItemSelection,
              onCompletionHandler: _handleHabitCompletion,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    HabitProvider habitProvider,
  ) {
    return FloatingActionButton(
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
      child: Icon(_isEditMode ? Icons.delete : Icons.add, color: Colors.grey),
    );
  }
}
