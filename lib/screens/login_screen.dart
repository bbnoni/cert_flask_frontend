import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'attendance_screen.dart';
import 'audit_summary_screen.dart';
import 'upload_certificates_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool isLoading = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final url = Uri.parse('${dotenv.env['API_URL']}/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];

        if (role == 'cleaner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AttendanceScreen(
                    userId: data['id'],
                    name: data['name'] ?? 'Unnamed',
                    location: data['location'] ?? 'Unknown',
                  ),
            ),
          );
        } else if (role == 'executive') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => UploadCertificatesScreen(
                    userId: data['id'],
                    branches: List<String>.from(data['branches'] ?? []),
                  ),
            ),
          );
        } else if (role == 'auditor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuditSummaryScreen()),
          );
        } else {
          setState(() {
            error = 'Unknown role: $role';
          });
        }
      } else {
        setState(() {
          error = 'Invalid credentials';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Login failed. Please try again.';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child:
                  isLoading
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text("Login"),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
