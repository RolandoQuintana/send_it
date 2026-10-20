import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';

/// Inset card that stacks [children] with hairlines between them, like an
/// iOS grouped table section.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    required this.children,
    this.dividerIndent = 16,
  });

  final List<Widget> children;

  /// Left inset of the hairlines (e.g. past a leading avatar).
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: surfaces.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) InsetDivider(indent: dividerIndent),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Hairline between rows of a grouped section.
class InsetDivider extends StatelessWidget {
  const InsetDivider({super.key, this.indent = 16});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(height: 0.5, color: context.surfaces.hairline),
    );
  }
}
