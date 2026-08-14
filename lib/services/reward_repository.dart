import '../models/store_reward.dart';
import 'database_helper.dart';
import 'gamification_service.dart';
import 'streak_freeze_repository.dart';

class RewardRepository {
  RewardRepository._internal();
  static final RewardRepository instance = RewardRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GamificationService _gamification = GamificationService.instance;

  // ---- Recompensas pessoais (cadastradas pelo usuário) ----

  Future<List<CustomReward>> getCustomRewards() async {
    final db = await _dbHelper.database;
    final rows = await db.query('custom_rewards', orderBy: 'created_at DESC');
    return rows.map(CustomReward.fromMap).toList();
  }

  Future<void> addCustomReward({
    required String title,
    required int cost,
    required String emoji,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('custom_rewards', {
      'title': title,
      'cost': cost,
      'emoji': emoji,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove uma recompensa que o próprio usuário cadastrou. As
  /// recompensas do sistema não podem ser removidas.
  Future<void> deleteCustomReward(int id) async {
    final db = await _dbHelper.database;
    await db.delete('custom_rewards', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Recompensas do sistema já desbloqueadas (não-consumíveis) ----

  Future<Set<String>> getOwnedNonConsumableIds() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'reward_redemptions',
      where: 'is_consumable = 0',
    );
    return rows.map((r) => r['reward_id'] as String).toSet();
  }

  // ---- Resgates ----

  Future<RedemptionResult> redeemPredefined(StoreReward reward) async {
    if (!reward.consumable) {
      final owned = await getOwnedNonConsumableIds();
      if (owned.contains(reward.id)) return RedemptionResult.alreadyOwned;
    }

    final success = await _gamification.spendPoints(
      reward.cost,
      'redeemed:${reward.id}',
    );
    if (!success) return RedemptionResult.insufficientPoints;

    await _applyRewardEffect(reward.id);

    final db = await _dbHelper.database;
    await db.insert('reward_redemptions', {
      'reward_id': reward.id,
      'reward_title': reward.title,
      'cost': reward.cost,
      'is_consumable': reward.consumable ? 1 : 0,
      'redeemed_at': DateTime.now().toIso8601String(),
    });

    return RedemptionResult.success;
  }

  Future<RedemptionResult> redeemCustom(CustomReward reward) async {
    final success = await _gamification.spendPoints(
      reward.cost,
      'redeemed:custom_${reward.id}',
    );
    if (!success) return RedemptionResult.insufficientPoints;

    final db = await _dbHelper.database;
    await db.insert('reward_redemptions', {
      'reward_id': 'custom_${reward.id}',
      'reward_title': reward.title,
      'cost': reward.cost,
      'is_consumable': 1,
      'redeemed_at': DateTime.now().toIso8601String(),
    });

    return RedemptionResult.success;
  }

  /// Aplica o efeito real de uma recompensa do sistema, quando houver.
  Future<void> _applyRewardEffect(String rewardId) async {
    switch (rewardId) {
      case 'streak_freeze':
        await StreakFreezeRepository.instance.addFreeze();
        break;
      case 'points_boost_2x_1h':
        await _gamification.activatePointsBoost(
          multiplier: 2.0,
          duration: const Duration(hours: 1),
        );
        break;
      case 'points_boost_2x_24h':
        await _gamification.activatePointsBoost(
          multiplier: 2.0,
          duration: const Duration(hours: 24),
        );
        break;
      // 'accent_gold' e 'deco_stars' têm efeito lido diretamente do
      // Dashboard via getOwnedNonConsumableIds() — nada a fazer aqui.
      // 'banner_reader' e 'emblem_bookworm' ficam guardados no
      // inventário até a tela de Perfil existir.
    }
  }
}
