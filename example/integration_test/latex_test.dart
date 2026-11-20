import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Runs on an Android or iOS device, where flutter_tex_js renders with KaTeX
/// in a web view and TexImage shows the result as an Image.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TexImage renders the inline formula and the block', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final rendered = find.descendant(
      of: find.byType(TexImage),
      matching: find.byType(Image),
    );
    for (var i = 0; i < 60 && rendered.evaluate().length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(TexImage), findsNWidgets(2));
    expect(rendered, findsNWidgets(2));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('latex');
  });
}
