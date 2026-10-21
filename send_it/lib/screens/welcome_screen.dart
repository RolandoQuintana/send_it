import 'package:flutter/cupertino.dart';

import '../services/analytics_service.dart';
import '../services/haptics.dart';
import '../services/onboarding_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';
import '../widgets/ui/avatar.dart';
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

/// One screen: personal texts to everyone, written once (and no group
/// chat).
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
            // One group, sitting a little above center so the spare room
            // falls over the button. Scrolls at large Dynamic Type sizes.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Align(
                      alignment: const Alignment(0, -0.4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _FanOutIllustration(),
                            const SizedBox(height: 40),
                            Text(
                              'Personal texts to everyone.\nWritten once.',
                              textAlign: TextAlign.center,
                              style:
                                  AppText.title1.copyWith(color: surfaces.ink),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No group chat, no copy-paste. Everyone gets '
                              'their own text with their name in it, and '
                              'replies come back to you one by one.',
                              textAlign: TextAlign.center,
                              style: AppText.callout
                                  .copyWith(color: surfaces.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// What you write once, fanning out into three separate threads. On first
/// show the threads drop in one by one (skipped with Reduce Motion).
class _FanOutIllustration extends StatefulWidget {
  const _FanOutIllustration();

  @override
  State<_FanOutIllustration> createState() => _FanOutIllustrationState();
}

class _FanOutIllustrationState extends State<_FanOutIllustration>
    with SingleTickerProviderStateMixin {
  static const _message = 'Dinner Friday?';
  static const _names = ['Sam', 'Priya', 'Leo'];

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isDismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward().then((_) {
        if (mounted) Haptics.primary();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fades and slides [child] in over [begin]–[end] of the timeline.
  Widget _reveal({
    required double begin,
    required double end,
    required Widget child,
    Offset from = const Offset(0, -0.25),
    double scaleFrom = 1,
  }) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween(begin: from, end: Offset.zero).animate(curve),
        child: ScaleTransition(
          scale: Tween(begin: scaleFrom, end: 1.0).animate(curve),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final bodyStyle = AppText.subhead.copyWith(color: surfaces.ink);

    // The name as the composer draws it: a chip, not a raw token.
    final nameChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: surfaces.accentSoft,
        shape: const StadiumBorder(),
      ),
      child: Text(
        'first name',
        style: AppText.footnote.copyWith(
          color: surfaces.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    Widget thread(int i, String name) {
      final start = 0.35 + i * 0.17;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            InitialAvatar(name, size: 32),
            const SizedBox(width: 8),
            // Centered on the card: the trailing gap mirrors the avatar.
            Expanded(
              child: Align(
                child: _reveal(
                  begin: start,
                  end: start + 0.3,
                  from: const Offset(0, -0.6),
                  scaleFrom: 0.85,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: surfaces.accentFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Hey $name! $_message',
                      style: AppText.subhead.copyWith(color: surfaces.onAccent),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8 + 32),
          ],
        ),
      );
    }

    return ExcludeSemantics(
      child: Column(
        children: [
          Text(
            'You write',
            style: AppText.footnote.copyWith(color: surfaces.muted),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surfaces.fill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  const TextSpan(text: 'Hey '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: nameChip,
                  ),
                  const TextSpan(text: '! $_message'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _reveal(
            begin: 0.1,
            end: 0.35,
            child: Icon(
              CupertinoIcons.arrow_down,
              color: surfaces.faint,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: surfaces.cardDecoration(),
            child: Column(
              children: [
                for (final (i, name) in _names.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Container(height: 0.5, color: surfaces.hairline),
                    ),
                  thread(i, name),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
