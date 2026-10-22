import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lost_found/main.dart';
import 'package:lost_found/router.dart';
import 'package:lost_found/models/lost_found_model.dart';
import 'package:lost_found/data/mock_repositories.dart';

import 'support/lab4_flow.dart';

void main() {
  testWidgets('L4: retry, формы, общие счётчики, CRUD и переписка', (
    tester,
  ) async {
    await exerciseLab4(tester, (_) async {});
  });
  testWidgets('Свайп: отмена, отказ хранилища и удаление только своей вещи', (
    tester,
  ) async {
    final store = MockStore(delay: Duration.zero);
    final router = createRouter(initialLocation: '/activity');
    addTearDown(router.dispose);
    await tester.pumpWidget(LostFoundRoot(store: store, routerConfig: router));
    await tester.pumpAndSettle();
    final model = Provider.of<LostFoundModel>(
      tester.element(find.byType(NavigationBar)),
      listen: false,
    );
    final card = find.byKey(const ValueKey('i9'));
    Future<void> swipe() async {
      await tester.drag(card, const Offset(-700, 0));
      await tester.pumpAndSettle();
    }

    await swipe();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(model.byId('i9'), isNotNull);
    store.simulateError = true;
    await swipe();
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();
    expect(model.byId('i9'), isNotNull);
    store.simulateError = false;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await swipe();
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();
    expect(model.byId('i9'), isNull);
    expect(model.myItems.length, 7);
    expect(tester.takeException(), isNull);
  });
}
