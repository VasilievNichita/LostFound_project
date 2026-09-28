import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/main.dart';

void main() {
  testWidgets('Меню демонстрации открывается', (tester) async {
    await tester.pumpWidget(const LostFoundApp());
    expect(find.text('LostFound'), findsOneWidget);
    expect(find.text('Экраны приложения'), findsOneWidget);
  });
}
