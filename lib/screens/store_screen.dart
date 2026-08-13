import 'package:flutter/material.dart';
import '../services/tutorial_controller.dart';
import '../widgets/tutorial_card.dart';

/// Placeholder da Loja — será desenvolvido nas próximas etapas.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TutorialController.instance,
      builder: (context, _) {
        final showTutorial = TutorialController.instance.isActive &&
            TutorialController.instance.currentScreen == 'store';

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(title: const Text('Loja')),
              body: const Center(
                child: Text('Troque conquistas por recompensas — em construção 🎁'),
              ),
            ),
            if (showTutorial) const TutorialCard(),
          ],
        );
      },
    );
  }
}
