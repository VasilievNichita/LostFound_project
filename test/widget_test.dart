import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/router.dart';

void main() {
  testWidgets('Вход вне оболочки, адрес выбирает нужную вещь', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(LostFoundApp(routerConfig: router));
    expect(find.byType(NavigationBar), findsNothing);
    router.go('/items/i2');
    await tester.pumpAndSettle();
    expect(find.text('Связка ключей с синим брелоком'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    router.go('/items/unknown');
    await tester.pumpAndSettle();
    expect(find.text('Страница не найдена'), findsOneWidget);
  });
}
