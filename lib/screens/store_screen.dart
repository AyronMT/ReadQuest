import 'package:flutter/material.dart';
import '../models/store_reward.dart';
import '../services/gamification_service.dart';
import '../services/reward_repository.dart';
import '../services/tutorial_controller.dart';
import '../widgets/tutorial_card.dart';

/// A Loja: recompensas do sistema (com efeito real no app) e
/// recompensas pessoais cadastradas pelo próprio usuário — puramente
/// conceituais, para ele se recompensar por ler tanto.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _rewardRepository = RewardRepository.instance;
  final _gamification = GamificationService.instance;

  int _balance = 0;
  Set<String> _ownedIds = {};
  List<CustomReward> _customRewards = [];
  ({double multiplier, DateTime? expiresAt}) _boostInfo =
      (multiplier: 1.0, expiresAt: null);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final balance = await _gamification.getBalance();
    final owned = await _rewardRepository.getOwnedNonConsumableIds();
    final custom = await _rewardRepository.getCustomRewards();
    final boost = await _gamification.getActiveBoostInfo();

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _ownedIds = owned;
      _customRewards = custom;
      _boostInfo = boost;
      _isLoading = false;
    });
  }

  Future<void> _redeemPredefined(StoreReward reward) async {
    final confirmed = await _confirmRedeem(reward.title, reward.cost);
    if (confirmed != true) return;

    final result = await _rewardRepository.redeemPredefined(reward);
    if (!mounted) return;
    _handleRedemptionResult(result, reward.title);
    _loadData();
  }

  Future<void> _redeemCustom(CustomReward reward) async {
    final confirmed = await _confirmRedeem(reward.title, reward.cost);
    if (confirmed != true) return;

    final result = await _rewardRepository.redeemCustom(reward);
    if (!mounted) return;
    _handleRedemptionResult(result, reward.title);
    _loadData();
  }

  Future<bool?> _confirmRedeem(String title, int cost) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resgatar recompensa'),
        content: Text('Resgatar "$title" por $cost pontos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resgatar'),
          ),
        ],
      ),
    );
  }

  void _handleRedemptionResult(RedemptionResult result, String title) {
    final message = switch (result) {
      RedemptionResult.success => 'Resgatado: $title 🎉',
      RedemptionResult.insufficientPoints => 'Pontos insuficientes para essa recompensa.',
      RedemptionResult.alreadyOwned => 'Você já tem essa recompensa.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddCustomRewardDialog() async {
    final titleController = TextEditingController();
    final costController = TextEditingController();
    var selectedEmoji = '🎁';
    const emojiOptions = ['🎁', '🍫', '🎬', '🍕', '🛁', '🎮', '☕', '🌳', '🎧', '🛍️'];

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova recompensa pessoal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'O que você vai fazer?',
                      hintText: 'Ex: Comer um doce, assistir um filme...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custo em pontos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: emojiOptions.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return ChoiceChip(
                        label: Text(emoji, style: const TextStyle(fontSize: 18)),
                        selected: isSelected,
                        onSelected: (_) => setDialogState(() => selectedEmoji = emoji),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final cost = int.tryParse(costController.text.trim());
                    if (title.isEmpty || cost == null || cost <= 0) return;

                    await _rewardRepository.addCustomReward(
                      title: title,
                      cost: cost,
                      emoji: selectedEmoji,
                    );
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) _loadData();
  }

  Future<void> _confirmDeleteCustomReward(CustomReward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover recompensa'),
        content: Text('Remover "${reward.title}" da sua lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && reward.id != null) {
      await _rewardRepository.deleteCustomReward(reward.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TutorialController.instance,
      builder: (context, _) {
        final showTutorial = TutorialController.instance.isActive &&
            TutorialController.instance.currentScreen == 'store';

        return Stack(
          children: [
            _buildScaffold(context),
            if (showTutorial) const TutorialCard(),
          ],
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🪙 $_balance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (_boostInfo.expiresAt != null) _buildActiveBoostBanner(theme),
                  Text(
                    'Recompensas do sistema',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...StoreCatalog.items.map(
                    (reward) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RewardCard(
                        emoji: reward.emoji,
                        title: reward.title,
                        subtitle: reward.description,
                        categoryLabel: reward.category.label,
                        cost: reward.cost,
                        balance: _balance,
                        isOwned: !reward.consumable && _ownedIds.contains(reward.id),
                        onRedeem: () => _redeemPredefined(reward),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Minhas recompensas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddCustomRewardDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Nova'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recompensas conceituais que você mesmo criou — sem efeito no app, só pra te fazer feliz.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_customRewards.isEmpty)
                    Text(
                      'Você ainda não cadastrou nenhuma recompensa pessoal.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._customRewards.map(
                      (reward) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RewardCard(
                          emoji: reward.emoji,
                          title: reward.title,
                          cost: reward.cost,
                          balance: _balance,
                          onRedeem: () => _redeemCustom(reward),
                          onDelete: () => _confirmDeleteCustomReward(reward),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveBoostBanner(ThemeData theme) {
    final expiresAt = _boostInfo.expiresAt!;
    final label = 'x${_boostInfo.multiplier.toStringAsFixed(0)} pontos ativo até '
        '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')} '
        'de ${expiresAt.day}/${expiresAt.month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? categoryLabel;
  final int cost;
  final int balance;
  final bool isOwned;
  final VoidCallback onRedeem;
  final VoidCallback? onDelete;

  const _RewardCard({
    required this.emoji,
    required this.title,
    this.subtitle,
    this.categoryLabel,
    required this.cost,
    required this.balance,
    this.isOwned = false,
    required this.onRedeem,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = balance >= cost;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categoryLabel != null)
                  Text(
                    categoryLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '🪙 $cost',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remover',
                      ),
                    if (isOwned)
                      Chip(
                        label: const Text('Adquirido'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )
                    else
                      FilledButton(
                        onPressed: canAfford ? onRedeem : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('Resgatar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
