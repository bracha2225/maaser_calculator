import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String error = "";
  String passwordValidationError = "";

  bool _isPasswordValid(String password) {
    // בדיקה שהסיסמה לפחות 8 תווים
    if (password.length < 8) {
      passwordValidationError = "הסיסמה חייבת להכיל לפחות 8 תווים";
      return false;
    }

    // בדיקה שיש לפחות אות אחת
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      passwordValidationError = "הסיסמה חייבת להכיל לפחות אות אחת באנגלית";
      return false;
    }

    // בדיקה שיש לפחות ספרה אחת
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      passwordValidationError = "הסיסמה חייבת להכיל לפחות ספרה אחת";
      return false;
    }

    // בדיקה שאין אותיות עבריות
    if (RegExp(r'[\u0590-\u05FF]').hasMatch(password)) {
      passwordValidationError = "הסיסמה לא יכולה להכיל אותיות עבריות";
      return false;
    }

    passwordValidationError = "";
    return true;
  }

  Future<void> register() async {
    // בדיקה שהסיסמאות זהות
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        error = "הסיסמאות אינן זהות";
      });
      return;
    }

    // בדיקת תקינות הסיסמה
    if (!_isPasswordValid(_passwordController.text)) {
      setState(() {
        error = passwordValidationError;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            error = "אימייל זה כבר רשום במערכת.";
            break;
          case 'invalid-email':
            error = "כתובת אימייל לא תקינה.";
            break;
          case 'weak-password':
            error = "הסיסמה חלשה מדי. יש לבחור סיסמה חזקה יותר (לפחות 6 תווים).";
            break;
          default:
            error = "שגיאה בהרשמה: ${e.message}";
        }
      });
    } catch (e) {
      setState(() {
        error = "שגיאה לא ידועה: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הרשמה')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'אימייל'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'סיסמה'),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  _isPasswordValid(value);
                });
              },
            ),
            if (passwordValidationError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(passwordValidationError, style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'אישור סיסמה'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: register, child: const Text('הרשם')),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(error, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}