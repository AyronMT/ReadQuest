/// Categoria de uma recompensa da loja.
enum RewardCategory {
  streakFreeze,
  pointsBoost,
  interfaceCustomization,
  dashboardCustomization,
  screenDecoration,
  banner,
  emblem,
  custom;

  String get label {
    switch (this) {
      case RewardCategory.streakFreeze:
        return 'Congelamento de ofensiva';
      case RewardCategory.pointsBoost:
        return 'Bônus de pontos';
      case RewardCategory.interfaceCustomization:
        return 'Customização de interface';
      case RewardCategory.dashboardCustomization:
        return 'Customização do Dashboard';
      case RewardCategory.screenDecoration:
        return 'Decoração de tela';
      case RewardCategory.banner:
        return 'Banner de perfil';
      case RewardCategory.emblem:
        return 'Emblema de perfil';
      case RewardCategory.custom:
        return 'Recompensa pessoal';
    }
  }
}

/// Uma recompensa pré-definida pelo sistema (com valor "real":
/// afeta o app de alguma forma) ou, no caso de [RewardCategory.custom],
/// o "molde" usado para uma recompensa criada pelo próprio usuário.
class StoreReward {
  final String id;
  final String title;
  final String description;
  final int cost;
  final RewardCategory category;
  final String emoji;

  /// Se true, pode ser comprada várias vezes (ex: congelamentos,
  /// bônus temporários). Se false, é um desbloqueio único.
  final bool consumable;

  const StoreReward({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.category,
    required this.emoji,
    this.consumable = false,
  });
}

/// Catálogo fixo de recompensas do sistema.
class StoreCatalog {
  static const List<StoreReward> items = [
    StoreReward(
      id: 'streak_freeze',
      title: 'Congelar ofensiva',
      description: 'Protege sua sequência caso você perca um dia de leitura.',
      cost: 150,
      category: RewardCategory.streakFreeze,
      emoji: '🧊',
      consumable: true,
    ),
    StoreReward(
      id: 'points_boost_2x_1h',
      title: 'x2 pontos por 1 hora',
      description: 'Todo ponto que você ganhar vale o dobro pela próxima hora.',
      cost: 100,
      category: RewardCategory.pointsBoost,
      emoji: '⚡',
      consumable: true,
    ),
    StoreReward(
      id: 'points_boost_2x_24h',
      title: 'x2 pontos por 24 horas',
      description: 'Todo ponto que você ganhar vale o dobro pelas próximas 24 horas.',
      cost: 400,
      category: RewardCategory.pointsBoost,
      emoji: '🚀',
      consumable: true,
    ),
    StoreReward(
      id: 'accent_gold',
      title: 'Destaque dourado',
      description: 'Muda a cor de destaque do card de ofensiva no Dashboard.',
      cost: 200,
      category: RewardCategory.interfaceCustomization,
      emoji: '✨',
    ),
    StoreReward(
      id: 'deco_stars',
      title: 'Decoração estelar',
      description: 'Adiciona estrelinhas decorativas ao card de ofensiva.',
      cost: 120,
      category: RewardCategory.dashboardCustomization,
      emoji: '🌟',
    ),
    StoreReward(
      id: 'banner_reader',
      title: 'Banner: Leitor Dedicado',
      description: 'Banner para exibir no seu perfil (em breve).',
      cost: 300,
      category: RewardCategory.banner,
      emoji: '🚩',
    ),
    StoreReward(
      id: 'emblem_bookworm',
      title: 'Emblema: Rato de Biblioteca',
      description: 'Emblema para exibir no seu perfil (em breve).',
      cost: 250,
      category: RewardCategory.emblem,
      emoji: '🐛',
    ),
  ];
}

/// Uma recompensa "conceitual" cadastrada pelo próprio usuário —
/// sem efeito real no app, só para ele se recompensar (ex: "comer
/// um doce", "assistir um filme").
class CustomReward {
  final int? id;
  final String title;
  final int cost;
  final String emoji;
  final DateTime createdAt;

  const CustomReward({
    this.id,
    required this.title,
    required this.cost,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'cost': cost,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomReward.fromMap(Map<String, Object?> map) {
    return CustomReward(
      id: map['id'] as int?,
      title: map['title'] as String,
      cost: map['cost'] as int,
      emoji: map['emoji'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum RedemptionResult { success, insufficientPoints, alreadyOwned }
