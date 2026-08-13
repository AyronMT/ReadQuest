import 'database_helper.dart';

/// Controla se o pop-up de convite ao tutorial já foi mostrado
/// (para não perguntar de novo a cada abertura do app).
class TutorialRepository {
  TutorialRepository._internal();
  static final TutorialRepository instance = TutorialRepository._internal();

  static const _kPromptShownKey = 'tutorial_prompt_shown';

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<bool> hasBeenPrompted() async {
    return (await _db.getSetting(_kPromptShownKey)) == 'true';
  }

  Future<void> markPrompted() async {
    await _db.setSetting(_kPromptShownKey, 'true');
  }
}
