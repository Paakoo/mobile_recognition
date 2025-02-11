import 'package:flutter/material.dart';
import 'package:tes/screen/screen.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => SplashScreen(),
        "/login": (context) => LoginScreen(),
        "/liveness": (context) => const LivenessScreen(),
        "/main": (context) => HomeScreen(),
        "/history": (context) => HistoryScreen(),
      },
    );
  }
}
