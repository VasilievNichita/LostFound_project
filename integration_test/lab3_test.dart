import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/lab3_flow.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('L3 на Android: навигация, формы и подтверждение выхода', (
    tester,
  ) async {
    var converted = false;
    await exerciseLab3(tester, (name) async {
      if (!converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pumpAndSettle();
      }
      await binding.takeScreenshot(name);
    });
  });
}
