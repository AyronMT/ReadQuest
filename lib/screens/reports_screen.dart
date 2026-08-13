import 'package:flutter/material.dart';
import '../services/tutorial_controller.dart';
import '../widgets/tutorial_card.dart';

/// Placeholder dos Relatórios — será desenvolvido nas próximas etapas.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TutorialController.instance,
      builder: (context, _) {
        final showTutorial = TutorialController.instance.isActive &&
            TutorialController.instance.currentScreen == 'reports';

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(title: const Text('Relatórios')),
              body: const Center(
                child: Text('Gráficos diários, semanais e mensais — em construção 📊'),
              ),
            ),
            if (showTutorial) const TutorialCard(),
          ],
        );
      },
    );
  }
}
