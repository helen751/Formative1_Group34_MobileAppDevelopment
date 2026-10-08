import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'database/database_seeder.dart';
import 'services/task_notification_service.dart';

import 'screens/home_shell.dart';
import 'theme/devtrack_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // opening the database
  await DatabaseHelper.instance.database;

  // adding default data when the tables are empty
  await DatabaseSeeder.seedDatabase();

  // checking tasks for new notifications
  await TaskNotificationService.checkTaskDeadlines();

  runApp(const MyApp());
}

/// Root widget: applies the DevTrack theme and starts on [HomeShell].
///
/// Point [MaterialApp.home] at the login page once auth is plugged in.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevTrack',
      debugShowCheckedModeBanner: false,
      theme: DevTrackTheme.light,
      home: const HomeShell(),
    );
  }
}
