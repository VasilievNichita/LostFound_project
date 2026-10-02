import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/router.dart';
import 'package:lost_found/validation.dart';
import 'package:lost_found/screens/login_screen.dart';

import 'support/lab3_flow.dart';

void main() {
  testWidgets('Полный сценарий L3, стеки вкладок и неизменность mock-данных', (
    tester,
  ) async {
    await exerciseLab3(tester, (_) async {});
  });

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
    await tester.pumpWidget(LostFoundApp(routerConfig: router));
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
      expect(find.text('Страница не найдена'), findsOneWidget);
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

  testWidgets('Регистрация проверяет подтверждение и не сохраняет аккаунт', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(LostFoundApp(routerConfig: router));
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
    await tester.ensureVisible(find.byKey(const Key('confirmation')));
    await tester.enterText(find.byKey(const Key('confirmation')), 'abcdef');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);
    expect(router.canPop(), isFalse);
  });
}
