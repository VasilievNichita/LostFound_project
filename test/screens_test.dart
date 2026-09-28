import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/data/mock_data.dart';
import 'package:lost_found/screens/login_screen.dart';
import 'package:lost_found/screens/board_screen.dart';
import 'package:lost_found/screens/item_detail_screen.dart';
import 'package:lost_found/screens/item_form_screen.dart';
import 'package:lost_found/screens/claim_screen.dart';
import 'package:lost_found/screens/messages_screen.dart';
import 'package:lost_found/screens/my_activity_screen.dart';
import 'package:lost_found/screens/profile_screen.dart';

void main() {
  const screens = <(String, Widget)>[
    ('Вход / регистрация', LoginScreen()),
    ('Доска объявлений', BoardScreen()),
    ('Карточка вещи', ItemDetailScreen()),
    ('Создание / редактирование', ItemFormScreen()),
    ('Заявка владельца', ClaimScreen()),
    ('Сообщения по заявке', MessagesScreen()),
    ('Мои объявления и заявки', MyActivityScreen()),
    ('Профиль пользователя', ProfileScreen()),
  ];

  test('Mock-данные полны и связи заявок согласованы', () {
    expect(foundItems.length, 8);
    expect(lostItems.length, 8);
    expect(myItems.length, 8);
    expect(claims.length, 8);
    expect(messages.length, 8);
    expect(allItems.map((i) => i.id).toSet().length, allItems.length);
    for (final claim in claims) {
      final item = allItems.singleWhere((item) => item.id == claim.itemId);
      expect(item.userId, isNot(claim.userId));
    }
    for (final message in messages) {
      expect(claims.any((claim) => claim.id == message.claimId), isTrue);
    }
  });

  for (final configuration in [
    (320.0, 640.0, 1.0),
    (412.0, 915.0, 1.0),
    (360.0, 800.0, 1.3),
  ]) {
    for (final entry in screens) {
      testWidgets(
        '${entry.$1}: ${configuration.$1}, текст ${configuration.$3}',
        (tester) async {
          final size = Size(configuration.$1, configuration.$2);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            LostFoundApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(configuration.$3),
                ),
                child: entry.$2,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Проверяем также элементы списков, создаваемые только при прокрутке.
          for (var step = 0; step < 9; step++) {
            await tester.drag(
              find.byType(Scaffold).first,
              const Offset(0, -450),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('Все восемь экранов доступны через меню и кнопку назад', (
    tester,
  ) async {
    await tester.pumpWidget(const LostFoundApp());
    for (final entry in screens) {
      await tester.scrollUntilVisible(
        find.text(entry.$1),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(find.byType(entry.$2.runtimeType), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Вход не проверяет поля и не авторизует пользователя', (
    tester,
  ) async {
    await tester.pumpWidget(const LostFoundApp(home: LoginScreen()));
    await tester.enterText(find.byType(TextField).first, 'не почта');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(Form), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
