import 'package:flutter/material.dart';

import '../theme/devtrack_theme.dart';

/// Rounded filter chip: dark with mint text when selected, white with a border otherwise.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? DevTrackColors.ink : DevTrackColors.surface,
            // Selected pills keep a border (same color as the fill) so both
            // states have the same size.
            border: Border.all(
              color: selected ? DevTrackColors.ink : DevTrackColors.border,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? DevTrackColors.mint : DevTrackColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
