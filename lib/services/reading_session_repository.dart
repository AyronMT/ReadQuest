import '../models/book.dart';
import '../models/reading_session.dart';
import 'book_repository.dart';
import 'database_helper.dart';
import 'gamification_service.dart';
import 'streak_freeze_repository.dart';

class ReadingSessionRepository {
  ReadingSessionRepository._internal();
  static final ReadingSessionRepository instance =
      ReadingSessionRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final BookRepository _bookRepository = BookRepository.instance;
  final GamificationService _gamification = GamificationService.instance;

  String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Registra uma nova sessão de leitura, atualiza o progresso do
  /// livro, concede os pontos correspondentes e retorna as
  /// estatísticas para exibir no pop-up de resumo.
  /// [emotion] e [feedback] são opcionais.
  Future<ReadingStats> addSession({
    required Book book,
    required int pagesRead,
    required int durationMinutes,
    required ReadingMode mode,
    ReadingEmotion? emotion,
    String? feedback,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final wasFinishedBefore = book.status == BookStatus.finished;
    final todayBefore = await getTodayTotals();
    final isFirstSessionToday = todayBefore.pages == 0 && todayBefore.minutes == 0;

    final session = ReadingSession(
      bookId: book.id!,
      pagesRead: pagesRead,
      durationMinutes: durationMinutes,
      mode: mode,
      emotion: emotion,
      feedback: (feedback == null || feedback.trim().isEmpty) ? null : feedback.trim(),
      createdAt: now,
    );
    await db.insert('reading_sessions', session.toMap());

    await _bookRepository.updateProgress(
      book.id!,
      book.currentPage + pagesRead,
    );

    final updatedBook = await _bookRepository.getById(book.id!);
    final justFinished = !wasFinishedBefore && updatedBook?.status == BookStatus.finished;

    var pointsEarned = await _gamification.awardPoints(
      GamificationRules.readingLogged,
      'reading_logged',
    );
    if (isFirstSessionToday) {
      pointsEarned += await _gamification.awardPoints(
        GamificationRules.dailyStreakBonus,
        'streak_bonus',
      );
    }
    if (justFinished) {
      pointsEarned += await _gamification.awardPoints(
        GamificationRules.bookFinishedBonus,
        'book_finished',
      );
    }

    final todayTotals = await getTodayTotals();
    final streak = await getCurrentStreak();

    return ReadingStats(
      bookTitle: book.title,
      pagesReadNow: pagesRead,
      durationMinutesNow: durationMinutes,
      totalPagesToday: todayTotals.pages,
      totalMinutesToday: todayTotals.minutes,
      currentStreak: streak,
      emotion: emotion,
      pointsEarned: pointsEarned,
    );
  }

  /// Todas as sessões de leitura de um livro, da mais recente para a
  /// mais antiga — usado na tela de detalhes do livro.
  Future<List<ReadingSession>> getSessionsForBook(int bookId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'reading_sessions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at DESC',
    );
    return rows.map(ReadingSession.fromMap).toList();
  }

  /// Soma de páginas e minutos lidos hoje, considerando todos os livros.
  Future<({int pages, int minutes})> getTodayTotals() async {
    final db = await _dbHelper.database;
    final todayKey = _dateKey(DateTime.now());

    final rows = await db.query(
      'reading_sessions',
      where: 'session_date = ?',
      whereArgs: [todayKey],
    );

    final pages = rows.fold<int>(0, (sum, r) => sum + (r['pages_read'] as int));
    final minutes =
        rows.fold<int>(0, (sum, r) => sum + (r['duration_minutes'] as int));

    return (pages: pages, minutes: minutes);
  }

  /// Calcula quantos dias seguidos (incluindo hoje, se já houver
  /// registro) o usuário leu algo — o "sistema de ofensiva". Uma
  /// lacuna de exatamente um dia pode ser coberta automaticamente
  /// por um congelamento de ofensiva disponível (ver StreakFreezeRepository).
  Future<int> getCurrentStreak() async {
    final db = await _dbHelper.database;

    final rows = await db.rawQuery('''
      SELECT DISTINCT session_date FROM reading_sessions
      ORDER BY session_date DESC
    ''');

    if (rows.isEmpty) return 0;

    final sessionDates = rows
        .map((r) => DateTime.parse(r['session_date'] as String))
        .toSet();

    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    // Se ainda não leu nada hoje, a sequência continua valendo a
    // partir de ontem — só quebra se faltar um dia inteiro (e não
    // houver congelamento disponível para cobri-lo).
    if (!sessionDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (true) {
      if (sessionDates.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      final covered = await StreakFreezeRepository.instance.coverGapDate(cursor);
      if (covered) {
        // O dia foi protegido por um congelamento: a sequência não
        // quebra, mas esse dia em si não conta como leitura.
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      break;
    }

    return streak;
  }
}
