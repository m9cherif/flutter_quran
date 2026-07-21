import 'package:flutter/material.dart';
import 'mobile_screen.dart';

class QuranPreviewApp extends StatelessWidget {
  const QuranPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'القرآن الكريم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A843),
          brightness: Brightness.dark,
        ),
      ),
      home: const MobileScreen(),
    );
  }
}
