import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/lab4_flow.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('L4 на Android', (tester) async {
    var converted = false;
    await exerciseLab4(tester, (name) async {
      if (!converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pump();
      }
      await binding.takeScreenshot(name);
    }, delay: const Duration(milliseconds: 1500));
  });
}
