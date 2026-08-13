import 'package:flutter/material.dart';
import '../services/tutorial_controller.dart';

/// Envolve qualquer widget e o destaca com uma borda/brilho quando
/// ele for o alvo do passo atual do tutorial (identificado por [stepId]).
class TutorialHighlight extends StatelessWidget {
  final String stepId;
  final Widget child;

  const TutorialHighlight({
    super.key,
    required this.stepId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TutorialController.instance,
      builder: (context, _) {
        final controller = TutorialController.instance;
        final isHighlighted = controller.isActive &&
            controller.currentStep.targetId == stepId;

        final primary = Theme.of(context).colorScheme.primary;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isHighlighted
                ? Border.all(color: primary, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
