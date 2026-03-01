import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app builds and runs with flutter_litert_flex', (
    WidgetTester tester,
  ) async {
    // If the app builds and runs, the native library bundling worked.
    // The actual FlexDelegate functionality is tested via flutter_litert's
    // integration tests.
    expect(true, isTrue);
  });
}
