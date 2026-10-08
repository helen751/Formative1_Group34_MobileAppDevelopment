import 'project_task.dart';

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

  // converting a row from the users table into a member
  factory Member.fromMap(Map<String, Object?> map) {
    final name = (map['full_name'] as String).trim();
    final words = name.split(RegExp(r'\s+')).where((word) {
      return word.isNotEmpty;
    }).toList();

    // the first name matches the assignee saved on each task
    final shortName = words.isEmpty ? name : words.first;

    // the first letter of the first two names, e.g. "DN" for "Derrick Nshuti"
    final initials = words.take(2).map((word) {
      return word[0].toUpperCase();
    }).join();

    return Member(
      name: name,
      shortName: shortName,
      initials: initials.isEmpty ? '?' : initials,
      role: map['role'] as String,
      email: map['email'] as String,
    );
  }

  /// The tasks in [tasks] that are assigned to this member.
  List<ProjectTask> tasksFrom(List<ProjectTask> tasks) =>
      tasks.where((t) => t.assignee == shortName).toList();
}

/// Counters used by the dashboard, team cards and profile sheet, so every number
/// on screen is derived from the task list instead of being hard-coded.
extension TaskListStats on List<ProjectTask> {
  /// Number of tasks with the given [status].
  int countOf(SlaStatus status) => where((t) => t.status == status).length;

  /// Number of completed tasks.
  int get doneCount => countOf(SlaStatus.completed);

  /// Completed share from 0 to 1 (0 for an empty list).
  double get progress => isEmpty ? 0 : doneCount / length;

  /// Tasks that are not completed yet.
  List<ProjectTask> get open =>
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

// creating one notification
class AppNotification {
  const AppNotification({
    this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.kind,
    this.unread = false,
  });

  final int? id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final NotificationKind kind;
  final bool unread;

  // converting database data into a notification
  factory AppNotification.fromMap(
      Map<String, Object?> map,
      ) {
    return AppNotification(
      id: map['id'] as int,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      timeLabel: map['time_label'] as String,
      kind: NotificationKind.values.byName(
        map['kind'] as String,
      ),
      unread: map['unread'] == 1,
    );
  }

  // creating a copy marked as read
  AppNotification markRead() {
    return AppNotification(
      id: id,
      title: title,
      subtitle: subtitle,
      timeLabel: timeLabel,
      kind: kind,
      unread: false,
    );
  }
}
