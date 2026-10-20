import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/screens/welcome_screen.dart';
import 'package:send_it/services/onboarding_service.dart';
import 'package:send_it/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<OnboardingService> freshService() async {
    final service = OnboardingService.forTesting();
    await service.initialize();
    return service;
  }

  Widget app(OnboardingService service, {bool hasPro = false}) => CupertinoApp(
        theme: AppTheme.cupertino(brightness: Brightness.dark),
        home: WelcomeGate(
          onboarding: service,
          hasPro: () => hasPro,
          child: const Text('Home'),
        ),
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows once, then goes straight to Home', (tester) async {
    final service = await freshService();
    await tester.pumpWidget(app(service));
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    // Next launch.
    final relaunched = await freshService();
    await tester.pumpWidget(app(relaunched));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
  });

  testWidgets('Pro users never see it', (tester) async {
    final service = await freshService();
    await tester.pumpWidget(app(service, hasPro: true));
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('fits at the largest Dynamic Type size', (tester) async {
    final service = await freshService();
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(375, 667),
        textScaler: TextScaler.linear(3),
      ),
      child: app(service),
    ));
    expect(tester.takeException(), isNull);
  });
}
