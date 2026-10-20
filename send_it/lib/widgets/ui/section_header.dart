import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';
import '../../theme/app_text.dart';

/// Uppercase label above a grouped section, with an optional trailing
/// widget (a count, a text button).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppText.sectionHeader.copyWith(color: surfaces.muted),
            ),
          ),
          if (trailing != null)
            DefaultTextStyle.merge(
              style: AppText.footnote.copyWith(color: surfaces.muted),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
