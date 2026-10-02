import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'router.dart';

void main() => runApp(const LostFoundApp());

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
    ),
  );
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key, this.routerConfig});
  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'LostFound',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: routerConfig ?? router,
  );
}
