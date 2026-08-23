import 'reading_session.dart';
import 'book.dart';

/// Resumo "Wrapped" de um mês específico.
class MonthlyWrapped {
  final DateTime month;
  final int pagesRead;
  final int minutesRead;
  final int sessionsCount;
  final int booksFinished;
  final String? topGenre;
  final double? pagesChangePercent; // vs. mês anterior; null se não há dado anterior

  const MonthlyWrapped({
    required this.month,
    required this.pagesRead,
    required this.minutesRead,
    required this.sessionsCount,
    required this.booksFinished,
    this.topGenre,
    this.pagesChangePercent,
  });
}

/// Hábito e consistência de leitura.
class HabitStats {
  final int currentStreak;
  final int longestStreak;
  final int activeDaysThisMonth;
  final int daysInMonthSoFar;
  final Set<int> activeDaysOfMonth;

  const HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDaysThisMonth,
    required this.daysInMonthSoFar,
    required this.activeDaysOfMonth,
  });
}

/// Métricas clássicas de desempenho de leitura.
class ClassicStats {
  final int totalPagesRead;
  final int totalMinutesRead;
  final int booksFinished;
  final double avgPagesPerMinute;
  final double avgSessionMinutes;
  final double avgPagesPerActiveDay;

  const ClassicStats({
    required this.totalPagesRead,
    required this.totalMinutesRead,
    required this.booksFinished,
    required this.avgPagesPerMinute,
    required this.avgSessionMinutes,
    required this.avgPagesPerActiveDay,
  });
}

class GenreStat {
  final String genre;
  final int pages;
  const GenreStat(this.genre, this.pages);
}

/// O "raio-X" do leitor: gêneros, autor favorito, emoções e horários
/// preferidos de leitura.
class ReaderProfile {
  final List<GenreStat> genreDistribution;
  final String? topAuthor;
  final Map<ReadingEmotion, int> emotionCounts;
  final Map<String, int> timeOfDayCounts;

  const ReaderProfile({
    required this.genreDistribution,
    required this.topAuthor,
    required this.emotionCounts,
    required this.timeOfDayCounts,
  });
}

/// Estatísticas de economia e gamificação.
class EconomyStats {
  final int currentBalance;
  final int totalEarned;
  final int totalSpent;
  final int rewardsRedeemed;
  final int streakFreezesAvailable;

  const EconomyStats({
    required this.currentBalance,
    required this.totalEarned,
    required this.totalSpent,
    required this.rewardsRedeemed,
    required this.streakFreezesAvailable,
  });
}

/// Estatísticas de uma saga específica.
class SagaStats {
  final String seriesName;
  final List<Book> books;
  final int finishedBooks;
  final int totalPagesRead;
  final int totalMinutesRead;
  final Map<ReadingEmotion, int> emotionCounts;

  const SagaStats({
    required this.seriesName,
    required this.books,
    required this.finishedBooks,
    required this.totalPagesRead,
    required this.totalMinutesRead,
    required this.emotionCounts,
  });
}
