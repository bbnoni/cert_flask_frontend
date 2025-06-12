import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_frontend/screens/auditor_home_screen.dart';
import 'package:flutter_frontend/screens/home_screen.dart';
import 'package:http/http.dart' as http;

import 'attendance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String error = '';
  bool isLoading = false;
  bool isRegistering = false; // Toggle between login and registration

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        error = 'Please fill in all fields.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        error = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final url = Uri.parse('${dotenv.env['API_URL']}/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'name': name, 'password': password}),
      );

      if (response.statusCode == 201) {
        // Registration successful, switch to login
        setState(() {
          isRegistering = false;
          nameController.clear();
          error = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          error = data['error'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Registration failed. Please try again.';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

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
                  (_) => HomeScreen(
                    userId: data['id'],
                    branches: List<String>.from(data['branches'] ?? []),
                    userName: data['name'] ?? 'User', // <-- Pass the name!
                  ),
            ),
          );
        } else if (role == 'auditor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuditorHomeScreen()),
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
      appBar: AppBar(
        title: Text(isRegistering ? "Register" : "Login"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            // Email Field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Name Field (only for registration)
            if (isRegistering) ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),

            // Main Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          if (isRegistering) {
                            register();
                          } else {
                            login();
                          }
                        },
                child:
                    isLoading
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          isRegistering ? "Register" : "Login",
                          style: const TextStyle(fontSize: 18),
                        ),
              ),
            ),
            const SizedBox(height: 10),

            // Toggle between Login and Register
            TextButton(
              onPressed: () {
                setState(() {
                  isRegistering = !isRegistering;
                  nameController.clear();
                  error = '';
                });
              },
              child: Text(
                isRegistering
                    ? "Already have an account? Login"
                    : "Need an account? Register",
              ),
            ),

            // Error Message
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
