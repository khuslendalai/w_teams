import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 7, 1, 96)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}