import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaaserScreen extends StatefulWidget {
  @override
  _MaaserScreenState createState() => _MaaserScreenState();
}

class _MaaserScreenState extends State<MaaserScreen> {
  double _income = 0;
  double _given = 0;
  double _percent = 10;
  double _toGive = 0;
  double _balance = 0;

  final TextEditingController _incomeController = TextEditingController();
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
        _income = data['current_income']?.toDouble() ?? 0;
        _given = data['current_given']?.toDouble() ?? 0;
        _balance = data['balance']?.toDouble() ?? 0;
        _toGive = (_income * _percent / 100) - _given;
      });
    }
  }

  Future<void> _updateIncome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final income = double.tryParse(_incomeController.text) ?? 0;
    setState(() {
      _income = income;
      _toGive = (_income * _percent / 100) - _given;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'current_income': _income,
      'current_given': _given,
      'percent': _percent,
      'balance': _balance,
    }, SetOptions(merge: true));
  }

  Future<void> _addGiven() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final given = double.tryParse(_givenController.text) ?? 0;
    setState(() {
      _given += given;
      _balance += given - (_income * _percent / 100);
      _toGive = (_income * _percent / 100) - _given;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'current_given': _given,
      'balance': _balance,
    });
    // אפשר להוסיף גם רישום להיסטוריה כאן
  }

  void _changePercent(double value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _percent = value;
      _toGive = (_income * _percent / 100) - _given;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'percent': _percent,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
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
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'הכנסה חודשית'),
          ),
          ElevatedButton(
            onPressed: _updateIncome,
            child: Text('עדכן הכנסה'),
          ),
          SizedBox(height: 20),
          Text('מעשר על החודש: ${(_income * _percent / 100).toStringAsFixed(2)} ₪'),
          Text('נתת החודש: ${_given.toStringAsFixed(2)} ₪'),
          Text('נותר להפריש: ${_toGive.toStringAsFixed(2)} ₪'),
          Text('יתרת זכות/חוב: ${_balance.toStringAsFixed(2)} ₪'),
          Divider(),
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