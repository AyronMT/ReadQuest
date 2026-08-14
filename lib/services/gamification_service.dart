import 'database_helper.dart';

/// Quantidade de pontos concedida por cada ação do app.
class GamificationRules {
  static const int appOpenDaily = 5;
  static const int readingLogged = 5;
  static const int dailyStreakBonus = 10;
  static const int bookFinishedBonus = 50;
}

/// Gerencia o saldo de pontos do usuário (via histórico de
/// transações), o bônus diário de abrir o app e o multiplicador
/// temporário de pontos (comprado na loja).
class GamificationService {
  GamificationService._internal();
  static final GamificationService instance = GamificationService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const _kBoostMultiplierKey = 'points_boost_multiplier';
  static const _kBoostExpiresAtKey = 'points_boost_expires_at';

  String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Saldo atual de pontos (soma de todas as transações).
  Future<int> getBalance() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM point_transactions',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Concede pontos ao usuário (aplicando o multiplicador ativo, se
  /// houver) e retorna quantos pontos foram realmente creditados.
  Future<int> awardPoints(int baseAmount, String reason) async {
    final multiplier = await _getActiveMultiplier();
    final finalAmount = (baseAmount * multiplier).round();

    final db = await _dbHelper.database;
    await db.insert('point_transactions', {
      'amount': finalAmount,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    return finalAmount;
  }

  /// Tenta gastar pontos (ex: resgate na loja). Retorna false se o
  /// saldo for insuficiente, sem debitar nada.
  Future<bool> spendPoints(int amount, String reason) async {
    final balance = await getBalance();
    if (balance < amount) return false;

    final db = await _dbHelper.database;
    await db.insert('point_transactions', {
      'amount': -amount,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  /// Concede o bônus por abrir o app, uma vez por dia.
  Future<void> awardDailyOpenBonusIfNeeded() async {
    final db = await _dbHelper.database;
    final todayKey = _dateKey(DateTime.now());

    final existing = await db.query(
      'point_transactions',
      where: "reason = ? AND created_at LIKE ?",
      whereArgs: ['daily_open', '$todayKey%'],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await awardPoints(GamificationRules.appOpenDaily, 'daily_open');
  }

  /// Ativa um multiplicador temporário de pontos (comprado na loja).
  Future<void> activatePointsBoost({
    required double multiplier,
    required Duration duration,
  }) async {
    final expiresAt = DateTime.now().add(duration);
    await _dbHelper.setSetting(_kBoostMultiplierKey, multiplier.toString());
    await _dbHelper.setSetting(_kBoostExpiresAtKey, expiresAt.toIso8601String());
  }

  /// Informações sobre o multiplicador ativo no momento, se houver.
  Future<({double multiplier, DateTime? expiresAt})> getActiveBoostInfo() async {
    final expiresAtStr = await _dbHelper.getSetting(_kBoostExpiresAtKey);
    if (expiresAtStr == null) return (multiplier: 1.0, expiresAt: null);

    final expiresAt = DateTime.parse(expiresAtStr);
    if (DateTime.now().isAfter(expiresAt)) return (multiplier: 1.0, expiresAt: null);

    final multiplierStr = await _dbHelper.getSetting(_kBoostMultiplierKey);
    final multiplier = double.tryParse(multiplierStr ?? '1.0') ?? 1.0;
    return (multiplier: multiplier, expiresAt: expiresAt);
  }

  Future<double> _getActiveMultiplier() async {
    final info = await getActiveBoostInfo();
    return info.multiplier;
  }
}
