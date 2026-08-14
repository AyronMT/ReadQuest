import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/book_repository.dart';
import '../services/reading_session_repository.dart';
import '../services/gamification_service.dart';
import '../services/reward_repository.dart';
import '../services/tutorial_controller.dart';
import '../services/tutorial_repository.dart';
import '../widgets/tutorial_highlight.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/book_picker_sheet.dart';
import '../widgets/reading_mode_picker_sheet.dart';
import 'library_screen.dart';
import 'reports_screen.dart';
import 'store_screen.dart';
import 'profile_screen.dart';
import 'reading_timer_screen.dart';
import 'manual_reading_entry_screen.dart';

/// A tela principal do ReadQuest: livros em andamento, ofensiva de
/// leitura, resumo do dia e acesso rápido para registrar leitura.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BookRepository _bookRepository = BookRepository.instance;
  final ReadingSessionRepository _sessionRepository =
      ReadingSessionRepository.instance;

  List<Book> _currentBooks = [];
  int _streak = 0;
  ({int pages, int minutes}) _todayTotals = (pages: 0, minutes: 0);
  int _points = 0;
  Set<String> _ownedDecorations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTutorialPrompt();
    });
  }

  Future<void> _loadData() async {
    await GamificationService.instance.awardDailyOpenBonusIfNeeded();

    final books = await _bookRepository.getUnfinishedBooks(limit: 3);
    final streak = await _sessionRepository.getCurrentStreak();
    final todayTotals = await _sessionRepository.getTodayTotals();
    final points = await GamificationService.instance.getBalance();
    final owned = await RewardRepository.instance.getOwnedNonConsumableIds();

    if (!mounted) return;
    setState(() {
      _currentBooks = books;
      _streak = streak;
      _todayTotals = todayTotals;
      _points = points;
      _ownedDecorations = owned;
      _isLoading = false;
    });
  }

  Future<void> _maybeShowTutorialPrompt() async {
    final alreadyPrompted = await TutorialRepository.instance.hasBeenPrompted();
    if (alreadyPrompted) return;

    await TutorialRepository.instance.markPrompted();
    if (!mounted) return;

    final wantsTutorial = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bem-vindo(a) ao ReadQuest! 🎉'),
          content: const Text(
            'Quer um tour rápido para conhecer as principais funcionalidades do app?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim, vamos lá!'),
            ),
          ],
        );
      },
    );

    if (wantsTutorial == true) {
      TutorialController.instance.start();
    }
  }

  Future<void> _openAddReadingFlow() async {
    if (_currentBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você ainda não tem livros em andamento.'),
        ),
      );
      return;
    }

    final allUnfinished = await _bookRepository.getUnfinishedBooks();
    if (!mounted) return;

    final selectedBook = await showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookPickerSheet(
        books: allUnfinished,
        preselected: _currentBooks.first,
      ),
    );
    if (selectedBook == null) return;
    if (!mounted) return;

    final mode = await showModalBottomSheet<ReadingMode>(
      context: context,
      builder: (_) => const ReadingModePickerSheet(),
    );
    if (mode == null) return;
    if (!mounted) return;

    if (mode == ReadingMode.timer) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReadingTimerScreen(book: selectedBook)),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ManualReadingEntryScreen(book: selectedBook),
        ),
      );
    }

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TutorialController.instance,
      builder: (context, _) {
        final showTutorial = TutorialController.instance.isActive &&
            TutorialController.instance.currentScreen == 'dashboard';

        return Stack(
          children: [
            Scaffold(
              body: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                          children: [
                            _buildTopBar(context),
                            const SizedBox(height: 28),
                            _buildCurrentBooksSection(context),
                            const SizedBox(height: 24),
                            _buildStreakSection(context),
                            const SizedBox(height: 16),
                            _buildTodaySection(context),
                          ],
                        ),
                      ),
              ),
              bottomNavigationBar: _buildBottomNav(context),
              floatingActionButton: TutorialHighlight(
                stepId: 'nav_add',
                child: FloatingActionButton(
                  onPressed: _openAddReadingFlow,
                  child: const Icon(Icons.add),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
            ),
            if (showTutorial) const TutorialCard(),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReadQuest',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Continue sua jornada de leitura',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '$_points',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TutorialHighlight(
              stepId: 'profile_button',
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                icon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentBooksSection(BuildContext context) {
    final theme = Theme.of(context);

    return TutorialHighlight(
      stepId: 'current_books',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lendo agora',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TutorialHighlight(
                stepId: 'library_button',
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  ),
                  child: const Text('Ver biblioteca'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentBooks.isEmpty)
            Text(
              'Você ainda não tem livros em andamento.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ..._currentBooks.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BookProgressCard(book: book),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoldAccent = _ownedDecorations.contains('accent_gold');
    final hasStarsDecoration = _ownedDecorations.contains('deco_stars');
    final flameColor = hasGoldAccent ? Colors.amber.shade700 : Colors.deepOrange;

    return TutorialHighlight(
      stepId: 'streak',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: flameColor,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$_streak ${_streak == 1 ? "dia" : "dias"} seguidos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasStarsDecoration) ...[
                        const SizedBox(width: 6),
                        const Text('🌟', style: TextStyle(fontSize: 16)),
                      ],
                    ],
                  ),
                  Text(
                    'Sua ofensiva de leitura',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context) {
    final theme = Theme.of(context);
    final hasReadToday = _todayTotals.pages > 0;

    return TutorialHighlight(
      stepId: 'today_summary',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.today_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: hasReadToday
                  ? Text(
                      'Hoje você já leu ${_todayTotals.pages} páginas em ${_todayTotals.minutes} min.',
                      style: theme.textTheme.bodyMedium,
                    )
                  : Text(
                      'Nenhum registro de leitura hoje ainda.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TutorialHighlight(
            stepId: 'nav_home',
            child: IconButton(
              onPressed: () {}, // já estamos no Dashboard
              icon: const Icon(Icons.home_rounded),
            ),
          ),
          TutorialHighlight(
            stepId: 'nav_library',
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
              icon: const Icon(Icons.menu_book_rounded),
            ),
          ),
          const SizedBox(width: 40), // espaço reservado para o FAB
          TutorialHighlight(
            stepId: 'nav_reports',
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
              icon: const Icon(Icons.bar_chart_rounded),
            ),
          ),
          TutorialHighlight(
            stepId: 'nav_store',
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StoreScreen()),
              ),
              icon: const Icon(Icons.storefront_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card compacto de progresso de um livro em andamento.
class _BookProgressCard extends StatelessWidget {
  final Book book;

  const _BookProgressCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  book.author ?? 'Autor desconhecido',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: book.progress,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.currentPage}/${book.totalPages} páginas',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
