import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Habitly/firebase_options.dart';
import 'package:Habitly/providers/habit_provider.dart';
import 'package:Habitly/providers/timer_provider.dart';
import 'package:Habitly/providers/auth_provider.dart';
import 'package:Habitly/screens/auth_screen.dart';
import 'package:Habitly/screens/home_screen.dart';
import 'package:Habitly/screens/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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
          colorScheme: ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.white,
            surface: const Color(0xFF1E1E1E),
            background: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
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
