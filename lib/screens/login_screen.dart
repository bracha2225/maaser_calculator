import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String error = "";

  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-email':
            error = "כתובת האימייל אינה תקינה.";
            break;
          case 'user-disabled':
            error = "המשתמש הזה הושבת.";
            break;
          case 'user-not-found':
            error = "לא קיים משתמש עם האימייל הזה.";
            break;
          case 'wrong-password':
            error = "הסיסמה שגויה.";
            break;
          default:
            error = "שגיאה בהתחברות: ${e.message}";
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
      appBar: AppBar(title: const Text('התחברות')),
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
            const SizedBox(height: 24), // רווח גדול יותר
            ElevatedButton(onPressed: signIn, child: const Text('התחבר')),
            const SizedBox(height: 16), // רווח בין הכפתורים
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text('הרשם'),
            ),
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