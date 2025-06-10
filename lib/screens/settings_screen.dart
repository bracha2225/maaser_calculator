import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _reminder = 'חודשי';

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _reminder = doc['reminder'] ?? 'חודשי';
      });
    }
  }

  Future<void> _updateReminder(String value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _reminder = value;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'reminder': value,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(title: Text('תדירות תזכורת')),
        DropdownButton<String>(
          value: _reminder,
          items: [
            DropdownMenuItem(value: 'חודשי', child: Text('חודשי')),
            DropdownMenuItem(value: 'דו-חודשי', child: Text('דו-חודשי')),
            DropdownMenuItem(value: 'שבועי', child: Text('שבועי')),
          ],
          onChanged: (v) {
            if (v != null) _updateReminder(v);
          },
        ),
      ],
    );
  }
}