import '../models/devtrack_models.dart';

// Placeholder data for the screens.
// Replace with the SQLite-backed repository once the database layer is ready.

/// Signed-in user; decides what the dashboard's "My tasks" scope shows.
/// Replace with the logged-in user once auth is plugged in.
const currentUserFirstName = 'Derrick';

/// Project name shown on the dashboard progress card.
const projectName = 'DevTrack';

/// The four team members shown on the Team page.
const mockMembers = <Member>[
  Member(
    name: 'Emmanuel',
    shortName: 'Emmanuel',
    initials: 'E',
    role: 'Auth Developer',
    email: 'emmanuel@devtrack.app',
  ),
  Member(
    name: 'Derrick Nshuti',
    shortName: 'Derrick',
    initials: 'DN',
    role: 'Project Lead',
    email: 'derrick@devtrack.app',
  ),
  Member(
    name: 'Christian',
    shortName: 'Christian',
    initials: 'C',
    role: 'Task Module Developer',
    email: 'christian@devtrack.app',
  ),
  Member(
    name: 'Helen',
    shortName: 'Helen',
    initials: 'H',
    role: 'Database & Stats',
    email: 'helen@devtrack.app',
  ),
];

/// The seven project tasks. Every count on screen (the 14% ring, SLA
/// cards, member progress) is derived from this list.
///
/// [Task.dueInHours] is negative when overdue (-24 = a day late), null for
/// completed tasks, and 168 for "due in 7 days".
const mockTasks = <Task>[
  Task(
    title: 'Design login screen',
    assignee: 'Emmanuel',
    dueLabel: '1 day overdue',
    status: SlaStatus.overdue,
    dueInHours: -24,
  ),
  Task(
    title: 'Register form validation',
    assignee: 'Emmanuel',
    dueLabel: 'Completed',
    status: SlaStatus.completed,
  ),
  Task(
    title: 'Dashboard UI',
    assignee: 'Derrick',
    dueLabel: 'Due in 3 days',
    status: SlaStatus.onTrack,
    dueInHours: 72,
  ),
  Task(
    title: 'Team members page',
    assignee: 'Derrick',
    dueLabel: 'Due in 7 days',
    status: SlaStatus.onTrack,
    dueInHours: 168,
  ),
  Task(
    title: 'Set up SQLite tables',
    assignee: 'Helen',
    dueLabel: 'Due in 20h',
    status: SlaStatus.atRisk,
    dueInHours: 20,
  ),
  Task(
    title: 'Build create/edit task form',
    assignee: 'Christian',
    dueLabel: 'Due in 2 days',
    status: SlaStatus.atRisk,
    dueInHours: 48,
  ),
  Task(
    title: 'Task details layout',
    assignee: 'Helen',
    dueLabel: 'Due in 6 days',
    status: SlaStatus.onTrack,
    dueInHours: 144,
  ),
];

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
