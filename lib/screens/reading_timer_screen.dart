import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/reading_session_repository.dart';
import '../widgets/reading_summary_dialog.dart';
import '../widgets/session_extra_details_sheet.dart';

/// Tela de registro de leitura por cronômetro: o usuário inicia,
/// pode pausar/retomar quando quiser, e ao concluir informa quantas
/// páginas leu naquele intervalo.
class ReadingTimerScreen extends StatefulWidget {
  final Book book;

  const ReadingTimerScreen({super.key, required this.book});

  @override
  State<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends State<ReadingTimerScreen> {
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
      setState(() => _isRunning = true);
    }
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }

  Future<void> _finishAndRegister() async {
    _ticker?.cancel();
    setState(() => _isRunning = false);

    if (_elapsedSeconds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie o cronômetro antes de concluir.')),
      );
      return;
    }

    final pages = await _askPagesRead();
    if (pages == null) return;
    if (!mounted) return;

    final extras = await showModalBottomSheet<
        ({ReadingEmotion? emotion, String? feedback})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SessionExtraDetailsSheet(),
    );
    final emotion = extras?.emotion;
    final feedback = extras?.feedback;

    if (!mounted) return;
    setState(() => _isSaving = true);

    // Arredonda para o minuto mais próximo, com no mínimo 1 minuto.
    final minutes = (_elapsedSeconds / 60).round().clamp(1, 999999);

    final stats = await ReadingSessionRepository.instance.addSession(
      book: widget.book,
      pagesRead: pages,
      durationMinutes: minutes,
      mode: ReadingMode.timer,
      emotion: emotion,
      feedback: feedback,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    await showReadingSummaryDialog(context, stats);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<int?> _askPagesRead() {
    final controller = TextEditingController();

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quantas páginas você leu?'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Páginas lidas',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _formatDuration(_elapsedSeconds),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pausar' : (_elapsedSeconds > 0 ? 'Retomar' : 'Começar')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 52),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _finishAndRegister,
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Concluir leitura'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
