import 'package:flutter_test/flutter_test.dart';

import 'package:send_it/main.dart';
import 'package:send_it/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await SubscriptionService.instance.initialize();
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SendItApp());
    await tester.pump();
    await tester.pump(Duration.zero);

    expect(find.byType(SendItApp), findsOneWidget);
  });
}
