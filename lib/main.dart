import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/annotation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const QuranAnnotationApp());
}

class QuranAnnotationApp extends StatelessWidget {
  const QuranAnnotationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تحديد الكلمات القرآنية',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AnnotationScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD4A843),
        brightness: Brightness.light,
      ),
      dividerColor: const Color(0xFFE0E0E0),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD4A843), width: 1.5),
        ),
      ),
    );
  }
}
