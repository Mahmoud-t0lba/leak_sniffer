import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leak_sniffer_example/main.dart';

void main() {
  testWidgets('shows the stream leak demo', (tester) async {
    await tester.pumpWidget(const LeakSnifferExampleApp());

    expect(find.text('leak_sniffer stream demo'), findsOneWidget);
    expect(
      find.text(
        'A StreamController receives events when you tap the button, but dispose() intentionally forgets to close it so avoid_unclosed_stream_controller stays visible.',
      ),
      findsOneWidget,
    );
    expect(find.text('Active lint demo'), findsOneWidget);
    expect(find.text('What this demo is doing'), findsOneWidget);
    expect(find.text('Why the warning appears'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Expected fix'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Expected fix'), findsOneWidget);
  });
}
