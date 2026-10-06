import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'app_colors.dart';

void main() {
  runApp(const DevTrackApp());
}

class DevTrackApp extends StatelessWidget {
  const DevTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kDarkOrange),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const LoginPage(),
    );
  }
}