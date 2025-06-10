import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'maaser_screen.dart';
import 'halacha_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    MaaserScreen(), // מסך עיקרי של חישוב ונתונים
    HalachaScreen(), // מסך הלכות
    HistoryScreen(), // היסטוריה
    SettingsScreen(), // הגדרות
  ];

  final List<String> _titles = [
    'מעשר כספים',
    'הלכות מעשר',
    'היסטוריה',
    'הגדרות',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'מעשר'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'הלכות'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'היסטוריה'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'הגדרות'),
        ],
      ),
    );
  }
}