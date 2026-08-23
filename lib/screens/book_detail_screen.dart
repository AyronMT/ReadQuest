import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/book_repository.dart';
import '../services/reading_session_repository.dart';
import 'add_book_screen.dart';

/// Tela de detalhes de um livro: capa e metadados completos, gráfico
/// de páginas lidas por sessão e o histórico de todas as sessões
/// registradas para ele (com emoção e feedback, quando houver).
class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookRepository = BookRepository.instance;

  late Book _book;
  List<ReadingSession> _sessions = [];
  bool _isLoading = true;
  bool _isUpdatingActive = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await ReadingSessionRepository.instance
        .getSessionsForBook(_book.id!);
    final refreshedBook = await _bookRepository.getById(_book.id!);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      if (refreshedBook != null) _book = refreshedBook;
      _isLoading = false;
    });
  }

  Future<void> _handleEdit() async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddBookScreen(editingBook: _book)),
    );
    if (edited == true) _loadSessions();
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar livro'),
        content: Text(
          'Apagar "${_book.title}" e todo o seu histórico de leitura? Essa ação não pode ser desfeita.',
        ),
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
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _bookRepository.deleteBook(_book.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleToggleActive(bool value) async {
    setState(() => _isUpdatingActive = true);

    final result = await _bookRepository.setActive(_book.id!, value);

    if (!mounted) return;
    setState(() => _isUpdatingActive = false);

    if (result == SetActiveResult.limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limite de ${BookRepository.maxActiveBooks} livros ativos atingido. Desative outro antes de ativar este.',
          ),
        ),
      );
      return;
    }

    setState(() => _book = _book.copyWith(isActive: value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = _book;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            onPressed: _handleEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Apagar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(context, book, theme),
                const SizedBox(height: 16),
                _buildActiveToggle(context, theme),
                const SizedBox(height: 24),
                _buildMetadata(context, book, theme),
                const SizedBox(height: 28),
                if (_sessions.isNotEmpty) ...[
                  Text(
                    'Páginas por sessão',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildChart(context, theme),
                  const SizedBox(height: 28),
                ],
                Text(
                  'Histórico de leituras',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_sessions.isEmpty)
                  Text(
                    'Nenhuma sessão registrada ainda para este livro.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ..._sessions.map(
                    (s) => _SessionHistoryTile(session: s),
                  ),
              ],
            ),
    );
  }

  Widget _buildActiveToggle(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            color: _book.isActive
                ? Colors.amber.shade700
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livro ativo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Fica sempre disponível para registrar leitura (máx. ${BookRepository.maxActiveBooks})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _isUpdatingActive
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _book.isActive,
                  onChanged: _handleToggleActive,
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Book book, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: book.coverPath != null
              ? Image.file(
                  File(book.coverPath!),
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 100,
                  height: 140,
                  color: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 36,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (book.author != null)
                Text(
                  book.author!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: book.progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${book.currentPage}/${book.totalPages} páginas (${(book.progress * 100).round()}%)',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Chip(
                label: Text(book.status.label),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context, Book book, ThemeData theme) {
    final entries = <String, String?>{
      'Gênero': book.genre,
      'Saga': book.series,
      'Editora': book.publisher,
      'ISBN': book.isbn,
    }..removeWhere((key, value) => value == null || value.isEmpty);

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        e.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildChart(BuildContext context, ThemeData theme) {
  final Map<DateTime, int> dailyPagesMap = {};
  for (var session in _sessions) {
    final dateOnly = DateTime(
      session.createdAt.year, 
      session.createdAt.month, 
      session.createdAt.day
    );
    
    dailyPagesMap[dateOnly] = (dailyPagesMap[dateOnly] ?? 0) + session.pagesRead;
  }

  final aggregatedSessions = dailyPagesMap.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));

  final recentSessions = aggregatedSessions.take(10).toList().reversed.toList();

  final maxPages = recentSessions.isEmpty 
      ? 0 
      : recentSessions.map((e) => e.value).reduce((a, b) => a > b ? a : b);
      
  double getInterval(int max) {
    if (max <= 20) return 5;
    if (max <= 50) return 10;
    if (max <= 100) return 20;
    if (max <= 500) return 100;
    return 200;
  }

  return SizedBox(
    height: 180,
    child: BarChart(
      BarChartData(
        maxY: (maxPages * 1.2).clamp(10, double.infinity).toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          // EIXO Y (Esquerda)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44, // AUMENTADO de 32 para 44 para não quebrar a linha (100)
              interval: getInterval(maxPages), // Força intervalos inteiros (ex: 50, 100)
              getTitlesWidget: (value, meta) {
                // Remove decimais estranhos forçando a ser int
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // EIXO X (Inferior - Datas)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= recentSessions.length) {
                  return const SizedBox.shrink();
                }
                // Agora recentSessions contém MapEntries (key = data, value = páginas)
                final date = recentSessions[index].key; 
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: [
          for (var i = 0; i < recentSessions.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: recentSessions[i].value.toDouble(), // Usa o valor agregado
                  color: theme.colorScheme.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    ),
  );
} 
}

class _SessionHistoryTile extends StatelessWidget {
  final ReadingSession session;

  const _SessionHistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.createdAt;
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (session.emotion != null)
                Text(session.emotion!.emoji, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${session.pagesRead} páginas em ${session.durationMinutes} min',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (session.feedback != null) ...[
            const SizedBox(height: 6),
            Text(
              '"${session.feedback}"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (session.feedback == null) ...[
            const SizedBox(height: 6),
            Text(
              '"Nenhum feedback."',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
