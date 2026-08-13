import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/reading_session_repository.dart';
import '../widgets/reading_summary_dialog.dart';
import '../widgets/session_extra_details_sheet.dart';

/// Tela de registro de leitura manual: o usuário informa diretamente
/// quantas páginas leu e quanto tempo levou.
class ManualReadingEntryScreen extends StatefulWidget {
  final Book book;

  const ManualReadingEntryScreen({super.key, required this.book});

  @override
  State<ManualReadingEntryScreen> createState() =>
      _ManualReadingEntryScreenState();
}

class _ManualReadingEntryScreenState extends State<ManualReadingEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pagesController = TextEditingController();
  final _minutesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _pagesController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  String? _validatePositiveInt(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $label';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Valor inválido';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final pages = int.parse(_pagesController.text.trim());
    final minutes = int.parse(_minutesController.text.trim());

    final extras = await showModalBottomSheet<
        ({ReadingEmotion? emotion, String? feedback})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SessionExtraDetailsSheet(),
    );
    // Se o usuário fechar o sheet arrastando pra baixo (sem escolher
    // "Pular" nem "Salvar"), extras vem null — tratamos como "pular".
    final emotion = extras?.emotion;
    final feedback = extras?.feedback;

    if (!mounted) return;
    setState(() => _isSaving = true);

    final stats = await ReadingSessionRepository.instance.addSession(
      book: widget.book,
      pagesRead: pages,
      durationMinutes: minutes,
      mode: ReadingMode.manual,
      emotion: emotion,
      feedback: feedback,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    await showReadingSummaryDialog(context, stats);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar leitura manual',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _pagesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Páginas lidas',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validatePositiveInt(v, 'as páginas lidas'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tempo gasto (minutos)',
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validatePositiveInt(v, 'o tempo gasto'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Registrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
