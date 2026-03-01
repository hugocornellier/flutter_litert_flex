import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_litert_flex example')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This plugin bundles the TensorFlow Lite Flex delegate '
              'native library. No Dart API is needed — just add '
              'flutter_litert_flex to your pubspec.yaml and use '
              'FlexDelegate() from flutter_litert.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
