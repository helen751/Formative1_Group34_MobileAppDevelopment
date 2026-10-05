import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme/devtrack_theme.dart';

void main() {
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
