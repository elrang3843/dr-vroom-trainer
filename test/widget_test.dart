import 'package:flutter_test/flutter_test.dart';
import 'package:dr_vroom_trainer/main.dart';

void main() {
  testWidgets('Dr. Vroom Trainer app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DrVroomTrainerApp());
    expect(find.byType(DrVroomTrainerApp), findsOneWidget);
  });
}
