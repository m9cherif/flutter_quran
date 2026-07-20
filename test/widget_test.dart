import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran/main.dart';

void main() {
  testWidgets('App loads annotation screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QuranAnnotationApp());
    expect(find.text('أدخل رقم الصفحة لبدء التحديد'), findsOneWidget);
  });
}
