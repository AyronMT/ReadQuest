import 'package:flutter/material.dart';
import '../models/app_theme_preset.dart';
import '../models/book.dart';
import '../services/book_repository.dart';
import '../services/theme_service.dart';
import '../services/tutorial_controller.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/book_card.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

/// A Biblioteca do usuário. O layout muda de verdade de acordo com o
/// perfil de interface escolhido no cadastro: crianças têm uma grade
/// grande e simples, idosos têm uma lista com textos e toques
/// ampliados, e adolescentes/adultos têm o conjunto completo de
/// busca, filtros, ordenação e alternância grade/lista.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _bookRepository = BookRepository.instance;

  List<Book> _books = [];
  List<String> _genres = [];
  bool _isLoading = true;
  bool _isGridView = true;

  String _searchQuery = '';
  BookStatus? _statusFilter;
  String? _genreFilter;
  BookSortOption _sortOption = BookSortOption.recentlyUpdated;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final books = await _bookRepository.getFilteredBooks(
      status: _statusFilter,
      genre: _genreFilter,
      searchQuery: _searchQuery,
      sortBy: _sortOption,
    );
    final genres = await _bookRepository.getDistinctGenres();

    if (!mounted) return;
    setState(() {
      _books = books;
      _genres = genres;
      _isLoading = false;
    });
  }

  Future<void> _openAddBook() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddBookScreen()),
    );
    if (added == true) _loadData();
  }

  Future<void> _openBookDetail(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TutorialController.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        final showTutorial = TutorialController.instance.isActive &&
            TutorialController.instance.currentScreen == 'library';
        final preset = ThemeService.instance.currentPreset;

        Widget content;
        switch (preset) {
          case AppThemePreset.crianca:
            content = _buildKidsLayout(context);
            break;
          case AppThemePreset.idoso:
            content = _buildElderlyLayout(context);
            break;
          case AppThemePreset.adolescente:
          case AppThemePreset.adulto:
            content = _buildStandardLayout(context);
            break;
        }

        return Stack(
          children: [
            content,
            if (showTutorial) const TutorialCard(),
          ],
        );
      },
    );
  }

  // ---- Layout padrão (adolescente / adulto): completo ----

  Widget _buildStandardLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'Ver em lista' : 'Ver em grade',
          ),
          PopupMenuButton<BookSortOption>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (option) {
              setState(() => _sortOption = option);
              _loadData();
            },
            itemBuilder: (context) => BookSortOption.values
                .map((o) => PopupMenuItem(value: o, child: Text(o.label)))
                .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar por título ou autor',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _loadData();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatusChip(
                    label: 'Todos',
                    selected: _statusFilter == null,
                    onTap: () {
                      setState(() => _statusFilter = null);
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...BookStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StatusChip(
                        label: status.label,
                        selected: _statusFilter == status,
                        onTap: () {
                          setState(() => _statusFilter = status);
                          _loadData();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_genres.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _genres
                      .map(
                        (genre) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(genre),
                            selected: _genreFilter == genre,
                            onSelected: (selected) {
                              setState(() => _genreFilter = selected ? genre : null);
                              _loadData();
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _books.isEmpty
                      ? _buildEmptyState(context, theme)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: _isGridView
                              ? GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.62,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _books.length,
                                  itemBuilder: (context, index) => BookGridCard(
                                    book: _books[index],
                                    onTap: () => _openBookDetail(_books[index]),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                  itemCount: _books.length,
                                  itemBuilder: (context, index) => BookListTile(
                                    book: _books[index],
                                    onTap: () => _openBookDetail(_books[index]),
                                  ),
                                ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddBook,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---- Layout infantil: grade grande, poucos filtros ----

  Widget _buildKidsLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus livros')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatusChip(
                    label: '📚 Todos',
                    selected: _statusFilter == null,
                    large: true,
                    onTap: () {
                      setState(() => _statusFilter = null);
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: '📖 Lendo',
                    selected: _statusFilter == BookStatus.reading,
                    large: true,
                    onTap: () {
                      setState(() => _statusFilter = BookStatus.reading);
                      _loadData();
                    },
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: '🏆 Terminei',
                    selected: _statusFilter == BookStatus.finished,
                    large: true,
                    onTap: () {
                      setState(() => _statusFilter = BookStatus.finished);
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _books.isEmpty
                      ? _buildEmptyState(context, theme)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _books.length,
                          itemBuilder: (context, index) => BookGridCard(
                            book: _books[index],
                            large: true,
                            onTap: () => _openBookDetail(_books[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBook,
        icon: const Icon(Icons.add),
        label: const Text('Novo livro'),
      ),
    );
  }

  // ---- Layout para idosos: lista com texto e toques ampliados ----

  Widget _buildElderlyLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Biblioteca')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<BookStatus?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Todos')),
                  ButtonSegment(value: BookStatus.reading, label: Text('Lendo')),
                  ButtonSegment(value: BookStatus.finished, label: Text('Concluídos')),
                ],
                selected: {_statusFilter},
                onSelectionChanged: (selection) {
                  setState(() => _statusFilter = selection.first);
                  _loadData();
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _books.isEmpty
                      ? _buildEmptyState(context, theme)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _books.length,
                          itemBuilder: (context, index) => BookListTile(
                            book: _books[index],
                            large: true,
                            onTap: () => _openBookDetail(_books[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBook,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar livro'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum livro encontrado.\nToque no + para adicionar o primeiro.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool large;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: large ? const TextStyle(fontSize: 16) : null,
      padding: large ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
    );
  }
}
