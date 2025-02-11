// login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();
  bool _isLoading = false;

  void _showNotification(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSuccess ? 'Success' : 'Error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Future<void> login() async {
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _showNotification(
          'Please enter both email and password',
          false
        );
        
        // Shake animation effect for empty fields
        if (email.isEmpty) {
          _emailController.clear();
          FocusScope.of(context).requestFocus(FocusNode());
        }
        if (password.isEmpty) {
          _passwordController.clear();
          FocusScope.of(context).requestFocus(FocusNode());
        }
        
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('http://172.20.10.2:5000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = data['data']['token'];
        await _storage.write(key: 'jwt_token', value: token);
        _showNotification('Login successful', true);
        Navigator.pushReplacementNamed(context, '/cob');
      } else {
        String errorMessage = data['message'] ?? 'Login failed';
        _showNotification(errorMessage, false);
      }
    } catch (e) {
      _showNotification('Connection error', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> viewToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token: $token')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No token found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[500]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue[700]!),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}