import 'package:flutter/material.dart';
import '../screens/library_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/store_screen.dart';

/// Empilha a tela seguinte do fluxo de tutorial pelo nome lógico
/// usado em [TutorialController].
void pushTutorialScreen(BuildContext context, String screenName) {
  Widget? screen;
  switch (screenName) {
    case 'library':
      screen = const LibraryScreen();
      break;
    case 'reports':
      screen = const ReportsScreen();
      break;
    case 'store':
      screen = const StoreScreen();
      break;
  }

  if (screen == null) return;

  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => screen!),
  );
}
