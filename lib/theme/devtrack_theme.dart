import 'package:flutter/material.dart';

/// Color palette used across the app: base colors plus the task status colors.
class DevTrackColors {
  DevTrackColors._();

  // Base palette.
  static const background = Color(0xFFF5FBF9);
  static const surface = Colors.white;
  static const ink = Color(0xFF25272C);
  static const muted = Color(0xFF6B7078);
  static const mint = Color(0xFFB8F7E4);
  static const border = Color(0xFFE3ECE8);

  // Task status colors, shared by badges, status bars and the SLA cards.
  static const onTrack = Color(0xFF1FAF85);
  static const atRisk = Color(0xFFF0A020);
  static const overdue = Color(0xFFE5484D);
  static const completed = Color(0xFF6B7078);

  /// 12% tint used behind status icons and badges.
  static Color tint(Color color) => color.withValues(alpha: 0.12);
}

/// App-wide theme built from [DevTrackColors].
class DevTrackTheme {
  DevTrackTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        // Roboto ships with Android; other platforms fall back to their system
        // font unless Roboto is added to pubspec.yaml.
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: DevTrackColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DevTrackColors.mint,
          primary: DevTrackColors.ink,
          surface: DevTrackColors.background,
        ),
      );
}

/// Shared card decoration: white, 1px border, rounded corners.
BoxDecoration devTrackCard({double radius = 20}) => BoxDecoration(
      color: DevTrackColors.surface,
      border: Border.all(color: DevTrackColors.border),
      borderRadius: BorderRadius.circular(radius),
    );
