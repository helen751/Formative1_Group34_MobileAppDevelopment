# DevTrack

DevTrack is a Flutter project and SLA task tracker that helps a development team create tasks, assign responsibilities, monitor deadlines, and follow the progress of a project.

## Features

- User signup and login
- SQLite local database
- Project dashboard
- Create and edit tasks
- Assign tasks to team members
- Task list and task details
- Task priority and progress stages
- SLA status tracking
- Overdue and at-risk task notifications
- Team members page
- Project statistics and progress graphs

## Technologies Used

- Flutter
- Dart
- SQLite
- `sqflite`
- `path`
- Material Design widgets

## Project Structure

```text
lib/
├── database/
│   ├── database_helper.dart
│   └── database_seeder.dart
├── models/
│   ├── devtrack_models.dart
│   └── project_task.dart
├── screens/
│   ├── create_task_page.dart
│   ├── dashboard.dart
│   ├── home_shell.dart
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── statistics_page.dart
│   ├── task_details_page.dart
│   ├── task_list_page.dart
│   └── team_members_page.dart
├── services/
│   └── task_notification_service.dart
├── theme/
│   └── devtrack_theme.dart
├── widgets/
├── app_colors.dart
└── main.dart
```

## Getting Started

### Requirements

Make sure the following are installed:

- Flutter SDK
- Android Studio
- Android Emulator or a physical Android device
- Git

Check the Flutter installation with:

```bash
flutter doctor
```

### Clone the Project

```bash
git clone https://github.com/helen751/Formative1_Group34_MobileAppDevelopment
```

Open the project folder:

```bash
cd Formative1_Group34_MobileAppDevelopment
```

### Install Dependencies

Run:

```bash
flutter pub get
```

The project uses these SQLite packages:

```yaml
dependencies:
  sqflite:
  path:
```

The packages are already included in `pubspec.yaml`, so they do not need to be installed separately.

### Run the Application

Start an emulator or connect an Android device, then run:

```bash
flutter run
```

The first Android build may take a few minutes.

## Database Setup

DevTrack uses SQLite for local storage.

The SQLite database is created automatically when the application starts. There is no separate database file to download.

The database contains the following tables:

- `users`
- `tasks`
- `notifications`

The database stores:

- Registered user details
- Task information
- Task assignments
- Due dates
- Task priority and progress stage
- Notification information
- Read and unread notification status

`database_seeder.dart` adds default users, tasks, and notifications when the database tables are empty.

Each emulator or physical device has its own local database. Uninstalling the application may remove the saved database from that device.

## Default Login

A new user can create an account from the signup page. A default account can also be used to test the application.

### Recommended Test Account

```text
Email: derrick@devtrack.app
Password: Derrick@2026
```

### Other Default Accounts

| Name | Email | Password | Role |
|---|---|---|---|
| Emmanuel | `emmanuel@devtrack.app` | `Emmanuel@2026` | Auth Developer |
| Derrick Nshuti | `derrick@devtrack.app` | `Derrick@2026` | Project Lead |
| Christian | `christian@devtrack.app` | `Christian@2026` | Task Module Developer |
| Helen | `helen@devtrack.app` | `Helen@2026` | Database & Stats |

These accounts are included for classroom testing and demonstration.

## How the Application Works

1. The user signs up or signs in.
2. Successful login opens the main application.
3. The dashboard displays project and SLA progress.
4. The Tasks tab displays tasks stored in SQLite.
5. A task can be opened to view its complete details.
6. Tasks can be created, edited, completed, reopened, or deleted.
7. The notification bell shows assigned, completed, at-risk, and overdue task updates.
8. The Team tab displays team members and their assigned tasks.
9. The Statistics tab displays project progress, SLA distribution, task stages, priorities, and team progress.


## Tasks

Tasks are stored in SQLite.

Each task can contain:

- Title
- Description
- Assignee
- Due date
- Priority
- Progress stage
- Completed status

A task can have one of these stages:

- To Do
- In Progress
- Done

Tasks are automatically given an SLA status based on their due date and completion status.

## Task Details

The Task Details page displays the full information for a selected task.

From this page, the user can:

- View the task title
- View the task description
- View the assigned team member
- View the due date
- View the SLA status
- Mark the task as completed
- Reopen a completed task
- Open the edit form
- Delete the task

## Notifications

DevTrack uses in-app notifications stored in SQLite.

A notification can be created when:

- A task is assigned
- A task is completed
- A task becomes at risk
- A task becomes overdue

The notification bell displays a red indicator when unread notifications are available.

Users can:

- Open the notification list
- Mark one notification as read
- Mark all notifications as read
- Delete a notification

The application checks task deadlines when the dashboard opens or refreshes.
Notifications are stored in SQLite. Users can mark one notification or all notifications as read.

## Team Members

The Team page displays the development team and their roles.

The default team includes:

- Emmanuel — Auth Developer
- Derrick Nshuti — Project Lead
- Christian — Task Module Developer
- Helen — Database & Stats

The page also displays tasks assigned to each team member.

## Statistics

The Statistics page reads task information from SQLite and displays:

- Total tasks
- Completed tasks
- Open tasks
- Project completion percentage
- SLA distribution
- Tasks by stage
- Tasks by priority
- Progress for each team member

Pull down on the Statistics page to refresh the information.

## Refreshing Data

The dashboard, task list, team page, and statistics page reload their information after a task is created or updated.

Users can also pull down on supported pages to refresh data from SQLite


## Team Contributions

- Emmanuel — Authentication and login interface
- Derrick — Dashboard and team members
- Christian — Task creation, editing, and task list
- Helen — SQLite database, task details, notifications, and statistics

## Important Note

The default login details are included for the class activity testing. 