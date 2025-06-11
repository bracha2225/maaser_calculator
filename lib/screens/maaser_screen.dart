import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'halacha_screen.dart';
import 'history_screen.dart';

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

  double get _totalIncome => _baseIncome + _additionalIncome;
  double get _shouldGive => _totalIncome * _percent / 100;
  double get _remainingToGive => _shouldGive - _given;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  Text('יתרת חוב/זכות מחודשים קודמים: ${_balance.toStringAsFixed(2)} ₪',
                      style: TextStyle(color: _balance < 0 ? Colors.red : Colors.green)),
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
        ],
      ),
    );
  }
}