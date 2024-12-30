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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.9:5000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);
      print('Login Response: $data'); // Debug log

      if (data['status'] == 'success' && data['data'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final userData = data['data'];
        
        // Format and store token correctly
        final String token = userData['token']?.toString() ?? '';
        final String tokenType = userData['token_type']?.toString() ?? 'Bearer';
        
        // Store token with proper formatting
        await prefs.setString('token', token);
        await prefs.setString('token_type', tokenType);
        await prefs.setString('email', userData['email']?.toString() ?? '');
        await prefs.setInt('id_karyawan', userData['id_karyawan'] ?? 0);
        await prefs.setString('nama', userData['nama']?.toString() ?? '');
        
        print('Stored token format: $tokenType $token');

        // Handle nullable expires_in
        if (userData['expires_in'] != null) {
          await prefs.setInt('expires_in', userData['expires_in']);
        }

        // Verify token was stored
        final storedToken = prefs.getString('token');
        final storedTokenType = prefs.getString('token_type');

        if (storedToken == null || storedTokenType == null) {
          throw Exception('Failed to store token data');
        }

        print('Token stored successfully: ${data['data']['token_type']} ${data['data']['token']}');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}