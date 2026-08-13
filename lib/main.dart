import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() {
  runApp(const ReadQuestApp());
}

class ReadQuestApp extends StatefulWidget {
  const ReadQuestApp({super.key});

  @override
  State<ReadQuestApp> createState() => _ReadQuestAppState();
}

class _ReadQuestAppState extends State<ReadQuestApp> {
  final ThemeService _themeService = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    // Carrega o tema salvo (se o usuário já tiver escolhido um antes).
    _themeService.loadSavedPreset();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'ReadQuest',
          debugShowCheckedModeBanner: false,
          theme: _themeService.currentThemeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}
