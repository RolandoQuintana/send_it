import 'package:flutter/cupertino.dart';

import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';
import '../widgets/ui/buttons.dart';

/// Shows [WelcomeScreen] once, on a new user's first launch, then [child].
/// Returning users (see [OnboardingService.initialize]) and Pro users go
/// straight to [child].
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({
    super.key,
    required this.child,
    this.onboarding,
    this.hasPro,
  });

  final Widget child;

  /// Defaults to [OnboardingService.instance].
  final OnboardingService? onboarding;

  /// Defaults to [SubscriptionService.hasPro].
  final bool Function()? hasPro;

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  late final OnboardingService _onboarding =
      widget.onboarding ?? OnboardingService.instance;

  @override
  void initState() {
    super.initState();
    _onboarding.addListener(_onChanged);
  }

  @override
  void dispose() {
    _onboarding.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasPro =>
      widget.hasPro?.call() ?? SubscriptionService.instance.hasPro;

  @override
  Widget build(BuildContext context) {
    if (_onboarding.hasSeenWelcome || _hasPro) return widget.child;
    return WelcomeScreen(onGetStarted: _onboarding.markWelcomeSeen);
  }
}

/// One screen, one point: everyone gets their own text.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.onboardingWelcomeViewed();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _FanOutIllustration(),
                      const SizedBox(height: 36),
                      Text(
                        'One message.\nEveryone gets their own text.',
                        textAlign: TextAlign.center,
                        style: AppText.title1.copyWith(color: surfaces.ink),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Write it once and Sent It texts each person '
                        'separately, with their name in it. Nobody sees '
                        "anyone else's replies.",
                        textAlign: TextAlign.center,
                        style: AppText.callout.copyWith(color: surfaces.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: PrimaryButton(
                label: 'Get Started',
                expand: true,
                onPressed: widget.onGetStarted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One bubble fanning out to three personal ones.
class _FanOutIllustration extends StatelessWidget {
  const _FanOutIllustration();

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

    Widget bubble(String text, {required bool outgoing}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: outgoing ? surfaces.accentFill : surfaces.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: outgoing ? null : surfaces.floating,
          ),
          child: Text(
            text,
            style: AppText.subhead.copyWith(
              color: outgoing ? surfaces.onAccent : surfaces.ink,
              fontWeight: outgoing ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );

    return ExcludeSemantics(
      child: Column(
        children: [
          bubble('Hey {firstname}!', outgoing: true),
          const SizedBox(height: 10),
          Icon(CupertinoIcons.arrow_down, color: surfaces.faint, size: 20),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              bubble('Hey Sam!', outgoing: false),
              bubble('Hey Priya!', outgoing: false),
              bubble('Hey Leo!', outgoing: false),
            ],
          ),
        ],
      ),
    );
  }
}
