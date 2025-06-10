import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String error = "";

  Future<void> register() async {
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
    super.dispose();
  }
}