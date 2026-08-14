import 'package:flutter/material.dart';
import '../models/reading_session.dart';

/// Pop-up breve exibido logo após salvar um registro de leitura,
/// com estatísticas rápidas e uma mensagem motivacional — pensado
/// para reforçar o hábito e incentivar o próximo registro.
Future<void> showReadingSummaryDialog(
  BuildContext context,
  ReadingStats stats,
) {
  return showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);

      return AlertDialog(
        icon: Icon(
          Icons.celebration_rounded,
          color: theme.colorScheme.primary,
          size: 36,
        ),
        title: const Text('Registro salvo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stats.pointsEarned > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${stats.pointsEarned} pontos 🪙',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            _StatRow(label: 'Livro', value: stats.bookTitle),
            _StatRow(
              label: 'Nesta sessão',
              value: '${stats.pagesReadNow} páginas em ${stats.durationMinutesNow} min',
            ),
            _StatRow(
              label: 'Ritmo',
              value: stats.pagesPerMinute > 0
                  ? '${stats.pagesPerMinute.toStringAsFixed(1)} páginas/min'
                  : '—',
            ),
            _StatRow(
              label: 'Tempo por página',
              value: stats.minutesPerPage > 0
                  ? '${stats.minutesPerPage.toStringAsFixed(1)} min/página'
                  : '—',
            ),
            _StatRow(
              label: 'Total hoje',
              value: '${stats.totalPagesToday} páginas · ${stats.totalMinutesToday} min',
            ),
            if (stats.currentStreak > 0)
              _StatRow(
                label: 'Ofensiva',
                value: '${stats.currentStreak} ${stats.currentStreak == 1 ? "dia" : "dias"} seguidos 🔥',
              ),
            if (stats.emotion != null)
              _StatRow(
                label: 'Como você se sentiu',
                value: '${stats.emotion!.emoji} ${stats.emotion!.label}',
              ),
            const SizedBox(height: 12),
            Text(
              _motivationalMessage(stats),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar lendo!'),
          ),
        ],
      );
    },
  );
}

String _motivationalMessage(ReadingStats stats) {
  if (stats.currentStreak >= 7) {
    return 'Uma semana inteira de leitura! Isso é consistência de verdade. 🏆';
  }
  if (stats.currentStreak >= 3) {
    return '${stats.currentStreak} dias seguidos — o hábito está pegando! 🔥';
  }
  if (stats.totalPagesToday >= 30) {
    return 'Que dia de leitura! Continue nesse ritmo. 📖';
  }
  return 'Mais um passo na sua jornada de leitura! 📚';
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
