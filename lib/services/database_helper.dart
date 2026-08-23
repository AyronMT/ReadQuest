import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Responsável por abrir/criar o banco SQLite local e expor
/// as tabelas de configurações, usuários, livros e sessões de leitura.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'readquest.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT,
            salt TEXT,
            auth_provider TEXT NOT NULL DEFAULT 'email',
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            author TEXT,
            total_pages INTEGER NOT NULL,
            current_page INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'reading',
            isbn TEXT,
            cover_path TEXT,
            series TEXT,
            genre TEXT,
            publisher TEXT,
            is_active INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reading_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            pages_read INTEGER NOT NULL,
            duration_minutes INTEGER NOT NULL,
            mode TEXT NOT NULL,
            emotion TEXT,
            feedback TEXT,
            session_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (book_id) REFERENCES books (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE point_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount INTEGER NOT NULL,
            reason TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE streak_freezes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT NOT NULL DEFAULT 'available',
            protected_date TEXT,
            created_at TEXT NOT NULL,
            used_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE custom_rewards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            cost INTEGER NOT NULL,
            emoji TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reward_redemptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reward_id TEXT NOT NULL,
            reward_title TEXT NOT NULL,
            cost INTEGER NOT NULL,
            is_consumable INTEGER NOT NULL,
            redeemed_at TEXT NOT NULL
          )
        ''');

        // Aqui futuramente entram outras tabelas do app: metas, loja, etc.
      },
    );
  }

  // ---- settings (key-value) ----

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> removeSetting(String key) async {
    final db = await database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
