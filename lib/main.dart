import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WTeamsApp());
}

class WTeamsApp extends StatelessWidget {
  const WTeamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_teams',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 1, 4, 104)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}