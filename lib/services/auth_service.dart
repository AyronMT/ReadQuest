import 'database_helper.dart';

/// Serviço responsável por verificar e gerenciar o estado de "sessão"
/// do usuário: logado na nuvem (com conta) ou usando o app localmente.
/// O estado é persistido na tabela `settings` do SQLite local.
class AuthService {
  static const _kIsLoggedInKey = 'is_logged_in';
  static const _kIsLocalModeKey = 'is_local_mode';
  static const _kUserEmailKey = 'user_email';

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Retorna true se o usuário deve ir direto para o Dashboard,
  /// seja porque está logado na nuvem, seja porque optou pelo modo local.
  Future<bool> hasActiveSession() async {
    final isLoggedIn = await _db.getSetting(_kIsLoggedInKey) == 'true';
    final isLocalMode = await _db.getSetting(_kIsLocalModeKey) == 'true';
    return isLoggedIn || isLocalMode;
  }

  /// Marca o usuário como logado (fluxo com conta / nuvem).
  Future<void> setLoggedIn(String email) async {
    await _db.setSetting(_kIsLoggedInKey, 'true');
    await _db.setSetting(_kIsLocalModeKey, 'false');
    await _db.setSetting(_kUserEmailKey, email);
  }

  /// Marca o usuário como usando o app apenas localmente (sem conta).
  Future<void> setLocalMode() async {
    await _db.setSetting(_kIsLocalModeKey, 'true');
    await _db.setSetting(_kIsLoggedInKey, 'false');
  }

  /// Encerra a sessão (logout), mantendo a opção de voltar ao login.
  Future<void> signOut() async {
    await _db.setSetting(_kIsLoggedInKey, 'false');
    await _db.setSetting(_kIsLocalModeKey, 'false');
    await _db.removeSetting(_kUserEmailKey);
  }
}
