import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flutter_litert_flex bundles a FlexDelegate that loads', (
    WidgetTester tester,
  ) async {
    // If the app builds and the delegate loads, the native library bundling
    // worked.
    expect(FlexDelegate.isAvailable, isTrue);
    final flex = await FlexDelegate.create();
    flex.delete();
  });

  testWidgets('FlexDelegate runs a real Flex kernel (MatrixInverse)', (
    WidgetTester tester,
  ) async {
    // TFLite has no builtin matrix inverse, so this model holds the custom op
    // FlexMatrixInverse, which only the TensorFlow kernels in the Flex
    // delegate can run. See scripts/generate_flex_test_model.py.
    final data = await rootBundle.load('assets/flex_matrix_inverse.tflite');
    final tmpDir = await Directory.systemTemp.createTemp('litert_flex_test_');
    final modelFile = File('${tmpDir.path}/flex_matrix_inverse.tflite');
    await modelFile.writeAsBytes(data.buffer.asUint8List());

    // ignore: avoid_print
    print('TensorFlow Lite runtime version: $version');

    final flex = await FlexDelegate.create();
    final options = InterpreterOptions()..addDelegate(flex);
    final interpreter = Interpreter.fromFile(modelFile, options: options);

    final input = [
      [4.0, 7.0],
      [2.0, 6.0],
    ];
    final output = List.generate(2, (_) => List.filled(2, 0.0));
    interpreter.run(input, output);

    // inverse([[4, 7], [2, 6]]) = [[0.6, -0.7], [-0.2, 0.4]]
    const expected = [
      [0.6, -0.7],
      [-0.2, 0.4],
    ];
    for (var i = 0; i < 2; i++) {
      for (var j = 0; j < 2; j++) {
        expect(output[i][j], closeTo(expected[i][j], 1e-5));
      }
    }

    interpreter.close();
    options.delete();
    flex.delete();
    await tmpDir.delete(recursive: true);
  });
}
