import 'package:flutter/material.dart';
import '../services/tutorial_controller.dart';
import '../services/tutorial_navigation.dart';

/// Cartão flutuante mostrado durante o tutorial guiado, com o
/// título/descrição do passo atual e os botões "Pular", "Voltar" e
/// "Avançar"/"Concluir" — sempre visíveis enquanto o tutorial roda.
class TutorialCard extends StatelessWidget {
  const TutorialCard({super.key});

  void _handleSkip(BuildContext context) {
    TutorialController.instance.skip();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handlePrevious(BuildContext context) {
    final targetScreen = TutorialController.instance.previous();
    if (targetScreen != null) {
      Navigator.of(context).pop();
    }
  }

  void _handleNext(BuildContext context) {
    final nextScreen = TutorialController.instance.next();
    if (nextScreen != null) {
      pushTutorialScreen(context, nextScreen);
    } else if (!TutorialController.instance.isActive) {
      // Tutorial concluído.
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutorial concluído! Bora ler? 📚')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TutorialController.instance;
    final step = controller.currentStep;
    final isFinalButton = controller.isLastStepOfScreen && controller.isLastScreen;
    final canGoBack = !controller.isFirstStepOfFirstScreen;
    final theme = Theme.of(context);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _handleSkip(context),
                    child: const Text('Pular'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                step.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: canGoBack ? () => _handlePrevious(context) : null,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Voltar'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _handleNext(context),
                    icon: Icon(
                      isFinalButton ? Icons.check : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(isFinalButton ? 'Concluir' : 'Avançar'),
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
