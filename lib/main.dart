import 'package:flutter/material.dart';
import 'package:tes/screen/home_screen.dart';
import 'package:tes/screen/liveness_screen.dart';
import 'package:tes/screen/login_screen.dart';
import 'package:tes/screen/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liveness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: "/login",
      routes: {
        "/coba": (context) => CobaScreen(),
        "/login": (context) => LoginScreen(),
        "/home": (context) => HomeScreen(),
        "/liveness": (context) => const LivenessScreen(),
        "/map": (context) => MapScreen()
      },
    );
  }
}
