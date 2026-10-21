import 'package:flutter/cupertino.dart';

import '../main.dart';
import '../services/haptics.dart';
import 'settings_screen.dart';

/// Bottom tabs: Groups and Settings. Detail screens (a group, the group
/// form) push on the root navigator so they cover the tab bar.
///
/// Tabs swap instantly, as in most of iOS; a selection haptic and a small
/// bounce on the new icon carry the feedback.
class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  final _controller = CupertinoTabController();
  int _switches = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _controller,
      tabBar: CupertinoTabBar(
        onTap: (index) {
          if (index == _controller.index) return;
          Haptics.selection();
          setState(() => _switches++);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person_3),
            activeIcon: _BounceIcon(
              CupertinoIcons.person_3_fill,
              play: _switches > 0,
            ),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.gear),
            activeIcon: _BounceIcon(
              CupertinoIcons.gear_solid,
              play: _switches > 0,
            ),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(
        builder: (_) => switch (index) {
          0 => const HomePage(),
          _ => const SettingsScreen(),
        },
      ),
    );
  }
}

/// The selected tab's icon: pops once when a tab is picked (not at launch).
class _BounceIcon extends StatefulWidget {
  const _BounceIcon(this.icon, {required this.play});

  final IconData icon;
  final bool play;

  @override
  State<_BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<_BounceIcon>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  // Up and settle; no dip first.
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.12, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isDismissed) return;
    if (widget.play && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: Icon(widget.icon));
  }
}
