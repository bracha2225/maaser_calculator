import 'package:flutter/material.dart';

class HalachaScreen extends StatelessWidget {
  final String halachaText = '''
הלכות מעשר כספים:

1. כל הכנסה שמרוויחים (משכורת, מתנות, רווחים וכו') יש להפריש ממנה 10% לצדקה.
2. מי שמעוניין להחמיר, מפריש חומש - 20%.
3. את המעשר נותנים לעניים, מוסדות תורה, או צדקה אחרת.
4. יש לעקוב אחר ההפרשות ולנהל רישום מסודר.

*הערה: יש להיוועץ ברב בכל שאלה מעשית.*
''';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Text(halachaText, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}