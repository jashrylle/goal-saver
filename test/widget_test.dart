import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:goal_saver/app.dart';

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('goal_saver_test');
    Hive.init(tempDir.path);
  });

  testWidgets('Goal Saver App can be instantiated', (tester) async {
    // Verify the app widget can be created without errors
    await tester.pumpWidget(const GoalSaverApp());
    await tester.pump();
    // No crashes = test passes
    expect(true, isTrue);
  });
}
