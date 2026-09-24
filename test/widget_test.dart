import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found/main.dart';

void main() {
  testWidgets('Доска помещается на небольшом экране и прокручивается', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LostFoundApp());

    expect(find.text('LostFound'), findsOneWidget);
    expect(find.text('Ключи с синим брелоком'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Бутылка для воды'), 100);
    expect(find.text('Бутылка для воды').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
