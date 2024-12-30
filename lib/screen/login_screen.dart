import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  // Fungsi untuk login dan mendapatkan token
  Future<void> login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.parse('http://192.168.1.9:5000/api/login'),  // Ganti dengan URL backend Anda
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['data']['token'];

      // Simpan token di secure storage
      await _storage.write(key: 'jwt_token', value: token);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login successful')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid credentials')));
    }
    Navigator.pushReplacementNamed(context, '/home');
  }

  // Fungsi untuk mengakses route yang dilindungi menggunakan token
  Future<void> getProtectedData() async {
    final token = await _storage.read(key: 'jwt_token');

    final response = await http.get(
      Uri.parse('http://192.168.1.11:5000/api/protected'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('JWT Token: $token');
    print('Authirization: $token');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged in as: ${data['logged_in_as']}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token is invalid')));
    }
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
  }

  // Fungsi untuk melihat token yang disimpan di secure storage
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
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: getProtectedData,
              child: Text('Access Protected Data'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: viewToken,
              child: Text('View Token'),
            ),
          ],
        ),
      ),
    );
  }
}