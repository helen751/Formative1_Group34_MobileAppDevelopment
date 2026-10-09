import 'package:flutter/material.dart';

import '../models/devtrack_models.dart';
import '../models/project_task.dart';
import '../theme/devtrack_theme.dart';
import 'dark_button.dart';
import 'task_tile.dart';

/// Opens [member]'s profile as a bottom sheet over the current page.
///
/// [tasks] are the tasks already filtered down to that member.
Future<void> showMemberProfileSheet(
  BuildContext context, {
  required Member member,
  required List<ProjectTask> tasks,
  ValueChanged<String>? onAssignTask,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DevTrackColors.surface,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => MemberProfileSheet(
      member: member,
      tasks: tasks,
      onAssignTask: onAssignTask,
    ),
  );
}

/// Sheet content: identity, task counters, email and the member's assigned tasks.
class MemberProfileSheet extends StatelessWidget {
  const MemberProfileSheet({
    super.key,
    required this.member,
    required this.tasks,
    this.onAssignTask,
  });

  final Member member;

  // opening the create task page with this member picked
  final ValueChanged<String>? onAssignTask;

  /// Tasks assigned to [member].
  final List<ProjectTask> tasks;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // Cap the height so the content scrolls instead of overflowing on short
        // screens or when a member has many tasks.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DevTrackColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Identity(member: member),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatTile(
                    value: tasks.length,
                    label: 'Tasks',
                    color: DevTrackColors.ink,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    value: tasks.doneCount,
                    label: 'Done',
                    color: DevTrackColors.onTrack,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    value: tasks.countOf(SlaStatus.overdue),
                    label: 'Overdue',
                    color: DevTrackColors.overdue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: devTrackCard(radius: 14),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline,
                        size: 18, color: DevTrackColors.muted),
                    const SizedBox(width: 10),
                    Text(
                      member.email,
                      style: const TextStyle(
                        color: DevTrackColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assigned tasks',
                style: TextStyle(
                  color: DevTrackColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final task in tasks) ...[
                const SizedBox(height: 16),
                TaskTile(task: task, subtitle: task.dueLabel, compact: true),
              ],
              const SizedBox(height: 16),
              DarkButton(
                icon: Icons.add,
                label: 'Assign a task',
                // closing the sheet first, then opening the form
                onPressed: () {
                  Navigator.of(context).pop();
                  onAssignTask?.call(member.shortName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar, name and role, centered at the top of the sheet.
class _Identity extends StatelessWidget {
  const _Identity({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: DevTrackColors.mint,
            shape: BoxShape.circle,
          ),
          child: Text(
            member.initials,
            style: const TextStyle(
              color: DevTrackColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          member.name,
          style: const TextStyle(
            color: DevTrackColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          member.role,
          style: const TextStyle(color: DevTrackColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

/// One of the Tasks / Done / Overdue counters; the three share the row evenly.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: DevTrackColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: DevTrackColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
