import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_material_button.dart';

class _ClerkDynamicBackground extends Color {
  const _ClerkDynamicBackground() : super(0x00000000);

  @override
  int get value {
    final stack = StackTrace.current.toString();
    print('TEST_STACK:\n$stack');
    return 0xFFFFFFFF;
  }
}

void main() {
  testWidgets('Test button stack trace', (tester) async {
    final colors = ClerkThemeColors(
      background: const _ClerkDynamicBackground(),
      altBackground: Colors.white,
      borderSide: Colors.grey,
      text: Colors.black,
      icon: Colors.black,
      lightweightText: Colors.grey,
      error: Colors.red,
      accent: Colors.purple,
    );
    final theme = ClerkThemeExtension(colors: colors);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [theme],
        ),
        home: Scaffold(
          body: ClerkMaterialButton(
            label: const Text('Continue'),
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
