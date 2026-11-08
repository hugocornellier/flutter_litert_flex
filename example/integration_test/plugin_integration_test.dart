import 'package:flutter_litert/flutter_litert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flutter_litert_flex bundles a FlexDelegate that loads', (
    WidgetTester tester,
  ) async {
    // If the app builds and the delegate loads, the native library bundling
    // worked. Running SELECT_TF_OPS models is tested via flutter_litert's
    // integration tests.
    expect(FlexDelegate.isAvailable, isTrue);
    final flex = await FlexDelegate.create();
    flex.delete();
  });
}
