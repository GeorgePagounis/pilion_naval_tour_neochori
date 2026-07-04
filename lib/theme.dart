import 'package:flutter/material.dart';

/// Naval palette for the tour.
const Color deepNavy = Color(0xFF0B2239); // sea at dusk — background
const Color ropeBeige = Color(0xFFD8C39A); // manila rope — primary actions
const Color seafoam = Color(0xFF7EC8B8); // foam / accents
const Color foam = Color(0xFFF3EFE4); // parchment — body text
const Color deepNavyScrim = Color(0xD90B2239); // 85% navy for photo scrims

const String _fontFamily = 'EBGaramond';

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: deepNavy,
    colorScheme: const ColorScheme.dark(
      primary: ropeBeige,
      onPrimary: deepNavy,
      secondary: seafoam,
      onSecondary: deepNavy,
      surface: deepNavy,
      onSurface: foam,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          fontFamily: _fontFamily,
          bodyColor: foam,
          displayColor: foam,
        )
        .copyWith(
          displaySmall: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 40,
            height: 1.1,
            color: foam,
          ),
          headlineMedium: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 30,
            fontWeight: FontWeight.w500,
            color: foam,
          ),
          titleLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: foam,
          ),
          // Scene narration — larger, generous line height, easy to read on a
          // photo scrim or a projector.
          bodyLarge: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 22,
            height: 1.5,
            color: foam,
          ),
          bodyMedium: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 18,
            height: 1.45,
            color: foam,
          ),
          // Provenance caption — italic, understated.
          labelSmall: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: seafoam,
          ),
        ),
  );
}
