import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:goal_saver/app.dart';

void main() {
  testWidgets('Goal Saver renders onboarding and dashboard', (tester) async {
    await tester.pumpWidget(const GoalSaverApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Save for the\nProducts You Want'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.pumpWidget(
      const GoalSaverApp(key: ValueKey('dashboard-app'), showOnboarding: false),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Total Saved'), findsOneWidget);
    expect(find.text("Products I'm Saving For"), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -800),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('School Expenses'), findsOneWidget);
  });
}
