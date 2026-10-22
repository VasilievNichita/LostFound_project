import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/router.dart';
import 'package:lost_found/data/mock_repositories.dart';
import 'package:lost_found/models/lost_found_model.dart';

typedef Capture = Future<void> Function(String name);
Future<void> exerciseLab4(
  WidgetTester tester,
  Capture capture, {
  Duration delay = const Duration(milliseconds: 650),
}) async {
  final store = MockStore(delay: delay);
  final router = createRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(LostFoundRoot(store: store, routerConfig: router));
  await tester.pumpAndSettle();
  await capture('00_login');
  Future<void> tap(Finder finder) async {
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  router.go('/items');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await capture('01_loading');
  await tester.pumpAndSettle();
  await capture('02_board_before');
  final model = Provider.of<LostFoundModel>(
    tester.element(find.byType(NavigationBar)),
    listen: false,
  );
  expect(model.items.length, 16);
  await tap(find.text('Профиль'));
  await capture('03_profile_before');
  await tap(find.byKey(const Key('simulate-error')));
  await tap(find.text('Доска'));
  await tap(find.byTooltip('Обновить'));
  expect(find.text('Повторить'), findsOneWidget);
  await capture('04_error');
  await tap(find.text('Профиль'));
  await tap(find.byKey(const Key('simulate-error')));
  await tap(find.text('Доска'));
  await tap(find.text('Повторить'));
  expect(find.byKey(const Key('board-count')), findsOneWidget);

  await tester.enterText(find.byKey(const Key('board-search')), 'рюкзак');
  await tester.pumpAndSettle();
  expect(model.visibleItems.single.id, 'i1');
  await tap(find.text('Профиль'));
  await tap(find.text('Доска'));
  expect(model.query, 'рюкзак');
  await capture('05_filter');
  await tap(find.text('Сбросить поиск и место'));

  await tap(find.byTooltip('Добавить объявление'));
  await tap(find.byKey(const Key('item-submit')));
  expect(find.text('Выберите: потерял или нашёл'), findsOneWidget);
  await tap(find.byKey(const Key('item-type')));
  await tap(find.text('Нашёл').last);
  await tester.enterText(
    find.byKey(const Key('item-title')),
    'Синий футляр для очков',
  );
  await tester.enterText(
    find.byKey(const Key('item-description')),
    'Оставлен рядом с выдачей книг.',
  );
  await tap(find.byKey(const Key('item-location')));
  await tap(find.text('Библиотека').last);
  await capture('06_filled_form');
  // Сбой записи: форма и содержимое полей должны остаться.
  store.simulateError = true;
  await tap(find.byKey(const Key('item-submit')));
  expect(model.items.length, 16);
  expect(find.text('Синий футляр для очков'), findsOneWidget);
  await capture('07_save_error');
  store.simulateError = false;
  await tap(find.byKey(const Key('item-submit')));
  expect(model.items.length, 17);
  expect(model.myItems.length, 9);
  await capture('08_board_after');
  final created = model.items.first;
  await tap(find.text('Профиль'));
  await capture('09_profile_after');
  expect(find.text('9 объявлений'), findsOneWidget);
  await tap(find.text('Мои'));
  await capture('10_activity_after');
  expect(find.text(created.title), findsOneWidget);
  await tap(find.text(created.title));
  await capture('11_detail_after');
  await tap(find.text('Редактировать'));
  await tester.enterText(
    find.byKey(const Key('item-title')),
    'Футляр с серебристой кнопкой',
  );
  await tap(find.byKey(const Key('item-submit')));
  expect(model.byId(created.id)!.title, 'Футляр с серебристой кнопкой');
  await tap(find.byKey(const Key('item-close')));
  await tap(find.text('Подтвердить'));
  expect(model.byId(created.id)!.statusLabel, 'Возвращено');
  await capture('12_closed');
  await tap(find.byKey(const Key('item-delete')));
  await tap(find.text('Отмена'));
  expect(model.byId(created.id), isNotNull);
  await tap(find.byKey(const Key('item-delete')));
  await tap(find.text('Подтвердить'));
  expect(model.byId(created.id), isNull);
  expect(model.myItems.length, 8);

  router.go('/items/i2/claim');
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('claim-evidence')),
    'Под брелоком маленькая наклейка с числом 42',
  );
  await tap(find.byKey(const Key('claim-submit')));
  expect(model.claims.length, 9);
  final claim = model.claims.first;
  await tester.enterText(
    find.byKey(const Key('message-text')),
    'Могу забрать у библиотеки после пары.',
  );
  await tap(find.byTooltip('Отправить'));
  expect(model.thread(claim.id).length, 1);
  await capture('13_message');
  router.go('/activity/claims/c1/messages');
  await tester.pumpAndSettle();
  expect(find.text('Могу забрать у библиотеки после пары.'), findsNothing);
  router.go('/activity/claims/${claim.id}/messages');
  await tester.pumpAndSettle();
  expect(find.text('Могу забрать у библиотеки после пары.'), findsOneWidget);
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}
