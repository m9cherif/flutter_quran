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
    const primaryColor = Color(0xFFD4A843);
    const surfaceColor = Color(0xFF1A1A2E);
    const bgColor = Color(0xFF0D1117);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Color(0xFFC9A84C),
        surface: surfaceColor,
        error: Color(0xFFCF6679),
        onPrimary: Color(0xFF1A1A2E),
        onSecondary: Color(0xFF1A1A2E),
        onSurface: Color(0xFFE8E8E8),
      ),
      dividerColor: const Color(0xFF2A2A4A),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withAlpha(180),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF25253E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF6A6A8A)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8E8E8),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8E8E8),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFC0C0D0),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF8A8AA0),
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB0B0C8),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: Color(0xFF8A8AA0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(color: Color(0xFFE8E8E8)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
