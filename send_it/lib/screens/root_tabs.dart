import 'package:flutter/cupertino.dart';

import '../main.dart';
import '../services/haptics.dart';
import '../theme/app_surfaces.dart';
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

  // CupertinoTabScaffold updates the controller before chaining onTap, so
  // the controller can't tell us whether the tab changed.
  int _index = 0;

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
        // Flutter pins labels to the bar's bottom edge and centers the icon
        // in what's left, so a taller bar only spreads them apart. Items
        // carry their own label instead (see _TabItem) and sit centered.
        height: 60,
        // The default hairline is translucent black, which vanishes in dark
        // mode. Keep it in light; use the app's divider color in dark.
        border: Border(
          top: BorderSide(
            color: CupertinoTheme.brightnessOf(context) == Brightness.dark
                ? context.surfaces.hairline
                : const Color(0x4D000000),
            width: 0,
          ),
        ),
        onTap: (index) {
          if (index == _index) return;
          _index = index;
          Haptics.selection();
          setState(() => _switches++);
        },
        items: [
          BottomNavigationBarItem(
            icon: const _TabItem(
              icon: Icon(CupertinoIcons.person_3),
              label: 'Groups',
            ),
            activeIcon: _TabItem(
              icon: _BounceIcon(
                CupertinoIcons.person_3_fill,
                play: _switches > 0,
              ),
              label: 'Groups',
            ),
          ),
          BottomNavigationBarItem(
            icon: const _TabItem(
              icon: Icon(CupertinoIcons.gear),
              label: 'Settings',
            ),
            activeIcon: _TabItem(
              icon: _BounceIcon(
                CupertinoIcons.gear_solid,
                play: _switches > 0,
              ),
              label: 'Settings',
            ),
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

/// Icon over label as one block, so the bar centers both with even space
/// above and below. Colors and text style come from the tab bar.
class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Offsets the tab bar's own 4pt bottom inset so the block sits centered.
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 2),
          Text(label),
        ],
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
