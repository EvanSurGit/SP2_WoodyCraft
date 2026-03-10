import 'package:flutter_test/flutter_test.dart';
import 'package:crudapi/main.dart';

void main() {
  testWidgets('Vérification du titre de l\'application', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Gestion du catalogue'), findsOneWidget);
  });
}
