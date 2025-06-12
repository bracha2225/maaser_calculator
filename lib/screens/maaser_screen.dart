import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'halacha_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MaaserScreen extends StatefulWidget {
  @override
  _MaaserScreenState createState() => _MaaserScreenState();
}

class _MaaserScreenState extends State<MaaserScreen> {
  double _baseIncome = 0; // משכורת קבועה
  double _additionalIncome = 0; // הכנסה נוספת החודש
  double _given = 0;
  double _percent = 10;
  double _balance = 0; // יתרת חוב/זכות מחודשים קודמים

  final TextEditingController _baseIncomeController = TextEditingController();
  final TextEditingController _additionalIncomeController = TextEditingController();
  final TextEditingController _givenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentData();
  }

  Future<void> _fetchCurrentData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _percent = data['percent']?.toDouble() ?? 10;
        _baseIncome = data['base_income']?.toDouble() ?? 0;
        _additionalIncome = data['additional_income']?.toDouble() ?? 0;
        _given = data['current_given']?.toDouble() ?? 0;
        _balance = data['balance']?.toDouble() ?? 0;
      });
      _baseIncomeController.text = _baseIncome.toString();
    }
  }

  Future<void> _updateBaseIncome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final income = double.tryParse(_baseIncomeController.text) ?? 0;
    setState(() {
      _baseIncome = income;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'base_income': _baseIncome,
      'additional_income': _additionalIncome,
      'current_given': _given,
      'percent': _percent,
      'balance': _balance,
    }, SetOptions(merge: true));

    // סגירת המקלדת
    FocusScope.of(context).unfocus();
  }

  Future<void> _addAdditionalIncome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final additional = double.tryParse(_additionalIncomeController.text) ?? 0;
    setState(() {
      _additionalIncome += additional;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'additional_income': _additionalIncome,
    });
    _additionalIncomeController.clear();

    // סגירת המקלדת
    FocusScope.of(context).unfocus();
  }

  Future<void> _addGiven() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final given = double.tryParse(_givenController.text) ?? 0;
    setState(() {
      _given += given;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'current_given': _given,
    });

    // הוספה להיסטוריה
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history')
        .add({
      'amount': given,
      'date': DateTime.now().toIso8601String(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _givenController.clear();

    // סגירת המקלדת
    FocusScope.of(context).unfocus();
  }

  void _changePercent(double value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _percent = value;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'percent': _percent,
    });
  }

  Future<void> _resetCurrentMonth() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('איפוס חודש נוכחי'),
          content: Text('האם אתה בטוח שברצונך למחוק את כל הנתונים של החודש הנוכחי?'),
          actions: [
            TextButton(
              child: Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('אישור'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // מחיקת ההיסטוריה של החודש הנוכחי
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(Duration(days: 1));

      final historyQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .get();

      for (var doc in historyQuery.docs) {
        await doc.reference.delete();
      }

      // איפוס הנתונים הנוכחיים
      setState(() {
        _additionalIncome = 0;
        _given = 0;
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'additional_income': 0,
        'current_given': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('החודש הנוכחי אופס בהצלחה')),
      );
    }
  }

  Future<void> _resetAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('איפוס כל ההיסטוריה'),
          content: Text('האם אתה בטוח שברצונך למחוק את כל ההיסטוריה? פעולה זו לא ניתנת לביטול!'),
          actions: [
            TextButton(
              child: Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('אישור'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // בקשת סיסמה
      final passwordController = TextEditingController();
      final passwordConfirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('אישור סיסמה'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('הזן את הסיסמה שלך לאישור מחיקת כל ההיסטוריה:'),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'סיסמה'),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('ביטול'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('אישור'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (passwordConfirmed == true) {
        try {
          // אימות הסיסמה
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final credential = EmailAuthProvider.credential(
              email: user.email!,
              password: passwordController.text,
            );
            await user.reauthenticateWithCredential(credential);

            // מחיקת כל ההיסטוריה
            final uid = user.uid;
            final historyQuery = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('history')
                .get();

            for (var doc in historyQuery.docs) {
              await doc.reference.delete();
            }

            // איפוס כל הנתונים
            setState(() {
              _baseIncome = 0;
              _additionalIncome = 0;
              _given = 0;
              _balance = 0;
            });

            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'base_income': 0,
              'additional_income': 0,
              'current_given': 0,
              'balance': 0,
              'percent': _percent,
            });

            _baseIncomeController.clear();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('כל ההיסטוריה נמחקה בהצלחה')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('סיסמה שגויה או שגיאה במחיקה')),
          );
        }
      }
      passwordController.dispose();
    }
  }

  double get _totalIncome => _baseIncome + _additionalIncome;
  double get _shouldGive => _totalIncome * _percent / 100;
  double get _remainingToGive => _shouldGive - _given;
  double get _currentBalance => _balance + (_given - _shouldGive);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // סגירת מקלדת בלחיצה על המסך
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // כפתורי ניווט
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HalachaScreen()),
                    );
                  },
                  child: Text('הלכות'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                  child: Text('היסטוריה'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                  child: Text('הגדרות'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // אחוז הפרשה
            Row(
              children: [
                Text('אחוז הפרשה:'),
                SizedBox(width: 10),
                DropdownButton<double>(
                  value: _percent,
                  items: [
                    DropdownMenuItem(child: Text('מעשר (10%)'), value: 10),
                    DropdownMenuItem(child: Text('חומש (20%)'), value: 20),
                  ],
                  onChanged: (value) {
                    if (value != null) _changePercent(value);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            // משכורת קבועה
            Text('משכורת קבועה נוכחית: ${_baseIncome.toStringAsFixed(2)} ₪',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _baseIncomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'עדכון משכורת קבועה'),
            ),
            ElevatedButton(
              onPressed: _updateBaseIncome,
              child: Text('עדכן משכורת קבועה'),
            ),
            SizedBox(height: 20),

            // הכנסה נוספת
            Text('הכנסה נוספת החודש: ${_additionalIncome.toStringAsFixed(2)} ₪'),
            TextField(
              controller: _additionalIncomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'הכנסה נוספת (חד פעמי)'),
            ),
            ElevatedButton(
              onPressed: _addAdditionalIncome,
              child: Text('הוסף הכנסה נוספת'),
            ),
            SizedBox(height: 20),

            // סיכום
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('סיכום החודש:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('סה"כ הכנסה: ${_totalIncome.toStringAsFixed(2)} ₪'),
                  Text('מעשר על החודש: ${_shouldGive.toStringAsFixed(2)} ₪'),
                  Text('נתת החודש: ${_given.toStringAsFixed(2)} ₪'),
                  Text('נותר להפריש: ${_remainingToGive.toStringAsFixed(2)} ₪',
                      style: TextStyle(color: _remainingToGive > 0 ? Colors.red : Colors.green)),
                  if (_balance != 0)
                    Text(
                        _balance > 0
                            ? 'יתרת זכות מחודשים קודמים: ${_balance.toStringAsFixed(2)} ₪'
                            : 'יתרת חוב מחודשים קודמים: ${(-_balance).toStringAsFixed(2)} ₪',
                        style: TextStyle(color: _balance > 0 ? Colors.green : Colors.red)
                    ),
                  Divider(),
                  Text(
                      _currentBalance >= 0
                          ? 'מצב כללי - יתרת זכות: ${_currentBalance.toStringAsFixed(2)} ₪'
                          : 'מצב כללי - יתרת חוב: ${(-_currentBalance).toStringAsFixed(2)} ₪',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentBalance >= 0 ? Colors.green : Colors.red
                      )
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // הוספת תרומה
            TextField(
              controller: _givenController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'סכום תרומה חדש'),
            ),
            ElevatedButton(
              onPressed: _addGiven,
              child: Text('עדכן תרומה'),
            ),
            SizedBox(height: 20),

            // כפתורי איפוס
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetCurrentMonth,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text('איפוס חודש נוכחי'),
                ),
                ElevatedButton(
                  onPressed: _resetAllHistory,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('איפוס כל ההיסטוריה'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}