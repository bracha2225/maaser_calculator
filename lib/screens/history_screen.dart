import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBalance();
  }

  Future<void> _fetchCurrentBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final baseIncome = data['base_income']?.toDouble() ?? 0;
      final additionalIncome = data['additional_income']?.toDouble() ?? 0;
      final given = data['current_given']?.toDouble() ?? 0;
      final percent = data['percent']?.toDouble() ?? 10;
      final previousBalance = data['balance']?.toDouble() ?? 0;

      final totalIncome = baseIncome + additionalIncome;
      final shouldGive = totalIncome * percent / 100;
      final currentMonthBalance = given - shouldGive;

      setState(() {
        _currentBalance = previousBalance + currentMonthBalance;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Map<String, List<QueryDocumentSnapshot>> _groupByMonth(List<QueryDocumentSnapshot> docs) {
    Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateString = data['date'] as String? ?? '';
      try {
        final date = DateTime.parse(dateString);
        final monthKey = DateFormat('MM/yyyy').format(date);
        if (!grouped.containsKey(monthKey)) {
          grouped[monthKey] = [];
        }
        grouped[monthKey]!.add(doc);
      } catch (e) {
        // אם יש בעיה בתאריך, נשים את זה תחת "אחר"
        if (!grouped.containsKey('אחר')) {
          grouped['אחר'] = [];
        }
        grouped['אחר']!.add(doc);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('היסטוריית מעשר'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // יתרה נוכחית
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentBalance >= 0 ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              _currentBalance >= 0
                  ? 'יתרה נוכחית: ${_currentBalance.toStringAsFixed(2)} ₪'
                  : 'חוב נוכחי: ${(-_currentBalance).toStringAsFixed(2)} ₪',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _currentBalance >= 0 ? Colors.green[800] : Colors.red[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // היסטוריה
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('history')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text('אין נתונים'));

                final groupedDocs = _groupByMonth(docs);

                return ListView(
                  children: groupedDocs.entries.map((entry) {
                    final month = entry.key;
                    final monthDocs = entry.value;
                    final monthTotal = monthDocs.fold<double>(0, (sum, doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return sum + (data['amount']?.toDouble() ?? 0);
                    });

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text(
                          'חודש $month',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('סה"כ תרומות: ${monthTotal.toStringAsFixed(2)} ₪'),
                        children: monthDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: Icon(Icons.monetization_on, color: Colors.green),
                            title: Text('תרומה: ${(data['amount']?.toDouble() ?? 0).toStringAsFixed(2)} ₪'),
                            subtitle: Text('תאריך: ${_formatDate(data['date'] ?? '')}'),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}