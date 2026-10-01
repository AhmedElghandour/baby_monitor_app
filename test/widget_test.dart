import 'package:flutter_test/flutter_test.dart';
import 'package:camera_peer_mobile_app/main.dart';

void main() {
  testWidgets('Baby monitor app initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const BabyMonitorApp());
    expect(find.byType(BabyMonitorApp), findsOneWidget);
  });
}
