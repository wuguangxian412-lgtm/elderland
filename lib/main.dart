import 'package:flutter/material.dart';

import 'pages/loading_page.dart';

void main() {
  runApp(const ElderlandApp());
}

class ElderlandApp extends StatelessWidget {
  const ElderlandApp({super.key});

  static const Color _accent = Color(0xFF7BAE7F);
  static const Color _text = Color(0xFF333333);
  static const Color _border = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) {
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
    );

    return MaterialApp(
      title: 'Elderland',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(_text),
            overlayColor: WidgetStateProperty.all(_accent.withValues(alpha: 0.12)),
            side: WidgetStateProperty.all(const BorderSide(color: _border)),
            shape: WidgetStateProperty.all(roundedShape),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            foregroundColor: WidgetStateProperty.all(_text),
            overlayColor: WidgetStateProperty.all(_accent.withValues(alpha: 0.12)),
            side: WidgetStateProperty.all(const BorderSide(color: _border)),
            shape: WidgetStateProperty.all(roundedShape),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(_accent),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.20)),
            shape: WidgetStateProperty.all(roundedShape),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(_accent),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.20)),
            shape: WidgetStateProperty.all(roundedShape),
          ),
        ),
      ),
      home: const LoadingPage(),
    );
  }
}
