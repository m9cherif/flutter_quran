import 'package:flutter/material.dart';
import 'mobile_screen.dart';

class QuranPreviewApp extends StatelessWidget {
  const QuranPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4A843);
    return MaterialApp(
      title: 'القرآن الكريم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0.5,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          elevation: 0.5,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MobileScreen(),
    );
  }
}
