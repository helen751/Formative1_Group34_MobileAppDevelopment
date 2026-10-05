import 'package:flutter/material.dart';

import '../theme/devtrack_theme.dart';

/// Full-width dark button with mint label, used for primary sheet actions.
class DarkButton extends StatelessWidget {
  const DarkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;

  /// Optional leading icon, e.g. the plus on "Assign a task".
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DevTrackColors.ink,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: DevTrackColors.mint),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: DevTrackColors.mint,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
