import 'package:flutter/material.dart';

import '../models/devtrack_models.dart';
import '../theme/devtrack_theme.dart';
import 'status_badge.dart';

/// Task row with a colored status bar on the left and a status badge on the right.
///
/// [compact] is the smaller variant used inside the member profile sheet.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.subtitle,
    this.compact = false,
  });

  final Task task;

  /// Second line under the title, e.g. the due text, optionally with the assignee.
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = task.status.color;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: devTrackCard(radius: compact ? 16 : 20),
      child: Row(
        children: [
          Container(
            width: compact ? 4 : 5,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(compact ? 3 : 4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DevTrackColors.ink,
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: compact ? 3 : 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DevTrackColors.muted,
                    fontSize: compact ? 12 : 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge(label: task.status.label, color: color),
        ],
      ),
    );
  }
}
