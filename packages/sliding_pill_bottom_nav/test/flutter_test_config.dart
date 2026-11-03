import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Inter')
    ..addFont(rootBundle.load('test/assets/inter/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('test/assets/inter/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('test/assets/inter/Inter-SemiBold.ttf'));
  await loader.load();
  await testMain();
}
