import '../models/devtrack_models.dart';

// Placeholder values for things the database does not hold yet.
// Tasks and team members now come from SQLite (see lib/database).

/// Signed-in user; decides what the dashboard's "My tasks" scope shows.
/// Replace with the logged-in user once auth is plugged in.
const currentUserFirstName = 'Derrick';

/// Project name shown on the dashboard progress card.
const projectName = 'DevTrack';

/// Notifications for the bell popup; the first three start out unread.
const mockNotifications = <AppNotification>[
  AppNotification(
    title: 'Design login screen is overdue',
    subtitle: 'Was due yesterday · Emmanuel',
    timeLabel: '2h ago',
    kind: NotificationKind.overdue,
    unread: true,
  ),
  AppNotification(
    title: 'Set up SQLite tables is at risk',
    subtitle: 'Due in 20h · Helen',
    timeLabel: '5h ago',
    kind: NotificationKind.atRisk,
    unread: true,
  ),
  AppNotification(
    title: 'Build create/edit task form is at risk',
    subtitle: 'Due in 2 days · Christian',
    timeLabel: 'Yesterday',
    kind: NotificationKind.atRisk,
    unread: true,
  ),
  AppNotification(
    title: 'Register form validation completed',
    subtitle: 'Finished by Emmanuel',
    timeLabel: '2 days ago',
    kind: NotificationKind.completed,
  ),
  AppNotification(
    title: 'Dashboard UI assigned to you',
    subtitle: 'Assigned by Christian',
    timeLabel: '2 days ago',
    kind: NotificationKind.assigned,
  ),
];
