import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/level_select_screen.dart';
import 'utils/vantage_theme.dart';

void main() {
  runApp(const ProviderScope(child: VantageApp()));
}

class VantageApp extends StatelessWidget {
  const VantageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vantage',
      theme: VantageTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const LevelSelectScreen(),
    );
  }
}
