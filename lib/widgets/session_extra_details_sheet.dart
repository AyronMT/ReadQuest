import 'package:flutter/material.dart';
import '../models/reading_session.dart';

/// Bottom sheet opcional exibido após informar páginas/tempo, para o
/// usuário registrar como está se sentindo em relação à leitura e
/// deixar um feedback rápido sobre a história até aqui.
/// Retorna um record (emotion, feedback) — ambos podem vir nulos se
/// o usuário optar por pular.
class SessionExtraDetailsSheet extends StatefulWidget {
  const SessionExtraDetailsSheet({super.key});

  @override
  State<SessionExtraDetailsSheet> createState() =>
      _SessionExtraDetailsSheetState();
}

class _SessionExtraDetailsSheetState extends State<SessionExtraDetailsSheet> {
  ReadingEmotion? _selectedEmotion;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop((
      emotion: _selectedEmotion,
      feedback: _feedbackController.text.trim().isEmpty
          ? null
          : _feedbackController.text.trim(),
    ));
  }

  void _skip() {
    Navigator.of(context).pop((emotion: null, feedback: null));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Como foi essa leitura? (opcional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ReadingEmotion.values.map((emotion) {
                  final isSelected = _selectedEmotion == emotion;
                  return ChoiceChip(
                    label: Text('${emotion.emoji} ${emotion.label}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedEmotion = selected ? emotion : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'O que achou da história até agora?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _skip,
                      child: const Text('Pular'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
