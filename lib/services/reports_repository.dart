import '../models/book.dart';
import '../models/reading_session.dart';
import '../models/report_stats.dart';
import 'book_repository.dart';
import 'database_helper.dart';
import 'gamification_service.dart';
import 'reading_session_repository.dart';
import 'streak_freeze_repository.dart';

class ReportsRepository {
  ReportsRepository._internal();
  static final ReportsRepository instance = ReportsRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  Future<int> _sumPagesForMonth(DateTime month) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(pages_read), 0) as total FROM reading_sessions WHERE session_date LIKE ?',
      ['${_monthKey(month)}%'],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ---- Wrapped mensal ----

  Future<MonthlyWrapped> getMonthlyWrapped(DateTime month) async {
    final db = await _dbHelper.database;
    final monthKey = _monthKey(month);

    final sessionRows = await db.query(
      'reading_sessions',
      where: 'session_date LIKE ?',
      whereArgs: ['$monthKey%'],
    );

    final pagesRead = sessionRows.fold<int>(0, (s, r) => s + (r['pages_read'] as int));
    final minutesRead = sessionRows.fold<int>(0, (s, r) => s + (r['duration_minutes'] as int));

    final finishedRows = await db.query(
      'books',
      where: 'status = ? AND updated_at LIKE ?',
      whereArgs: [BookStatus.finished.name, '$monthKey%'],
    );

    final topGenreRows = await db.rawQuery('''
      SELECT b.genre as genre, SUM(rs.pages_read) as pages
      FROM reading_sessions rs
      JOIN books b ON b.id = rs.book_id
      WHERE rs.session_date LIKE ? AND b.genre IS NOT NULL AND b.genre != ''
      GROUP BY b.genre
      ORDER BY pages DESC
      LIMIT 1
    ''', ['$monthKey%']);

    final previousMonth = DateTime(month.year, month.month - 1, 1);
    final previousPages = await _sumPagesForMonth(previousMonth);
    double? changePercent;
    if (previousPages > 0) {
      changePercent = ((pagesRead - previousPages) / previousPages) * 100;
    }

    return MonthlyWrapped(
      month: month,
      pagesRead: pagesRead,
      minutesRead: minutesRead,
      sessionsCount: sessionRows.length,
      booksFinished: finishedRows.length,
      topGenre: topGenreRows.isEmpty ? null : topGenreRows.first['genre'] as String?,
      pagesChangePercent: changePercent,
    );
  }

  // ---- Hábito e consistência ----

  Future<HabitStats> getHabitStats({DateTime? referenceMonth}) async {
    final db = await _dbHelper.database;
    final month = referenceMonth ?? DateTime.now();
    final monthKey = _monthKey(month);

    final currentStreak = await ReadingSessionRepository.instance.getCurrentStreak();

    final allDatesRows = await db.rawQuery(
      'SELECT DISTINCT session_date FROM reading_sessions ORDER BY session_date ASC',
    );
    final allDates = allDatesRows
        .map((r) => DateTime.parse(r['session_date'] as String))
        .toList();

    var longestStreak = 0;
    var runningStreak = 0;
    DateTime? previousDate;
    for (final date in allDates) {
      if (previousDate != null && date.difference(previousDate).inDays == 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      if (runningStreak > longestStreak) longestStreak = runningStreak;
      previousDate = date;
    }

    final monthDatesRows = await db.rawQuery(
      'SELECT DISTINCT session_date FROM reading_sessions WHERE session_date LIKE ?',
      ['$monthKey%'],
    );
    final activeDaysOfMonth = monthDatesRows
        .map((r) => DateTime.parse(r['session_date'] as String).day)
        .toSet();

    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daysInMonthSoFar = isCurrentMonth ? now.day : daysInMonth;

    return HabitStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      activeDaysThisMonth: activeDaysOfMonth.length,
      daysInMonthSoFar: daysInMonthSoFar,
      activeDaysOfMonth: activeDaysOfMonth,
    );
  }

  // ---- Métricas clássicas ----

  Future<ClassicStats> getClassicStats({DateTime? monthFilter}) async {
    final db = await _dbHelper.database;

    final where = monthFilter != null ? 'session_date LIKE ?' : null;
    final whereArgs = monthFilter != null ? ['${_monthKey(monthFilter)}%'] : null;

    final sessionRows = await db.query(
      'reading_sessions',
      where: where,
      whereArgs: whereArgs,
    );

    final totalPagesRead = sessionRows.fold<int>(0, (s, r) => s + (r['pages_read'] as int));
    final totalMinutesRead = sessionRows.fold<int>(0, (s, r) => s + (r['duration_minutes'] as int));

    final activeDays = sessionRows.map((r) => r['session_date'] as String).toSet();

    final booksWhere = monthFilter != null
        ? 'status = ? AND updated_at LIKE ?'
        : 'status = ?';
    final booksArgs = monthFilter != null
        ? [BookStatus.finished.name, '${_monthKey(monthFilter)}%']
        : [BookStatus.finished.name];
    final finishedRows = await db.query('books', where: booksWhere, whereArgs: booksArgs);

    return ClassicStats(
      totalPagesRead: totalPagesRead,
      totalMinutesRead: totalMinutesRead,
      booksFinished: finishedRows.length,
      avgPagesPerMinute: totalMinutesRead > 0 ? totalPagesRead / totalMinutesRead : 0,
      avgSessionMinutes: sessionRows.isNotEmpty ? totalMinutesRead / sessionRows.length : 0,
      avgPagesPerActiveDay: activeDays.isNotEmpty ? totalPagesRead / activeDays.length : 0,
    );
  }

  // ---- Raio-X do leitor ----

  Future<ReaderProfile> getReaderProfile() async {
    final db = await _dbHelper.database;

    final genreRows = await db.rawQuery('''
      SELECT b.genre as genre, SUM(rs.pages_read) as pages
      FROM reading_sessions rs
      JOIN books b ON b.id = rs.book_id
      WHERE b.genre IS NOT NULL AND b.genre != ''
      GROUP BY b.genre
      ORDER BY pages DESC
    ''');
    final genreDistribution = genreRows
        .map((r) => GenreStat(r['genre'] as String, r['pages'] as int))
        .toList();

    final authorRows = await db.rawQuery('''
      SELECT b.author as author, SUM(rs.pages_read) as pages
      FROM reading_sessions rs
      JOIN books b ON b.id = rs.book_id
      WHERE b.author IS NOT NULL AND b.author != ''
      GROUP BY b.author
      ORDER BY pages DESC
      LIMIT 1
    ''');
    final topAuthor = authorRows.isEmpty ? null : authorRows.first['author'] as String?;

    final emotionRows = await db.rawQuery('''
      SELECT emotion, COUNT(*) as total FROM reading_sessions
      WHERE emotion IS NOT NULL
      GROUP BY emotion
    ''');
    final emotionCounts = <ReadingEmotion, int>{};
    for (final row in emotionRows) {
      final emotion = ReadingEmotion.fromString(row['emotion'] as String?);
      if (emotion != null) emotionCounts[emotion] = row['total'] as int;
    }

    final allSessionRows = await db.query('reading_sessions', columns: ['created_at']);
    final timeOfDayCounts = <String, int>{
      'Madrugada': 0,
      'Manhã': 0,
      'Tarde': 0,
      'Noite': 0,
    };
    for (final row in allSessionRows) {
      final createdAt = DateTime.parse(row['created_at'] as String);
      final hour = createdAt.hour;
      if (hour >= 5 && hour < 12) {
        timeOfDayCounts['Manhã'] = timeOfDayCounts['Manhã']! + 1;
      } else if (hour >= 12 && hour < 18) {
        timeOfDayCounts['Tarde'] = timeOfDayCounts['Tarde']! + 1;
      } else if (hour >= 18 && hour < 23) {
        timeOfDayCounts['Noite'] = timeOfDayCounts['Noite']! + 1;
      } else {
        timeOfDayCounts['Madrugada'] = timeOfDayCounts['Madrugada']! + 1;
      }
    }

    return ReaderProfile(
      genreDistribution: genreDistribution,
      topAuthor: topAuthor,
      emotionCounts: emotionCounts,
      timeOfDayCounts: timeOfDayCounts,
    );
  }

  // ---- Economia e gamificação ----

  Future<EconomyStats> getEconomyStats() async {
    final db = await _dbHelper.database;

    final balance = await GamificationService.instance.getBalance();

    final earnedResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM point_transactions WHERE amount > 0',
    );
    final totalEarned = (earnedResult.first['total'] as int?) ?? 0;

    final spentResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM point_transactions WHERE amount < 0',
    );
    final totalSpent = -((spentResult.first['total'] as int?) ?? 0);

    final redemptionsRows = await db.query('reward_redemptions');

    final freezesAvailable = await StreakFreezeRepository.instance.getAvailableCount();

    return EconomyStats(
      currentBalance: balance,
      totalEarned: totalEarned,
      totalSpent: totalSpent,
      rewardsRedeemed: redemptionsRows.length,
      streakFreezesAvailable: freezesAvailable,
    );
  }

  // ---- Por saga ----

  Future<List<String>> getAllSeries() => BookRepository.instance.getDistinctSeries();

  Future<SagaStats> getSagaStats(String seriesName) async {
    final db = await _dbHelper.database;

    final bookRows = await db.query('books', where: 'series = ?', whereArgs: [seriesName]);
    final books = bookRows.map(Book.fromMap).toList();
    final bookIds = books.map((b) => b.id).whereType<int>().toList();

    if (bookIds.isEmpty) {
      return SagaStats(
        seriesName: seriesName,
        books: books,
        finishedBooks: 0,
        totalPagesRead: 0,
        totalMinutesRead: 0,
        emotionCounts: {},
      );
    }

    final placeholders = List.filled(bookIds.length, '?').join(',');
    final sessionRows = await db.query(
      'reading_sessions',
      where: 'book_id IN ($placeholders)',
      whereArgs: bookIds,
    );

    final totalPagesRead = sessionRows.fold<int>(0, (s, r) => s + (r['pages_read'] as int));
    final totalMinutesRead = sessionRows.fold<int>(0, (s, r) => s + (r['duration_minutes'] as int));

    final emotionCounts = <ReadingEmotion, int>{};
    for (final row in sessionRows) {
      final emotion = ReadingEmotion.fromString(row['emotion'] as String?);
      if (emotion != null) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    return SagaStats(
      seriesName: seriesName,
      books: books,
      finishedBooks: books.where((b) => b.status == BookStatus.finished).length,
      totalPagesRead: totalPagesRead,
      totalMinutesRead: totalMinutesRead,
      emotionCounts: emotionCounts,
    );
  }
}
