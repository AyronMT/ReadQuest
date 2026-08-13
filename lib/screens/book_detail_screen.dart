import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/reading_session_repository.dart';

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
  List<ReadingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await ReadingSessionRepository.instance
        .getSessionsForBook(widget.book.id!);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(context, book, theme),
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
    // Mostra as últimas 10 sessões, da mais antiga para a mais
    // recente, com a quantidade de páginas lidas em cada uma.
    final recentSessions = _sessions.take(10).toList().reversed.toList();

    final maxPages = recentSessions
        .map((s) => s.pagesRead)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: (maxPages * 1.2).clamp(10, double.infinity),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentSessions.length) {
                    return const SizedBox.shrink();
                  }
                  final date = recentSessions[index].createdAt;
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
                    toY: recentSessions[i].pagesRead.toDouble(),
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
        ],
      ),
    );
  }
}
