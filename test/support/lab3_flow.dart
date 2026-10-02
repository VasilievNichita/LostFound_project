import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/router.dart';
import 'package:lost_found/screens/board_screen.dart';
import 'package:lost_found/screens/item_detail_screen.dart';
import 'package:lost_found/screens/login_screen.dart';
import 'package:lost_found/data/mock_data.dart';

typedef Capture = Future<void> Function(String name);

Future<void> exerciseLab3(WidgetTester tester, Capture capture) async {
  final router = createRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(LostFoundApp(routerConfig: router));
  await tester.pumpAndSettle();

  Future<void> tap(Finder target) async {
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> type(String key, String value) async {
    final field = find.byKey(Key(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> snapshot(String name) async {
    expect(tester.takeException(), isNull);
    await capture(name);
  }

  await type('email', 'wrong');
  await type('password', '123');
  await tap(find.byKey(const Key('auth-submit')));
  expect(find.text('Проверьте адрес, например name@utm.md'), findsOneWidget);
  expect(find.text('В пароле нужно хотя бы 6 символов'), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
  await snapshot('01_login_errors');

  await type('email', 'student@example.org');
  await type('password', 'abcdef');
  await tap(find.byKey(const Key('auth-submit')));
  expect(find.byType(LoginScreen), findsNothing);
  expect(router.canPop(), isFalse);
  await snapshot('02_board_feedback');
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();

  final boardScroll = find
      .descendant(
        of: find.byType(BoardScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.drag(boardScroll, const Offset(0, -300));
  await tester.pumpAndSettle();
  final offset = tester.state<ScrollableState>(boardScroll).position.pixels;
  expect(offset, greaterThan(0));
  await tap(find.text('Мои'));
  await snapshot('03_activity');
  await tap(find.text('Профиль'));
  await snapshot('04_profile');
  await tap(find.text('Доска'));
  expect(tester.state<ScrollableState>(boardScroll).position.pixels, offset);

  await tester.drag(boardScroll, const Offset(0, 1600));
  await tester.pumpAndSettle();
  await tap(find.text(foundItems.first.title));
  expect(find.byType(ItemDetailScreen), findsOneWidget);
  expect(router.state.uri.path, '/items/i1');
  await snapshot('05_item_i1');
  await tap(find.text('Профиль'));
  await tap(find.text('Доска'));
  expect(find.byType(ItemDetailScreen), findsOneWidget);
  await tap(find.text('Это моя вещь'));
  await tap(find.byKey(const Key('claim-submit')));
  expect(
    find.text('Опишите особую примету вещи, хотя бы 10 символов'),
    findsOneWidget,
  );
  await snapshot('06_claim_errors');
  await type('claim-evidence', 'На лямке рюкзака пришита зелёная петля.');
  await tap(find.byKey(const Key('claim-submit')));
  expect(router.state.uri.path, '/items/i1/preview');
  expect(find.text(foundItems.first.title), findsOneWidget);
  await snapshot('07_claim_preview');
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await tap(find.byTooltip('Отправить'));
  expect(find.text('Напишите сообщение автору объявления'), findsOneWidget);
  await type('message-text', 'Где можно забрать вещь?');
  await tap(find.byTooltip('Отправить'));
  expect(find.text('Где можно забрать вещь?'), findsNothing);
  await snapshot('08_message_feedback');
  await tester.pageBack();
  await tester.pumpAndSettle();
  expect(find.byType(ItemDetailScreen), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tap(find.text(foundItems[1].title));
  expect(router.state.uri.path, '/items/i2');
  expect(find.text(foundItems[1].title), findsOneWidget);
  await snapshot('09_item_i2');
  await tester.pageBack();
  await tester.pumpAndSettle();

  final originalCount = allItems.length;
  await tap(find.byTooltip('Добавить объявление'));
  await tap(find.byKey(const Key('item-submit')));
  expect(find.text('Выберите: потерял или нашёл'), findsOneWidget);
  expect(
    find.text('Напишите, какая вещь потеряна или найдена'),
    findsOneWidget,
  );
  expect(find.text('Укажите место в кампусе'), findsOneWidget);
  await tester.ensureVisible(find.byKey(const Key('item-type')));
  await tester.pumpAndSettle();
  await snapshot('10_item_errors');
  await tap(find.byKey(const Key('item-type')));
  await tap(find.text('Нашёл').last);
  await type('item-title', 'Синий чехол для очков');
  await type('item-description', 'Оставлен у стойки выдачи книг.');
  await tap(find.byKey(const Key('item-location')));
  await tap(find.text('Библиотека').last);
  await snapshot('11_item_valid');
  await tap(find.byKey(const Key('item-submit')));
  expect(find.byType(BoardScreen), findsOneWidget);
  expect(allItems.length, originalCount);
  await snapshot('12_item_feedback');

  await tap(find.text('Мои'));
  await tap(find.text(lostItems.first.title));
  await tap(find.text('Редактировать'));
  expect(
    tester
        .widget<TextFormField>(find.byKey(const Key('item-title')))
        .controller!
        .text,
    lostItems.first.title,
  );
  await type('item-title', 'Студенческий билет CR-232');
  await tap(find.byKey(const Key('item-submit')));
  expect(lostItems.first.title, 'Студенческий билет в прозрачной обложке');

  await tap(find.text('Профиль'));
  await tap(find.text('Выйти из аккаунта'));
  await snapshot('13_logout_dialog');
  await tap(find.text('Остаться'));
  expect(find.byType(NavigationBar), findsOneWidget);
  await tap(find.text('Выйти из аккаунта'));
  await tap(find.text('Да, выйти'));
  expect(find.byType(LoginScreen), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
  expect(router.canPop(), isFalse);
  expect(tester.takeException(), isNull);
}
