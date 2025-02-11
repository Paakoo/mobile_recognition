import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkToken();
  }

  Future<void> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (token == null) {
      // No token found, redirect to login
      navigateToLogin();
      return;
    }

    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final DateTime expirationDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      
      if (DateTime.now().isAfter(expirationDate)) {
        // Token expired
        await prefs.remove('token');
        navigateToLogin();
      } else {
        // Token valid
        navigateToHome();
      }
    } catch (e) {
      // Invalid token format
      await prefs.remove('token');
      navigateToLogin();
    }
  }

  void navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your logo here
            Image.asset(
              'images/image.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}