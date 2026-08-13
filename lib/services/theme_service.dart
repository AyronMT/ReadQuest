import 'package:flutter/material.dart';
import '../models/app_theme_preset.dart';
import 'database_helper.dart';

/// Gerencia o tema visual ativo do app, persiste a escolha no SQLite
/// e notifica os widgets (via ChangeNotifier) quando ela muda,
/// permitindo troca de tema em tempo real sem reiniciar o app.
class ThemeService extends ChangeNotifier {
  ThemeService._internal();
  static final ThemeService instance = ThemeService._internal();

  static const _kThemePresetKey = 'theme_preset';

  final DatabaseHelper _db = DatabaseHelper.instance;

  AppThemePreset _currentPreset = AppThemePreset.adulto;
  AppThemePreset get currentPreset => _currentPreset;

  ThemeData get currentThemeData => _currentPreset.buildThemeData();

  /// Carrega o tema salvo (se houver). Deve ser chamado no início do app.
  Future<void> loadSavedPreset() async {
    final saved = await _db.getSetting(_kThemePresetKey);
    if (saved != null) {
      _currentPreset = AppThemePreset.values.byName(saved);
      notifyListeners();
    }
  }

  /// Define e persiste um novo tema.
  Future<void> setPreset(AppThemePreset preset) async {
    _currentPreset = preset;
    notifyListeners();
    await _db.setSetting(_kThemePresetKey, preset.name);
  }
}
