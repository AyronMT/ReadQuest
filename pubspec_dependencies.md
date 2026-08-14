# Dependências necessárias

Adicione isso ao seu `pubspec.yaml` (dentro da seção `dependencies`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.3
  path: ^1.9.0
  crypto: ^3.0.5
  google_sign_in: ^6.2.1
  google_fonts: ^6.2.1
  fl_chart: ^0.68.0
  image_picker: ^1.1.2
```

Depois, rode:

```bash
flutter pub get
```

## Onde colocar os arquivos

Copie a pasta `lib/` deste pacote para a raiz do seu projeto Flutter,
substituindo o `lib/main.dart` padrão que o `flutter create` gera.

Estrutura final esperada:

```
lib/
 ├── main.dart
 ├── models/
 │    ├── app_theme_preset.dart
 │    ├── book.dart
 │    └── reading_session.dart
 ├── services/
 │    ├── database_helper.dart
 │    ├── auth_service.dart
 │    ├── user_repository.dart
 │    ├── theme_service.dart
 │    ├── book_repository.dart
 │    ├── reading_session_repository.dart
 │    ├── tutorial_controller.dart
 │    ├── tutorial_repository.dart
 │    └── tutorial_navigation.dart
 ├── widgets/
 │    ├── tutorial_highlight.dart
 │    ├── tutorial_card.dart
 │    ├── book_picker_sheet.dart
 │    ├── reading_mode_picker_sheet.dart
 │    └── reading_summary_dialog.dart
 └── screens/
      ├── splash_screen.dart
      ├── login_screen.dart
      ├── signup_screen.dart
      ├── theme_selection_screen.dart
      ├── dashboard_screen.dart
      ├── library_screen.dart
      ├── reports_screen.dart
      ├── store_screen.dart
      ├── profile_screen.dart
      ├── reading_timer_screen.dart
      └── manual_reading_entry_screen.dart
```

## Login com Google — BLOQUEADO por enquanto

A pedido, o botão "Continuar com Google" está desabilitado
(`onPressed: null`) tanto no cadastro quanto no login, com um ícone
de cadeado e o texto "(em breve)". Toda a lógica em
`UserRepository.continueWithGoogle()` continua pronta e funcional —
é só reconectar o `onPressed` quando quiser reativar. Quando for
reativar, ainda será necessário configurar o Firebase/Google Cloud
(SHA-1, `google-services.json`, etc.) — guia oficial:
https://pub.dev/packages/google_sign_in

## Cadastro/login por e-mail e senha

Fica tudo na tabela `users` do SQLite. A senha nunca é salva em
texto puro: `SHA-256(salt + senha)`, com salt aleatório por usuário.

## O Dashboard e o tutorial guiado

- **Primeiro acesso**: ao entrar no Dashboard pela primeira vez
  (local ou com conta), surge um pop-up perguntando se o usuário
  quer o tour guiado. A resposta (sim ou não) fica salva em
  `settings` (`tutorial_prompt_shown`), então ele só aparece uma vez.
- **Tutorial passo a passo**: coordenado por `TutorialController`
  (`services/tutorial_controller.dart`), com passos definidos por
  tela (`dashboard`, `library`, `reports`, `store`, nessa ordem).
  Cada passo pode destacar um elemento específico via
  `TutorialHighlight` (borda + brilho ao redor do widget) e sempre
  mostra um cartão (`TutorialCard`) com título, descrição e os
  botões **Pular**, **Voltar** e **Avançar/Concluir** — disponíveis
  o tempo todo, como pedido. Ao avançar do último passo de uma tela,
  ele empilha automaticamente a próxima tela do tutorial; ao voltar
  do primeiro passo de uma tela, ele desempilha para a anterior.
- **Dados de exemplo**: como a tela de Biblioteca (cadastro de
  livros) ainda não existe, `BookRepository` semeia 2 livros de
  exemplo ("Duna" e "O Hobbit") na primeira execução, só para o
  Dashboard e o registro de leitura terem o que mostrar. Remova essa
  semeadura (`_seedSampleBooksIfEmpty`) quando a Biblioteca real for
  implementada.

## Registro de leitura (funcional)

- Toque no botão central (+) da barra inferior.
- Escolhe o livro (o "atual" já vem selecionado e em primeiro na
  lista) → escolhe o modo → **Por tempo**: cronômetro com
  pausar/retomar; ao concluir, pergunta as páginas lidas. **Manual**:
  formulário direto com páginas e minutos.
- Em ambos os casos, salva no SQLite (`reading_sessions`), atualiza
  a página atual do livro (marcando como concluído se chegar ao
  fim) e mostra um pop-up de resumo (`reading_summary_dialog.dart`)
  com ritmo de leitura, total do dia e uma mensagem motivacional.
- A ofensiva (`getCurrentStreak`) considera dias consecutivos com
  pelo menos um registro, permitindo que a sequência continue válida
  até o fim do dia mesmo que ainda não tenha lido hoje.

## Biblioteca

- **Layouts por perfil**: `LibraryScreen` lê `ThemeService.instance.currentPreset`
  e escolhe entre 3 layouts estruturalmente diferentes — não é só
  cor/fonte, muda a própria interface:
  - **Criança**: só grade grande (2 colunas), 3 chips grandes de
    filtro (Todos/Lendo/Terminei), sem busca nem ordenação.
  - **Idoso**: só lista (sem opção de grade), textos e alvos de
    toque maiores, filtro por `SegmentedButton` (mais simples que
    chips), botão "Adicionar livro" com texto (não só ícone).
  - **Adolescente/Adulto**: busca por título/autor, chips de status
    + gênero, alternância grade/lista, menu de ordenação.
- **Cadastro de livro** (`AddBookScreen`): só nome e páginas são
  obrigatórios. Autor, gênero, saga e editora usam `Autocomplete`
  com sugestões vindas de livros já cadastrados
  (`BookRepository.getDistinctAuthors/Genres/Series/Publishers`).
  Capa é opcional, escolhida da galeria via `image_picker`.
- **Detalhes do livro** (`BookDetailScreen`): metadados completos,
  gráfico de barras (`fl_chart`) com páginas lidas nas últimas 10
  sessões, e o histórico completo de sessões (com emoção e feedback,
  quando informados).

## Emoção e feedback no registro de leitura

Depois de informar páginas/tempo (nos dois modos, cronômetro e
manual), um bottom sheet opcional (`SessionExtraDetailsSheet`)
pergunta como foi a leitura: emoção pré-definida (😍🙂😐😕😣) e um
campo de texto livre para feedback sobre a história. Ambos ficam
salvos na sessão e aparecem no histórico do livro e no resumo
motivacional.

## Gamificação: pontos e loja

- **Ganho de pontos** (`GamificationService`, tabela `point_transactions`
  — o saldo é sempre a soma das transações, então fica um histórico
  auditável de graça):
  - Abrir o app: +5, uma vez por dia (concedido no Dashboard).
  - Registrar uma leitura: +5.
  - Primeira leitura do dia (mantém a ofensiva viva): +10 a mais.
  - Terminar um livro: +50 a mais.
  - Um multiplicador temporário (comprado na loja) é aplicado
    automaticamente em cima de qualquer ganho, enquanto estiver ativo.
- **Loja** (`StoreScreen`): mostra o saldo no topo, um banner quando
  há bônus de pontos ativo, as recompensas do sistema
  (`StoreCatalog.items` em `models/store_reward.dart`) e as
  recompensas pessoais do usuário (cadastrar/resgatar/**remover** —
  só as próprias, as do sistema não podem ser removidas).
- **Recompensas do sistema com efeito real**:
  - 🧊 *Congelar ofensiva*: soma um congelamento disponível. O
    cálculo da ofensiva (`getCurrentStreak`) consome automaticamente
    um congelamento quando encontra uma lacuna de exatamente 1 dia
    sem leitura, evitando que ela zere.
  - ⚡🚀 *Bônus de pontos (1h / 24h)*: ativa o multiplicador x2 por
    tempo limitado.
  - ✨ *Destaque dourado* e 🌟 *Decoração estelar*: desbloqueios
    únicos que já mudam visualmente o card de ofensiva no Dashboard
    (cor da chama e estrelinhas) — dá pra ver o efeito na hora.
  - 🚩 *Banner* e 🐛 *Emblema*: ficam guardados no inventário
    (`reward_redemptions`), mas a aplicação visual depende da tela
    de Perfil, que você já indicou que é future work.
- **Recompensas pessoais**: título, custo em pontos e um emoji à
  escolha — sem efeito no app, só o registro do resgate.

## Tema (fontes via google_fonts)

O pacote `google_fonts` baixa e faz cache das fontes na primeira vez
que cada uma é usada. Se o app precisar funcionar 100% offline desde
a primeira abertura, será necessário empacotar as fontes como assets
locais — me avise que ajusto o `app_theme_preset.dart`.

Os 4 presets (`app_theme_preset.dart`) — Criança (laranja, Baloo 2,
+15% fonte), Adolescente (roxo, Poppins), Adulto (verde, Inter),
Idoso (azul alto contraste, Atkinson Hyperlegible, +30% fonte).
Como todas as telas usam `Theme.of(context)`, a interface inteira
(cores, fontes, formas de botão) já muda de acordo com o preset
escolhido — inclusive Dashboard, tutorial e registro de leitura.
