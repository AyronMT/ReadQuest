import 'package:flutter/material.dart';
import '../models/report_stats.dart';
import '../services/reports_repository.dart';
import '../services/tutorial_controller.dart';
import '../widgets/tutorial_card.dart';

/// A tela de Relatórios: acompanhamento geral (mensal, hábito,
/// métricas clássicas, perfil literário, gamificação) e
/// acompanhamento individual por saga.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repository = ReportsRepository.instance;

  bool _isLoading = true;
  String? _selectedSaga; // null = visão geral
  List<String> _availableSagas = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  MonthlyWrapped? _wrapped;
  HabitStats? _habit;
  ClassicStats? _classic;
  ReaderProfile? _profile;
  EconomyStats? _economy;
  SagaStats? _sagaStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final sagas = await _repository.getAllSeries();

    if (_selectedSaga == null) {
      final wrapped = await _repository.getMonthlyWrapped(_selectedMonth);
      final habit = await _repository.getHabitStats(referenceMonth: _selectedMonth);
      final classic = await _repository.getClassicStats();
      final profile = await _repository.getReaderProfile();
      final economy = await _repository.getEconomyStats();

      if (!mounted) return;
      setState(() {
        _availableSagas = sagas;
        _wrapped = wrapped;
        _habit = habit;
        _classic = classic;
        _profile = profile;
        _economy = economy;
        _isLoading = false;
      });
    } else {
      final saga = await _repository.getSagaStats(_selectedSaga!);
      if (!mounted) return;
      setState(() {
        _availableSagas = sagas;
        _sagaStats = saga;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _loadData();
  }

  void _selectScope(String? saga) {
    setState(() => _selectedSaga = saga);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TutorialController.instance,
      builder: (context, _) {
        final showTutorial = TutorialController.instance.isActive &&
            TutorialController.instance.currentScreen == 'reports';

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
      appBar: AppBar(title: const Text('Relatórios')),
      body: SafeArea(
        child: Column(
          children: [
            _buildScopeSelector(theme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _selectedSaga == null
                          ? _buildGeneralReport(theme)
                          : _buildSagaReport(theme),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSelector(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          ChoiceChip(
            label: const Text('Geral'),
            selected: _selectedSaga == null,
            onSelected: (_) => _selectScope(null),
          ),
          const SizedBox(width: 8),
          ..._availableSagas.map(
            (saga) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(saga),
                selected: _selectedSaga == saga,
                onSelected: (_) => _selectScope(saga),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= VISÃO GERAL =================

  Widget _buildGeneralReport(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _buildSectionTitle(theme, '📖 Seu mês, resumido'),
        const SizedBox(height: 8),
        _buildMonthNavigator(theme),
        const SizedBox(height: 12),
        _buildWrappedCard(theme),
        const SizedBox(height: 28),

        _buildSectionTitle(theme, '🔥 Hábito e consistência'),
        const SizedBox(height: 12),
        _buildHabitSection(theme),
        const SizedBox(height: 28),

        _buildSectionTitle(theme, '📊 Métricas clássicas'),
        const SizedBox(height: 12),
        _buildClassicMetricsGrid(theme, _classic!),
        const SizedBox(height: 28),

        _buildSectionTitle(theme, '🔍 Raio-X do leitor'),
        const SizedBox(height: 12),
        _buildReaderProfileSection(theme),
        const SizedBox(height: 28),

        _buildSectionTitle(theme, '🪙 Economia e gamificação'),
        const SizedBox(height: 12),
        _buildEconomySection(theme),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMonthNavigator(ThemeData theme) {
    const monthNames = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final label = '${monthNames[_selectedMonth.month - 1]} de ${_selectedMonth.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _buildWrappedCard(ThemeData theme) {
    final wrapped = _wrapped!;
    final change = wrapped.pagesChangePercent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${wrapped.pagesRead} páginas lidas',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 4),
            Text(
              '${change >= 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}% vs. mês anterior',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _wrappedStat('⏱️', '${wrapped.minutesRead} min'),
              _wrappedStat('📚', '${wrapped.sessionsCount} sessões'),
              _wrappedStat('🏁', '${wrapped.booksFinished} livros concluídos'),
              if (wrapped.topGenre != null) _wrappedStat('🎭', wrapped.topGenre!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wrappedStat(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHabitSection(ThemeData theme) {
    final habit = _habit!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                emoji: '🔥',
                label: 'Ofensiva atual',
                value: '${habit.currentStreak} dias',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                emoji: '🏆',
                label: 'Recorde de ofensiva',
                value: '${habit.longestStreak} dias',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${habit.activeDaysThisMonth} de ${habit.daysInMonthSoFar} dias com leitura',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _buildMonthCalendarDots(theme, habit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCalendarDots(ThemeData theme, HabitStats habit) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(habit.daysInMonthSoFar, (i) {
        final day = i + 1;
        final isActive = habit.activeDaysOfMonth.contains(day);
        return Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 9,
              color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildClassicMetricsGrid(ThemeData theme, ClassicStats classic) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatTile(emoji: '📄', label: 'Páginas lidas (total)', value: '${classic.totalPagesRead}'),
        _StatTile(emoji: '⏱️', label: 'Tempo lido (total)', value: '${classic.totalMinutesRead} min'),
        _StatTile(emoji: '🏁', label: 'Livros concluídos', value: '${classic.booksFinished}'),
        _StatTile(
          emoji: '⚡',
          label: 'Ritmo médio',
          value: '${classic.avgPagesPerMinute.toStringAsFixed(2)} pág/min',
        ),
        _StatTile(
          emoji: '🕐',
          label: 'Sessão média',
          value: '${classic.avgSessionMinutes.toStringAsFixed(0)} min',
        ),
        _StatTile(
          emoji: '📅',
          label: 'Média por dia ativo',
          value: '${classic.avgPagesPerActiveDay.toStringAsFixed(0)} pág',
        ),
      ],
    );
  }

  Widget _buildReaderProfileSection(ThemeData theme) {
    final profile = _profile!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.topAuthor != null) ...[
          _StatTile(emoji: '✍️', label: 'Autor favorito', value: profile.topAuthor!, wide: true),
          const SizedBox(height: 16),
        ],
        if (profile.genreDistribution.isNotEmpty) ...[
          Text('Gêneros mais lidos', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _buildDistributionBars(
            theme,
            profile.genreDistribution
                .take(5)
                .map((g) => MapEntry(g.genre, g.pages))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (profile.emotionCounts.isNotEmpty) ...[
          Text('Como você se sentiu lendo', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: profile.emotionCounts.entries.map((e) {
              return Column(
                children: [
                  Text(e.key.emoji, style: const TextStyle(fontSize: 22)),
                  Text('${e.value}x', style: theme.textTheme.bodySmall),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('Horário preferido de leitura', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _buildDistributionBars(theme, profile.timeOfDayCounts.entries.toList()),
      ],
    );
  }

  Widget _buildDistributionBars(ThemeData theme, List<MapEntry<String, int>> entries) {
    final maxValue = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);

    return Column(
      children: entries.map((entry) {
        final fraction = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(entry.key, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 14,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${entry.value}', style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEconomySection(ThemeData theme) {
    final economy = _economy!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatTile(emoji: '🪙', label: 'Saldo atual', value: '${economy.currentBalance}'),
        _StatTile(emoji: '📈', label: 'Total ganho', value: '${economy.totalEarned}'),
        _StatTile(emoji: '📉', label: 'Total gasto', value: '${economy.totalSpent}'),
        _StatTile(emoji: '🎁', label: 'Recompensas resgatadas', value: '${economy.rewardsRedeemed}'),
        _StatTile(emoji: '🧊', label: 'Congelamentos disponíveis', value: '${economy.streakFreezesAvailable}'),
      ],
    );
  }

  // ================= VISÃO POR SAGA =================

  Widget _buildSagaReport(ThemeData theme) {
    final saga = _sagaStats!;

    if (saga.books.isEmpty) {
      return Center(
        child: Text(
          'Nenhum livro cadastrado nessa saga.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          saga.seriesName,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${saga.finishedBooks}/${saga.books.length} livros concluídos',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _StatTile(emoji: '📄', label: 'Páginas lidas', value: '${saga.totalPagesRead}'),
            _StatTile(emoji: '⏱️', label: 'Tempo lido', value: '${saga.totalMinutesRead} min'),
          ],
        ),
        if (saga.emotionCounts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Emoções na saga', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            children: saga.emotionCounts.entries.map((e) {
              return Column(
                children: [
                  Text(e.key.emoji, style: const TextStyle(fontSize: 22)),
                  Text('${e.value}x', style: theme.textTheme.bodySmall),
                ],
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
        Text('Livros da saga', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...saga.books.map(
          (book) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(book.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text('${book.currentPage}/${book.totalPages}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool wide;

  const _StatTile({
    required this.emoji,
    required this.label,
    required this.value,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
