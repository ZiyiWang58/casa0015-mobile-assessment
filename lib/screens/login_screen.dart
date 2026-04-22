import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Login and registration screen for email/password authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Submit either a login or registration request based on the current mode.
  Future<void> submit() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty.');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      if (isLoginMode) {
        await AuthService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        await AuthService.registerWithEmail(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorText = 'This account does not exist.';
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          errorText = 'The password is incorrect.';
        } else if (e.code == 'invalid-email') {
          errorText = 'Please enter a valid email address.';
        } else if (e.code == 'email-already-in-use') {
          errorText = 'This email has already been registered.';
        } else if (e.code == 'weak-password') {
          errorText = 'Password must be at least 6 characters.';
        } else {
          errorText = e.message ?? 'Authentication failed.';
        }
      });
    } catch (e) {
      setState(() {
        errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoginMode ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.pets, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (errorText != null)
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : submit,
                child: Text(
                  isLoading
                      ? 'Please wait...'
                      : (isLoginMode ? 'Login' : 'Create Account'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                setState(() {
                  isLoginMode = !isLoginMode;
                  errorText = null;
                });
              },
              child: Text(
                isLoginMode
                    ? 'No account? Register here'
                    : 'Already have an account? Login here',
              ),
            ),
          ],
        ),
      ),
    );
  }
}