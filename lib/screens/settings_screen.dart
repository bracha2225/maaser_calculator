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
    return Scaffold(
      appBar: AppBar(
        title: Text('הגדרות'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // כפתור חזרה למסך הראשי
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('חזרה למסך הראשי'),
              ),
            ),
            SizedBox(height: 20),

            // הגדרות תזכורת
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'הגדרות תזכורת',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('תדירות תזכורת:'),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _reminder,
                      isExpanded: true,
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
                ),
              ),
            ),

            SizedBox(height: 20),

            // מידע על האפליקציה
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מידע על האפליקציה',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('גרסה: 1.0.0'),
                    Text('פותח לעזרה בניהול מעשר כספים'),
                    Text('על פי הלכה יהודית'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}