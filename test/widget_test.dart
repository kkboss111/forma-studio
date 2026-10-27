import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma_studio/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Forma Studio app loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: FormaApp()));

    // Pump frames to let async initState complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify brand title is shown
    expect(find.text('FORMA STUDIO'), findsAtLeastNWidgets(1));
  });
}
