import 'package:flutter/material.dart';

import '../theme/devtrack_theme.dart';

/// How a task stands against its deadline; also decides its color everywhere.
enum SlaStatus {
  onTrack('On Track', DevTrackColors.onTrack),
  atRisk('At Risk', DevTrackColors.atRisk),
  overdue('Overdue', DevTrackColors.overdue),
  completed('Completed', DevTrackColors.completed);

  const SlaStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// A single project task. Mock data for now; the SQLite layer will replace it.
class Task {
  const Task({
    required this.title,
    required this.assignee,
    required this.dueLabel,
    required this.status,
    this.dueInHours,
  });

  final String title;

  /// Short name of the assigned member; matches [Member.shortName].
  final String assignee;

  /// Human readable due text, e.g. "Due in 20h" or "1 day overdue".
  final String dueLabel;
  final SlaStatus status;

  /// Hours until the task is due (negative when overdue). Null once completed.
  final int? dueInHours;
}

/// A team member shown on the Team page and in the profile sheet.
class Member {
  const Member({
    required this.name,
    required this.shortName,
    required this.initials,
    required this.role,
    required this.email,
  });

  final String name;

  /// Name used on task tiles, e.g. "Derrick".
  final String shortName;
  final String initials;
  final String role;
  final String email;

  /// The tasks in [tasks] that are assigned to this member.
  List<Task> tasksFrom(List<Task> tasks) =>
      tasks.where((t) => t.assignee == shortName).toList();
}

/// Counters used by the dashboard, team cards and profile sheet, so every number
/// on screen is derived from the task list instead of being hard-coded.
extension TaskListStats on List<Task> {
  /// Number of tasks with the given [status].
  int countOf(SlaStatus status) => where((t) => t.status == status).length;

  /// Number of completed tasks.
  int get doneCount => countOf(SlaStatus.completed);

  /// Completed share from 0 to 1 (0 for an empty list).
  double get progress => isEmpty ? 0 : doneCount / length;

  /// Tasks that are not completed yet.
  List<Task> get open =>
      where((t) => t.status != SlaStatus.completed).toList();

  /// Open tasks due within the next 24 hours.
  int get dueTodayCount => _countDueWithin(24, inclusive: true);

  /// Open tasks due within the next 7 days (not counting overdue ones).
  int get dueThisWeekCount => _countDueWithin(24 * 7, inclusive: false);

  // Overdue (negative) and completed (null) tasks never count as upcoming.
  int _countDueWithin(int hours, {required bool inclusive}) => where((t) {
        final due = t.dueInHours;
        if (due == null || due < 0) return false;
        return inclusive ? due <= hours : due < hours;
      }).length;
}

/// What a notification is about; decides its icon, color and filter bucket.
enum NotificationKind { overdue, atRisk, completed, assigned }

/// An entry in the notifications sheet. Immutable: use [markRead] for a read copy.
class AppNotification {
  const AppNotification({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.kind,
    this.unread = false,
  });

  final String title;
  final String subtitle;

  /// Relative time, e.g. "2h ago".
  final String timeLabel;
  final NotificationKind kind;

  /// Unread items get a highlighted row, a bold title and a green dot.
  final bool unread;

  /// A copy of this notification marked as read.
  AppNotification markRead() => AppNotification(
        title: title,
        subtitle: subtitle,
        timeLabel: timeLabel,
        kind: kind,
      );
}
