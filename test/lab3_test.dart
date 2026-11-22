import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mock_root.dart';
import 'support/mock_repositories.dart';

import 'package:lost_found/router.dart';
import 'package:lost_found/validation.dart';

void main() {
  test('Пробелы, границы длины и корректный email', () {
    expect(validateTitle('   '), isNotNull);
    expect(validateTitle('Ключи'), isNull);
    expect(validateTitle('а' * 80), isNull);
    expect(validateTitle('а' * 81), isNotNull);
    expect(validateEvidence('а' * 9), isNotNull);
    expect(validateEvidence('а' * 10), isNull);
    expect(validateEvidence('а' * 600), isNull);
    expect(validateEvidence('а' * 601), isNotNull);
    expect(validateMessage(' \n '), isNotNull);
    expect(validateMessage('а' * 1000), isNull);
    expect(validateMessage('а' * 1001), isNotNull);
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('a@@b.ru'), isNotNull);
    expect(validateEmail('a b@c.ru'), isNotNull);
    expect(validateEmail('name@campus.md'), isNull);
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
  });

  testWidgets('Прямые адреса, new перед id и отдельные переписки', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/items/new');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      LostFoundRoot(
        routerConfig: router,
        store: MockStore(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Новое объявление'), findsOneWidget);
    for (final path in [
      '/items/no-such-item',
      '/items/no-such-item/claim',
      '/items/no-such-item/edit',
      '/activity/claims/no-such-claim/messages',
      '/missing',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        find.text(
          path == '/items/no-such-item'
              ? 'Объявление не найдено.'
              : 'Страница не найдена',
        ),
        findsOneWidget,
      );
    }
    router.go('/activity/claims/c1/messages');
    await tester.pumpAndSettle();
    expect(find.text('Здравствуйте! Кажется, это мой рюкзак.'), findsOneWidget);
    router.go('/activity/claims/c2/messages');
    await tester.pumpAndSettle();
    expect(find.text('Здравствуйте! Кажется, это мой рюкзак.'), findsNothing);
    expect(find.text('Беспроводные наушники в белом футляре'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Регистрация не отправляет форму с разными паролями', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      LostFoundRoot(
        routerConfig: router,
        store: MockStore(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    for (final entry in {
      'name': 'Никита',
      'email': 'one@example.org',
      'password': 'abcdef',
      'confirmation': 'different',
    }.entries) {
      await tester.ensureVisible(find.byKey(Key(entry.key)));
      await tester.enterText(find.byKey(Key(entry.key)), entry.value);
    }
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Пароли не совпадают'), findsOneWidget);
  });
}
