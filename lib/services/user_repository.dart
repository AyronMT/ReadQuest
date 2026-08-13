import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_helper.dart';
import 'auth_service.dart';

/// Erro de autenticação com mensagem amigável para exibir na UI.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Responsável pelo cadastro e login de usuários.
/// Senhas nunca são guardadas em texto puro: cada usuário tem um
/// salt aleatório próprio, e o hash é SHA-256(salt + senha).
class UserRepository {
  UserRepository._internal();
  static final UserRepository instance = UserRepository._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }

  /// Cadastra um novo usuário com e-mail e senha.
  /// Lança [AuthException] se o e-mail já estiver em uso.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final db = await _db.database;

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw AuthException('Este e-mail já está cadastrado.');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    await db.insert('users', {
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'salt': salt,
      'auth_provider': 'email',
      'created_at': DateTime.now().toIso8601String(),
    });

    await _authService.setLoggedIn(normalizedEmail);
  }

  /// Autentica um usuário existente com e-mail e senha.
  /// Lança [AuthException] se as credenciais forem inválidas.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final db = await _db.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (result.isEmpty) {
      throw AuthException('E-mail ou senha incorretos.');
    }

    final user = result.first;

    if (user['auth_provider'] != 'email') {
      throw AuthException('Esta conta usa login com Google.');
    }

    final salt = user['salt'] as String;
    final storedHash = user['password_hash'] as String;
    final attemptHash = _hashPassword(password, salt);

    if (attemptHash != storedHash) {
      throw AuthException('E-mail ou senha incorretos.');
    }

    await _authService.setLoggedIn(normalizedEmail);
  }

  /// Cadastra (se novo) ou autentica (se já existente) um usuário
  /// via conta Google. Retorna true se foi um cadastro novo.
  Future<bool> continueWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      // Usuário cancelou o fluxo do Google.
      throw AuthException('Login com Google cancelado.');
    }

    final normalizedEmail = account.email.trim().toLowerCase();
    final db = await _db.database;

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    var isNewUser = false;

    if (existing.isEmpty) {
      isNewUser = true;
      await db.insert('users', {
        'email': normalizedEmail,
        'password_hash': null,
        'salt': null,
        'auth_provider': 'google',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    await _authService.setLoggedIn(normalizedEmail);
    return isNewUser;
  }
}
