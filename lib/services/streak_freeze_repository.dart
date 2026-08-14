import 'database_helper.dart';

/// Gerencia os "congelamentos de ofensiva" comprados na loja: cada
/// um protege um único dia sem leitura para que a sequência não
/// quebre. São consumidos automaticamente quando o cálculo da
/// ofensiva encontra uma lacuna de exatamente um dia.
class StreakFreezeRepository {
  StreakFreezeRepository._internal();
  static final StreakFreezeRepository instance =
      StreakFreezeRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<int> getAvailableCount() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'streak_freezes',
      where: 'status = ?',
      whereArgs: ['available'],
    );
    return rows.length;
  }

  Future<void> addFreeze() async {
    final db = await _dbHelper.database;
    await db.insert('streak_freezes', {
      'status': 'available',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Tenta cobrir a lacuna de leitura no dia [date]. Se esse dia já
  /// tiver sido coberto antes, retorna true sem consumir outro
  /// congelamento. Se houver um congelamento disponível, consome-o
  /// e retorna true. Caso contrário, retorna false (a ofensiva quebra).
  Future<bool> coverGapDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateKey = _dateKey(date);

    final alreadyUsed = await db.query(
      'streak_freezes',
      where: 'status = ? AND protected_date = ?',
      whereArgs: ['used', dateKey],
      limit: 1,
    );
    if (alreadyUsed.isNotEmpty) return true;

    final available = await db.query(
      'streak_freezes',
      where: 'status = ?',
      whereArgs: ['available'],
      limit: 1,
    );
    if (available.isEmpty) return false;

    await db.update(
      'streak_freezes',
      {
        'status': 'used',
        'protected_date': dateKey,
        'used_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [available.first['id']],
    );

    return true;
  }
}
