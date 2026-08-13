import 'package:flutter/foundation.dart';
import 'tutorial_repository.dart';

/// Um passo do tutorial: título, descrição e (opcionalmente) o id do
/// elemento visual que deve ser destacado na tela (ver TutorialHighlight).
class TutorialStepData {
  final String title;
  final String description;
  final String? targetId;

  const TutorialStepData({
    required this.title,
    required this.description,
    this.targetId,
  });
}

/// Coordena o tutorial guiado através de várias telas: Dashboard,
/// Biblioteca, Relatórios e Loja, nessa ordem. Cada tela consulta
/// este controller para saber se deve exibir o cartão de tutorial e
/// destacar algum dos seus elementos.
class TutorialController extends ChangeNotifier {
  TutorialController._internal();
  static final TutorialController instance = TutorialController._internal();

  static const List<String> screenOrder = [
    'dashboard',
    'library',
    'reports',
    'store',
  ];

  static final Map<String, List<TutorialStepData>> _stepsByScreen = {
    'dashboard': [
      const TutorialStepData(
        targetId: 'profile_button',
        title: 'Seu perfil',
        description: 'Toque aqui para editar seus dados e preferências.',
      ),
      const TutorialStepData(
        targetId: 'current_books',
        title: 'Seus livros atuais',
        description:
            'Aqui aparecem os livros que você está lendo agora — até 3 de uma vez.',
      ),
      const TutorialStepData(
        targetId: 'library_button',
        title: 'Biblioteca',
        description: 'Veja todos os seus livros e acompanhe seu acervo.',
      ),
      const TutorialStepData(
        targetId: 'streak',
        title: 'Sua ofensiva',
        description:
            'A cada dia que você registra uma leitura, sua sequência cresce. Não deixe ela quebrar!',
      ),
      const TutorialStepData(
        targetId: 'today_summary',
        title: 'Leitura de hoje',
        description: 'Um resumo rápido do que você já leu no dia de hoje.',
      ),
      const TutorialStepData(
        targetId: 'nav_home',
        title: 'Início',
        description: 'Volte para o Dashboard a qualquer momento.',
      ),
      const TutorialStepData(
        targetId: 'nav_library',
        title: 'Biblioteca',
        description: 'Acesse sua estante completa por aqui.',
      ),
      const TutorialStepData(
        targetId: 'nav_add',
        title: 'Registrar leitura',
        description:
            'O botão mais importante do app! Toque aqui sempre que ler algo — por tempo ou manualmente.',
      ),
      const TutorialStepData(
        targetId: 'nav_reports',
        title: 'Relatórios',
        description:
            'Veja gráficos diários, semanais e mensais do seu progresso.',
      ),
      const TutorialStepData(
        targetId: 'nav_store',
        title: 'Loja',
        description: 'Troque suas conquistas de leitura por recompensas.',
      ),
    ],
    'library': [
      const TutorialStepData(
        title: 'Sua biblioteca',
        description:
            'Em breve, aqui você vai poder organizar e cadastrar todos os seus livros.',
      ),
    ],
    'reports': [
      const TutorialStepData(
        title: 'Seus relatórios',
        description:
            'Em breve, aqui você vai acompanhar gráficos diários, semanais e mensais da sua leitura.',
      ),
    ],
    'store': [
      const TutorialStepData(
        title: 'Loja de recompensas',
        description:
            'Em breve, aqui você vai trocar o que ganhou lendo por recompensas.',
      ),
    ],
  };

  bool isActive = false;
  String currentScreen = screenOrder.first;
  int stepIndex = 0;

  List<TutorialStepData> get currentSteps => _stepsByScreen[currentScreen]!;
  TutorialStepData get currentStep => currentSteps[stepIndex];

  bool get isLastStepOfScreen => stepIndex == currentSteps.length - 1;
  bool get isLastScreen => currentScreen == screenOrder.last;
  bool get isFirstStepOfFirstScreen =>
      stepIndex == 0 && currentScreen == screenOrder.first;

  void start() {
    isActive = true;
    currentScreen = screenOrder.first;
    stepIndex = 0;
    notifyListeners();
  }

  /// Avança um passo. Se o passo atual for o último da tela, mas
  /// ainda houver telas seguintes, retorna o nome da próxima tela
  /// para que a UI a navegue. Se for o último passo da última tela,
  /// finaliza o tutorial e retorna null.
  String? next() {
    if (!isLastStepOfScreen) {
      stepIndex++;
      notifyListeners();
      return null;
    }

    if (!isLastScreen) {
      final idx = screenOrder.indexOf(currentScreen);
      final nextScreen = screenOrder[idx + 1];
      currentScreen = nextScreen;
      stepIndex = 0;
      notifyListeners();
      return nextScreen;
    }

    finish();
    return null;
  }

  /// Retrocede um passo. Se já estiver no primeiro passo da tela
  /// atual (mas não for a primeira tela), retorna o nome da tela
  /// anterior para que a UI navegue de volta (Navigator.pop).
  String? previous() {
    if (stepIndex > 0) {
      stepIndex--;
      notifyListeners();
      return null;
    }

    final idx = screenOrder.indexOf(currentScreen);
    if (idx > 0) {
      final prevScreen = screenOrder[idx - 1];
      currentScreen = prevScreen;
      stepIndex = _stepsByScreen[prevScreen]!.length - 1;
      notifyListeners();
      return prevScreen;
    }

    return null;
  }

  void skip() {
    finish();
  }

  void finish() {
    isActive = false;
    notifyListeners();
    TutorialRepository.instance.markPrompted();
  }
}
