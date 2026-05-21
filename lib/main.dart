import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SportsApp());
}

// App entry point, starts directly on the login screen
class SportsApp extends StatelessWidget {
  const SportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
